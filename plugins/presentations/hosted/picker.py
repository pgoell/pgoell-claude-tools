#!/usr/bin/env python3
"""Deck picker for the hosted editor. Standard library only.

Usage: python3 picker.py <repo>

Lists every deck in the repo's checkout and in its worktrees under
.worktrees/, on port 8001. A click starts server.py on that deck on port 8000,
in place of the deck open before: one deck is open at a time. The reverse
proxy sends /__decks/* here and everything else to port 8000.
"""
import html
import http.client
import subprocess
import sys
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import quote, unquote, urlsplit

REPO = Path(sys.argv[1]).resolve()
SERVER = Path(__file__).resolve().parent / "server.py"
editor = None


def worktrees():
    extra = sorted(p for p in (REPO / ".worktrees").glob("*") if (p / ".git").exists())
    return [REPO, *extra]


def branch(tree):
    return subprocess.run(["git", "-C", str(tree), "branch", "--show-current"], capture_output=True, text=True).stdout.strip()


def decks(tree):
    """HTML files that hold a <deck-stage>, at most four folders deep, worktrees and hidden folders left out."""
    found = []
    for path in sorted(tree.glob("*.html")) + sorted(tree.glob("*/*.html")) + sorted(tree.glob("*/*/*.html")) + sorted(tree.glob("*/*/*/*.html")):
        rel = path.relative_to(tree)
        if any(part.startswith(".") for part in rel.parts) or "node_modules" in rel.parts:
            continue
        with open(path, encoding="utf-8", errors="replace") as f:
            if "<deck-stage" in f.read():
                found.append(rel)
    return found


def page():
    out = ["<!doctype html><meta charset=utf-8><meta name=viewport content='width=device-width'><title>Decks</title>",
           "<style>body{font:15px/1.5 system-ui,sans-serif;max-width:50em;margin:2em auto;padding:0 1em}"
           "h2{font-size:1em;margin:1.5em 0 .2em}a{display:block}</style><h1>Decks</h1>"]
    for tree in worktrees():
        out.append(f"<h2>{html.escape(branch(tree) or tree.name)}</h2>")
        out += [f'<a href="/__decks/open?{quote(str(tree / rel))}">{html.escape(rel.as_posix())}</a>' for rel in decks(tree)]
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

    def do_GET(self):
        url = urlsplit(self.path)
        deck = Path(unquote(url.query)).resolve()
        if url.path == "/__decks/open" and deck.is_file() and deck.is_relative_to(REPO):
            self.send_response(302)
            self.send_header("Location", open_deck(deck))
            self.send_header("Content-Length", "0")
            self.end_headers()
            return
        body = page().encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    ThreadingHTTPServer(("0.0.0.0", 8001), Handler).serve_forever()
