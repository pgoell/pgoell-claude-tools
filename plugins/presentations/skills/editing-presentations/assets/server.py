#!/usr/bin/env python3
"""Local editor server for one HTML deck. Standard library only.

Usage: python3 server.py <deck.html> [port]

Serves the deck with a `data-de="<source offset>"` attribute on every element
inside <deck-stage> and an overlay script. The file on disk never carries
either: every edit is a splice of the source text at offsets, so the bytes
outside the edited span stay as they were.
"""
import hashlib
import html
import json
import mimetypes
import re
import shutil
import subprocess
import sys
import threading
import time
from html.parser import HTMLParser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import quote, unquote, urlsplit

HERE = Path(__file__).resolve().parent
DECK = Path(sys.argv[1]).resolve()
PORT = int(sys.argv[2]) if len(sys.argv) > 2 else 4747
STATE = DECK.parent / ".deck-editor"
VOID = {"area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "source", "track", "wbr"}


def read():
    with open(DECK, encoding="utf-8", newline="") as f:
        return f.read()


def rev_of(text):
    return hashlib.sha1(text.encode()).hexdigest()[:12]


class Scan(HTMLParser):
    """Source offsets of every element: start, open_end, close, end.

    An element whose end tag is missing keeps end=None and is not editable.
    """

    def __init__(self, text):
        super().__init__(convert_charrefs=False)
        self.text, self.els, self.stack, self.foreign = text, [], [], 0
        self.lines = [0] + [m.end() for m in re.finditer("\n", text)]
        self.feed(text)
        self.close()
        self.by_pos = {el["start"]: el for el in self.els}  # for display
        self.closed = {el["start"]: el for el in self.els if el["end"]}  # for edits

    def at(self):
        line, col = self.getpos()
        return self.lines[line - 1] + col

    def handle_starttag(self, tag, attrs, closed=False):
        start = self.at()
        el = {"tag": tag, "start": start, "open_end": start + len(self.get_starttag_text()), "close": None, "end": None}
        self.els.append(el)
        if tag in VOID or (closed and self.foreign):
            el["close"] = el["end"] = el["open_end"]
            return
        self.foreign += tag in ("svg", "math")
        self.stack.append(el)

    def handle_startendtag(self, tag, attrs):
        self.handle_starttag(tag, attrs, True)

    def handle_endtag(self, tag):
        if not any(el["tag"] == tag for el in self.stack):
            return
        start = self.at()
        while True:
            el = self.stack.pop()
            self.foreign -= el["tag"] in ("svg", "math")
            if el["tag"] == tag:
                el["close"], el["end"] = start, self.text.index(">", start) + 1
                return

    def line(self, offset):
        lo, hi = 0, len(self.lines)
        while hi - lo > 1:
            mid = (lo + hi) // 2
            lo, hi = (mid, hi) if self.lines[mid] <= offset else (lo, mid)
        return lo + 1

    def in_stage(self):
        stage = next((el for el in self.els if el["tag"] == "deck-stage" and el["end"]), None)
        return [el for el in self.els if stage and stage["start"] < el["start"] < stage["end"]]


def annotated(text, outline=()):
    """The deck as served: offsets on every slide element, overlay script appended."""
    out, at = [], 0
    for el in Scan(text).in_stage():
        cut = el["start"] + 1 + len(el["tag"])
        out += [text[at:cut], f' data-de="{el["start"]}"']
        at = cut
    html = "".join(out) + text[at:]
    if outline:  # screenshot render: mark the selection, no overlay, no rail
        marks = ",".join(f'[data-de="{int(p)}"]' for p in outline)
        return html.replace("<deck-stage", "<deck-stage no-rail", 1) + (
            f"<style>{marks}{{outline:6px solid #ff2d95;outline-offset:6px}}</style>"
        )
    return html + f'<script src="/__editor/overlay.js" data-rev="{rev_of(text)}"></script>'


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


def cut_start(text, el):
    """Start of an element including the line break and indent before it, so a move leaves no hole."""
    return re.search(r"(\r?\n)?[ \t]*\Z", text[:el["start"]]).start()


def op_text(scan, text, body):
    """Replace an element's content. Characters the source wrote as entities go back to that spelling."""
    el = scan.closed[body["pos"]]
    old, new = text[el["open_end"]:el["close"]], body["html"]
    for entity in set(re.findall(r"&#?\w+;", old)):
        char = html.unescape(entity)
        if char not in "&<>\"'" and char != entity:
            new = new.replace(char, entity)
    return [(el["open_end"], len(old), new)], None


def op_move(scan, text, body):
    """Move an element before or after a sibling."""
    el, ref = scan.closed[body["pos"]], scan.closed[body["ref"]]
    start = cut_start(text, el)
    at = ref["end"] if body["after"] else cut_start(text, ref)
    chunk = text[start:el["end"]]
    return [(start, len(chunk), ""), (at, 0, chunk)], (start, len(chunk), at)


OPS = {"text": op_text, "move": op_move}
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
        if body.get("rev") != rev_of(text):
            return None
        scan = Scan(text)
        try:
            splices, moved = OPS[body["op"]](scan, text, body)
        except (KeyError, TypeError):  # unknown element, or one without an end tag
            return None
        new = text
        for at, removed, inserted in sorted(splices, reverse=True):
            new = new[:at] + inserted + new[at + removed:]
        moves = {}
        for el in scan.in_stage():
            p = el["start"]
            if moved and moved[0] <= p < moved[0] + moved[1]:
                moves[p] = moved[2] - (moved[1] if moved[0] < moved[2] else 0) + p - moved[0]
            elif not any(at <= p < at + removed for at, removed, _ in splices):
                moves[p] = p + sum(len(inserted) - removed for at, removed, inserted in splices if at + removed <= p)
        # Every element must still sit where the map says, or the page reloads instead of trusting it.
        if any(new[at:at + 1 + len(scan.by_pos[old]["tag"])].lower() != "<" + scan.by_pos[old]["tag"] for old, at in moves.items()):
            return None
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


def screenshot():
    """Render the selected slide in headless Chrome with the selection outlined."""
    chrome = next((p for p in map(shutil.which, ("google-chrome", "chromium", "chromium-browser", "chrome", "msedge")) if p), None)
    if not chrome:
        return 501, "no Chrome or Chromium binary on PATH"
    try:
        elements = json.loads((STATE / "selection.json").read_text(encoding="utf-8"))["elements"]
    except (OSError, ValueError):
        elements = []
    if not elements:
        return 409, "nothing is selected in the editor"
    out = STATE / "selection.png"
    marks = ",".join(str(el["pos"]) for el in elements)
    url = f"http://127.0.0.1:{PORT}{DECK_URL}?de-shot={marks}#{elements[0]['slide']}"
    subprocess.run([chrome, "--headless", "--hide-scrollbars", "--window-size=1920,1167", "--virtual-time-budget=4000",
                    f"--screenshot={out}", url], capture_output=True, timeout=60)
    return (200, str(out)) if out.exists() else (500, "Chrome wrote no screenshot")


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
        names = (f"127.0.0.1:{PORT}", f"localhost:{PORT}")
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
        elif url.path == "/__editor/overlay.js":
            self.send(200, (HERE / "overlay.js").read_bytes(), "text/javascript")
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
                return self.send(200, annotated(read(), shot.group(1).split(",") if shot else ()), "text/html; charset=utf-8")
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
        body = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))) or b"{}")
        if self.path == "/__editor/selection":
            write_selection(body)
            self.send(200, "{}", "application/json")
        elif self.path == "/__editor/op":
            result = apply(body)
            self.send(200 if result else 409, json.dumps(result or {}), "application/json")
        else:
            self.send(404, "not found")


if __name__ == "__main__":
    threading.Thread(target=watch, daemon=True).start()
    server = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    server.daemon_threads = True
    print(f"Deck editor: http://127.0.0.1:{PORT}{DECK_URL}\nSelection file: {STATE / 'selection.json'}", flush=True)
    server.serve_forever()
