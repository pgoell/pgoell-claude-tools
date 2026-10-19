#!/usr/bin/env python3
"""Local editor server for one HTML deck. Standard library only.

Usage: python3 server.py <deck.html> [port]

Hosted mode, for a server behind a reverse proxy that does the sign-in: set
DECK_EDITOR_HOST to the public host name. The server then listens on every
interface and answers that name too. With DECK_EDITOR_REPO (owner/name) and
GITHUB_TOKEN set as well, the overlay shows "Send", which files the feedback
prompt as a GitHub issue.

Serves the deck with a `data-de="<source offset>"` attribute on every element
inside <deck-stage> and an overlay script. The file on disk never carries
either: every edit is a splice of the source text at offsets (deck_source.py),
so the bytes outside the edited span stay as they were.
"""
import hashlib
import json
import mimetypes
import os
import re
import shutil
import subprocess
import sys
import threading
import time
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import quote, unquote, urlsplit

from deck_source import Scan, splice

HERE = Path(__file__).resolve().parent
DECK = Path(sys.argv[1]).resolve()
PORT = int(sys.argv[2]) if len(sys.argv) > 2 else 4747
STATE = DECK.parent / ".deck-editor"
HOST = os.environ.get("DECK_EDITOR_HOST")
REPO, TOKEN = os.environ.get("DECK_EDITOR_REPO"), os.environ.get("GITHUB_TOKEN")
SCRIPTS = ("overlay-edit.js", "overlay-gates.js", "overlay.js")  # served from here; overlay.js loads last


def read():
    with open(DECK, encoding="utf-8", newline="") as f:
        return f.read()


def rev_of(text):
    return hashlib.sha1(text.encode()).hexdigest()[:12]


marks = {}  # slide offset -> SVG laid over that slide in a prompt screenshot


def annotated(text, outline=(), marked=False):
    """The deck as served: offsets on every slide element, overlay script appended."""
    out, at = [], 0
    for el in Scan(text).in_stage():
        cut = el["start"] + 1 + len(el["tag"])
        out += [text[at:cut], f' data-de="{el["start"]}"']
        at = cut
    html = "".join(out) + text[at:]
    if marked:  # prompt screenshot: comment boxes and drawings over each slide
        return html.replace("<deck-stage", "<deck-stage no-rail", 1) + "<script>" + "".join(
            f"document.querySelector('[data-de=\"{p}\"]')?.insertAdjacentHTML('beforeend', {json.dumps(svg)});"
            for p, svg in marks.items()) + "</script>"
    if outline:  # screenshot render: mark the selection, no overlay, no rail
        picked = ",".join(f'[data-de="{int(p)}"]' for p in outline)
        return html.replace("<deck-stage", "<deck-stage no-rail", 1) + (
            f"<style>{picked}{{outline:6px solid #ff2d95;outline-offset:6px}}</style>"
        )
    return html + "".join(f'<script src="/__editor/{name}"></script>' for name in SCRIPTS[:-1]) + f'<script src="/__editor/overlay.js" data-rev="{rev_of(text)}"{" data-send" * bool(REPO and TOKEN)}></script>'


# Serve from the highest directory the deck reaches with ../ so shared engines and assets resolve.
_ups = [m.group(0).count("../") for m in re.finditer(r"""(?:src|href)=["'](?:\.\./)+""", read())]
ROOT = DECK.parents[max(_ups)] if _ups else DECK.parent
DECK_URL = "/" + quote(DECK.relative_to(ROOT).as_posix())

watched = {DECK: DECK.stat().st_mtime_ns}  # every file the page has loaded
own_write = None  # text the editor itself last wrote to the deck
version = 0
changed = threading.Condition()


def watch():
    global version
    while True:
        time.sleep(0.4)
        dirty = False
        for path, seen in list(watched.items()):
            try:
                now = path.stat().st_mtime_ns
            except OSError:
                continue
            if now != seen:
                watched[path] = now
                dirty = dirty or path != DECK or read() != own_write
        if dirty:
            with changed:
                version += 1
                changed.notify_all()


undo, redo = [], []  # earlier and later versions of the deck text, editor writes only


def apply(body):
    """Run one edit as splices on the source. Returns the new rev and where every element moved to."""
    global own_write
    text = read()
    if body["op"] in ("undo", "redo"):
        src, dst = (undo, redo) if body["op"] == "undo" else (redo, undo)
        if not src or text != own_write:  # nothing to undo, or someone else wrote since
            return None
        dst.append(text)
        new, moves = src.pop(), None
    else:
        done = splice(text, body) if body.get("rev") == rev_of(text) else None
        if not done:
            return None
        new, moves = done
        undo.append(text)
        redo.clear()
    with open(DECK, "w", encoding="utf-8", newline="") as f:
        f.write(new)
    own_write = new
    return {"rev": rev_of(new), "moves": moves}


def write_selection(body):
    text = read()
    scan = Scan(text)
    elements = []
    for item in body["elements"]:
        el = scan.by_pos.get(item["pos"]) if body.get("rev") == rev_of(text) else None
        if not el:
            continue
        end = el["end"] or el["open_end"]
        elements.append({
            "slide": item["slide"],
            "label": item["label"],
            "selector": item["selector"],
            "file": str(DECK),
            "lines": [scan.line(el["start"]), scan.line(end)],
            "rect": item["rect"],
            "html": text[el["start"]:end] if end - el["start"] <= 4000 else text[el["start"]:el["start"] + 4000] + " ...",
            "pos": el["start"],
        })
    STATE.mkdir(exist_ok=True)
    (STATE / ".gitignore").write_text("*\n")
    (STATE / "selection.json").write_text(json.dumps({
        "deck": str(DECK),
        "updated": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
        "note": body.get("note", ""),
        "screenshot": f"curl -s http://127.0.0.1:{PORT}/__editor/shot",
        "elements": elements,
    }, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


CHROME = next((p for p in map(shutil.which, ("google-chrome", "chromium", "chromium-browser", "chrome", "msedge")) if p), None)


def snap(query, slide, out):
    """Screenshot one slide of the served deck in headless Chrome."""
    subprocess.run([CHROME, *os.environ.get("DECK_EDITOR_CHROME_ARGS", "").split(), "--headless", "--hide-scrollbars", "--window-size=1920,1080", "--virtual-time-budget=4000",
                    f"--screenshot={out}", f"http://127.0.0.1:{PORT}{DECK_URL}?{query}#{slide}"], capture_output=True, timeout=60)
    return out.exists()


def write_prompt(body):
    """All comments and drawings as one prompt: sources as text, one marked screenshot per slide."""
    text = read()
    scan = Scan(text)
    fresh = body.get("rev") == rev_of(text)
    w, h = body["size"]
    STATE.mkdir(exist_ok=True)
    (STATE / ".gitignore").write_text("*\n")
    out = [f"Feedback on the deck `{DECK}`, collected in the deck editor. Each comment names its elements by source "
           "line. Each screenshot shows the slide with the commented elements boxed and numbered in orange and my "
           "drawings in red.", ""]
    marks.clear()
    for s in body["slides"]:
        svg = [f'<svg viewBox="0 0 {w} {h}" style="position:absolute;inset:0;width:100%;height:100%;z-index:2147483647;pointer-events:none">']
        out += [f"## Slide {s['n']}: {s['label']}", ""]
        for c in s["comments"]:
            out += [f"### Comment {c['n']}", "", c["note"] or "(no text, see the drawing)", ""]
            for item in c["elements"]:
                x, y, rw, rh = item["rect"]
                svg.append(f'<rect x="{x}" y="{y}" width="{rw}" height="{rh}" fill="none" stroke="#ff9f1a" stroke-width="5"/>'
                           f'<rect x="{x}" y="{y - 44}" width="52" height="44" fill="#ff9f1a"/>'
                           f'<text x="{x + 26}" y="{y - 10}" font-size="32" font-weight="700" font-family="sans-serif" text-anchor="middle">{c["n"]}</text>')
                el = scan.by_pos.get(item["pos"]) if fresh else None
                if el:
                    end = el["end"] or el["open_end"]
                    src = text[el["start"]:end] if end - el["start"] <= 1500 else text[el["start"]:el["start"] + 1500] + " ..."
                    out += [f"`{DECK.name}` lines {scan.line(el['start'])} to {scan.line(end)}, `{item['selector']}`", "", "```html", src, "```", ""]
                else:
                    out += [f"`{item['selector']}`", ""]
        svg += [f'<polyline points="{" ".join(map(str, stroke))}" fill="none" stroke="#ff2d2d" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/>'
                for stroke in s["strokes"]]
        if s["strokes"]:
            out += ["I drew on this slide: see the red strokes on the screenshot.", ""]
        marks[int(s["pos"])] = "".join(svg) + "</svg>"
    for s in body["slides"]:  # after every slide's marks are known to the served page
        png = STATE / f"slide-{s['n']:02d}.png"
        png.unlink(missing_ok=True)
        if CHROME and snap("de-marks", s["n"], png):
            at = out.index(f"## Slide {s['n']}: {s['label']}")
            out[at + 1:at + 1] = ["", f"Screenshot: `{png}`"]
    prompt = "\n".join(out).rstrip() + "\n"
    (STATE / "prompt.md").write_text(prompt, encoding="utf-8")
    return prompt


def git(*args):
    return subprocess.run(["git", "-C", str(DECK.parent), *args], capture_output=True, text=True).stdout.strip()


def send_issue(body):
    """File the feedback prompt as a GitHub issue that names the branch, the worktree and the deck."""
    prompt = write_prompt(body)
    top, branch = Path(git("rev-parse", "--show-toplevel")), git("branch", "--show-current")
    deck = DECK.relative_to(top).as_posix()
    issue = {
        "title": f"Deck feedback: {deck} ({branch})",
        "labels": ["deck-feedback"],
        "body": f"Branch: `{branch}`\nWorktree: `{top}`\nDeck: `{deck}`\n\n"
                f"The screenshots are files on the machine that holds the worktree.\n\n{prompt}",
    }
    req = urllib.request.Request(f"https://api.github.com/repos/{REPO}/issues", json.dumps(issue).encode(),
                                 {"Authorization": f"Bearer {TOKEN}", "Accept": "application/vnd.github+json"})
    try:
        with urllib.request.urlopen(req, timeout=30) as res:
            return 200, json.load(res)["html_url"]
    except OSError as e:  # the prompt stays in prompt.md either way
        return 502, f"GitHub refused the issue: {e}"


def screenshot():
    """Render the selected slide in headless Chrome with the selection outlined."""
    if not CHROME:
        return 501, "no Chrome or Chromium binary on PATH"
    try:
        elements = json.loads((STATE / "selection.json").read_text(encoding="utf-8"))["elements"]
    except (OSError, ValueError):
        elements = []
    if not elements:
        return 409, "nothing is selected in the editor"
    out = STATE / "selection.png"
    out.unlink(missing_ok=True)
    picked = ",".join(str(el["pos"]) for el in elements)
    return (200, str(out)) if snap(f"de-shot={picked}", elements[0]["slide"], out) else (500, "Chrome wrote no screenshot")


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *args):
        pass

    def send(self, status, body, ctype="text/plain; charset=utf-8"):
        body = body if isinstance(body, bytes) else body.encode()
        self.send_response(status)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def local(self):
        """Refuse other sites: a rebound DNS name on GET, a cross-site form or fetch on POST."""
        names = [f"127.0.0.1:{PORT}", f"localhost:{PORT}"] + [HOST] * bool(HOST)
        origin = self.headers.get("Origin")
        ok = self.headers.get("Host") in names and (origin is None or origin.split("//")[-1] in names)
        if not ok:
            self.send(403, "forbidden")
        return ok

    def do_GET(self):
        if not self.local():
            return
        url = urlsplit(self.path)
        if url.path == "/":
            self.send_response(302)
            self.send_header("Location", DECK_URL)
            self.send_header("Content-Length", "0")
            self.end_headers()
        elif url.path.removeprefix("/__editor/") in SCRIPTS:
            self.send(200, (HERE / url.path.removeprefix("/__editor/")).read_bytes(), "text/javascript")
        elif url.path == "/__editor/shot":
            self.send(*screenshot())
        elif url.path == "/__editor/events":
            self.events()
        else:
            path = (ROOT / unquote(url.path).lstrip("/")).resolve()
            if not path.is_relative_to(ROOT) or not path.is_file():
                return self.send(404, "not found")
            if path == DECK:
                shot = re.match(r"de-shot=([\d,]+)", url.query)
                return self.send(200, annotated(read(), shot.group(1).split(",") if shot else (), url.query == "de-marks"),
                                 "text/html; charset=utf-8")
            watched.setdefault(path, path.stat().st_mtime_ns)
            self.send(200, path.read_bytes(), mimetypes.guess_type(path.name)[0] or "application/octet-stream")

    def events(self):
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        seen = version
        try:
            while True:
                with changed:
                    changed.wait(15)
                self.wfile.write(b"data: reload\n\n" if version != seen else b": ping\n\n")
                self.wfile.flush()
                seen = version
        except OSError:
            pass

    def do_POST(self):
        if not self.local():
            return
        data = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        if self.path.startswith("/__editor/upload?"):  # an image for a swap, stored under a name its content fixes
            name = re.sub(r"[^\w.-]", "-", Path(unquote(urlsplit(self.path).query)).name)
            name = f"{Path(name).stem}-{hashlib.sha1(data).hexdigest()[:6]}{Path(name).suffix}"
            (DECK.parent / "assets").mkdir(exist_ok=True)
            (DECK.parent / "assets" / name).write_bytes(data)
            return self.send(200, "assets/" + name)
        body = json.loads(data or b"{}")
        if self.path == "/__editor/selection":
            write_selection(body)
            self.send(200, "{}", "application/json")
        elif self.path == "/__editor/prompt":
            self.send(200, write_prompt(body))
        elif self.path == "/__editor/issue" and REPO and TOKEN:
            self.send(*send_issue(body))
        elif self.path == "/__editor/op":
            result = apply(body)
            self.send(200 if result else 409, json.dumps(result or {}), "application/json")
        else:
            self.send(404, "not found")


if __name__ == "__main__":
    threading.Thread(target=watch, daemon=True).start()
    server = ThreadingHTTPServer(("0.0.0.0" if HOST else "127.0.0.1", PORT), Handler)
    server.daemon_threads = True
    print(f"Deck editor: http://127.0.0.1:{PORT}{DECK_URL}\nSelection file: {STATE / 'selection.json'}", flush=True)
    server.serve_forever()
