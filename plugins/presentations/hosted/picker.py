#!/usr/bin/env python3
"""Deck picker for the hosted editor. Standard library only.

Usage: python3 picker.py <repo>

Lists the repo's branches, local and on origin, and the decks of the one
picked, on port 8001. A click on a deck starts server.py on it on port 8000,
in place of the deck open before: one deck is open at a time. A branch with
no worktree gets one under .worktrees/ first, because the editor and the
Claude session both work on files. The reverse proxy sends /__decks/* here
and everything else to port 8000.
"""
import base64
import html
import http.client
import os
import subprocess
import sys
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlencode, urlsplit

REPO = Path(sys.argv[1]).resolve()
SERVER = Path(__file__).resolve().parent / "server.py"
editor = None

GROUPS = {"tree": "Worktrees", "local": "Local branches", "remote": "On origin", "away": "Checked out outside the repo"}

STYLE = """
:root{color-scheme:light dark;--bg:#f6f5f2;--card:#fff;--ink:#1c1b19;--dim:#6f6b63;--line:#e2dfd8;--pick:#1c1b19;--onpick:#fff}
@media(prefers-color-scheme:dark){:root{--bg:#161513;--card:#201f1c;--ink:#ecebe7;--dim:#9a968d;--line:#33312c;--pick:#ecebe7;--onpick:#161513}}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--ink);font:15px/1.45 system-ui,sans-serif}
a{color:inherit;text-decoration:none}
.page{display:grid;grid-template-columns:19em 1fr;gap:2.5em;max-width:76em;margin:0 auto;padding:2em 1.25em}
@media(max-width:760px){.page{grid-template-columns:1fr;gap:1.5em;padding:1em}}
h1{font-size:1.5em;margin:0 0 .2em;overflow-wrap:anywhere}
h2{font-size:.72em;letter-spacing:.08em;text-transform:uppercase;color:var(--dim);margin:1.6em 0 .5em}
.top{display:flex;justify-content:space-between;align-items:center}
.top b{font-size:1.1em}
.btn{border:1px solid var(--line);border-radius:6px;padding:.25em .7em;font-size:.85em;background:var(--card)}
.btn:hover,.branch:hover,.file:hover{border-color:var(--dim)}
.branch{display:flex;justify-content:space-between;gap:.8em;padding:.4em .6em;border:1px solid transparent;border-radius:6px}
.branch span:first-child{overflow-wrap:anywhere}
.branch small,.sub{color:var(--dim);font-size:.85em;white-space:nowrap}
.branch.on{background:var(--pick);color:var(--onpick)}
.branch.on small{color:inherit;opacity:.7}
.sub{white-space:normal;margin:0 0 1.5em}
.decks{display:grid;grid-template-columns:repeat(auto-fill,minmax(17em,1fr));gap:1em}
.deck{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:1em}
.deck h3{font-size:1em;margin:0 0 .6em;overflow-wrap:anywhere}
.file{display:block;padding:.3em .55em;margin:.3em 0 0;border:1px solid var(--line);border-radius:6px;font-size:.9em;overflow-wrap:anywhere}
.err{white-space:pre-wrap;border:1px solid #c0392b;border-radius:8px;padding:.7em 1em;margin:0 0 1.5em;font:13px/1.4 ui-monospace,monospace}
"""


def git(*args, **kw):
    return subprocess.run(["git", "-C", str(REPO), *args], capture_output=True, text=True, **kw)


def trees():
    """Branch name to worktree folder, for every worktree git knows."""
    found, path = {}, None
    for line in git("worktree", "list", "--porcelain").stdout.splitlines():
        if line.startswith("worktree "):
            path = Path(line[9:])
        elif line.startswith("branch refs/heads/"):
            found[line[18:]] = path
    return found


def branches():
    """Branch name to (group, age), newest commit first. A branch on origin that also exists locally counts as local."""
    found = {}
    refs = git("for-each-ref", "--sort=-committerdate", "--format=%(refname)\t%(committerdate:relative)", "refs/heads", "refs/remotes/origin")
    for line in refs.stdout.splitlines():
        ref, age = line.split("\t")
        group, name = ("local", ref[11:]) if ref.startswith("refs/heads/") else ("remote", ref[20:])
        if name == "HEAD" or (group == "remote" and name in found):
            continue
        found[name] = (group, age)
    for name, tree in trees().items():
        if name in found:
            # The container sees the repo folder only; a worktree outside it cannot be opened here.
            found[name] = ("tree" if tree.is_relative_to(REPO) and tree.exists() else "away", found[name][1])
    return found


def decks(name, group):
    """HTML files that hold a <deck-stage>, at most four folders deep, hidden folders left out.

    A worktree is read from disk, so decks not yet committed show up. Any other branch is read from git.
    """
    if group == "tree":
        tree = trees()[name]
        paths = [p.relative_to(tree) for depth in ("*", "*/*", "*/*/*", "*/*/*/*") for p in sorted(tree.glob(depth + ".html"))]
    else:
        ref = f"origin/{name}" if group == "remote" else name
        hits = git("grep", "-l", "-F", "<deck-stage", ref, "--", "*.html").stdout.splitlines()
        paths = sorted(Path(hit.split(":", 1)[1]) for hit in hits)
    found = []
    for rel in paths:
        if len(rel.parts) > 4 or any(part.startswith(".") for part in rel.parts) or "node_modules" in rel.parts:
            continue
        if group == "tree":
            with open(tree / rel, encoding="utf-8", errors="replace") as f:
                if "<deck-stage" not in f.read():
                    continue
        found.append(rel)
    return found


def tree_dir(name):
    return REPO / ".worktrees" / name.replace("/", "-")


def tree_for(name):
    """The worktree of a branch, made under .worktrees/ when the branch has none. An error text when git refuses."""
    tree = trees().get(name)
    if tree:
        return tree, ""
    # With a name that exists on origin only, git makes the local branch and sets it to track.
    done = git("worktree", "add", str(tree_dir(name)), name)
    return tree_dir(name), done.stderr if done.returncode else ""


def fetch():
    """Fetch origin with the GitHub token. The token needs "Contents: read". Returns an error text, empty when it worked."""
    basic = base64.b64encode(f"x-access-token:{os.environ.get('GITHUB_TOKEN', '')}".encode()).decode()
    env = {**os.environ, "GIT_TERMINAL_PROMPT": "0", "GIT_CONFIG_COUNT": "1",
           "GIT_CONFIG_KEY_0": "http.extraheader", "GIT_CONFIG_VALUE_0": f"Authorization: Basic {basic}"}
    done = git("fetch", "--prune", "origin", env=env)
    return f"git fetch failed:\n{done.stderr}" if done.returncode else ""


def page(name, error=""):
    known = branches()
    if name not in known:
        name = git("branch", "--show-current").stdout.strip()
    esc = html.escape
    out = [f"<!doctype html><meta charset=utf-8><meta name=viewport content='width=device-width'><title>Decks</title><style>{STYLE}</style>",
           f"<div class=page><nav><div class=top><b>Decks</b><a class=btn href='/__decks/fetch?{urlencode({'b': name})}'>Fetch origin</a></div>"]
    for group, title in GROUPS.items():
        rows = [(n, age) for n, (g, age) in known.items() if g == group]
        if rows:
            out.append(f"<h2>{title}</h2>")
        out += [f"<a class='branch{' on' if n == name else ''}' href='/__decks/?{urlencode({'b': n})}'><span>{esc(n)}</span><small>{esc(age)}</small></a>"
                for n, age in rows]
    out.append(f"</nav><main><h1>{esc(name)}</h1>")
    group = known.get(name, ("", ""))[0]
    note = {"tree": f"Worktree at {trees()[name]}" if group == "tree" else "",
            "local": f"No worktree yet. Opening a deck makes one at {tree_dir(name)}.",
            "remote": f"On origin only. Opening a deck makes a local branch and a worktree at {tree_dir(name)}.",
            "away": "Checked out in a worktree outside the repo folder, which the editor cannot reach."}.get(group, "")
    out.append(f"<p class=sub>{esc(note)}</p>")
    if error:
        out.append(f"<p class=err>{esc(error)}</p>")
    folders = {}
    for rel in decks(name, group) if group and group != "away" else []:
        folders.setdefault(rel.parent, []).append(rel)
    out.append("<div class=decks>")
    for folder, files in folders.items():
        out.append(f"<div class=deck><h3>{esc(folder.name or name)}</h3>")
        out += [f"<a class=file href='/__decks/open?{urlencode({'b': name, 'f': rel.as_posix()})}'>{esc(rel.name)}</a>" for rel in files]
        out.append("</div>")
    if not folders and group != "away":
        out.append("<p class=sub>No decks on this branch.</p>")
    out.append("</div></main></div>")
    return "".join(out)


def open_deck(path):
    """Swap the editor for one on this deck. Returns the deck's URL once the editor answers."""
    global editor
    if editor:
        editor.terminate()
        editor.wait()
    editor = subprocess.Popen([sys.executable, str(SERVER), str(path), "8000"])
    for _ in range(50):
        try:
            conn = http.client.HTTPConnection("127.0.0.1", 8000, timeout=1)
            conn.request("GET", "/")
            return conn.getresponse().getheader("Location")
        except OSError:
            time.sleep(0.1)
    return "/__decks/"


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def redirect(self, to):
        self.send_response(302)
        self.send_header("Location", to)
        self.send_header("Content-Length", "0")
        self.end_headers()

    def do_GET(self):
        url = urlsplit(self.path)
        query = parse_qs(url.query)
        name, file = query.get("b", [""])[0], query.get("f", [""])[0]
        error = ""
        if url.path == "/__decks/fetch":
            error = fetch()
            if not error:
                return self.redirect(f"/__decks/?{urlencode({'b': name})}")
        if url.path == "/__decks/open" and name in branches():
            tree, error = tree_for(name)
            deck = (tree / file).resolve()
            if not error and deck.is_file() and deck.is_relative_to(tree):
                return self.redirect(open_deck(deck))
            error = error or f"{file} is not a file on {name}."
        body = page(name, error).encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    ThreadingHTTPServer(("0.0.0.0", 8001), Handler).serve_forever()
