# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Fetch the lead story's URL again and print its og meta and visible text.

Reads <newspaper>/<date>.json, GETs `lead.url` (redirects followed, 20 s
timeout) and prints `og:title` and `og:description` when present, then the
text without scripts, styles and tags, so the edition can check the lead's key
facts against the page.

A dead URL prints `error: lead url <url> is dead: <code>` and exits 1, where
code is 404, 410, refused, timeout, dns or ssl. Any other HTTP error is a site
turning the script away, not a dead story: it prints
`error: lead url <url> refused the fetch: HTTP <code>` and exits 2.
"""

import json
import re
import socket
import ssl
import sys
import urllib.error
import urllib.request
from html.parser import HTMLParser

from common import base_parser, newspaper_dir, today

AGENT = "Mozilla/5.0 (X11; Linux x86_64) Chrome/128.0 Safari/537.36"
LIMIT = 20000


class Text(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.parts: list[str] = []
        self.meta: dict[str, str] = {}
        self.skip = 0

    def handle_starttag(self, tag: str, attrs: list) -> None:
        if tag in ("script", "style"):
            self.skip += 1
        a = dict(attrs)
        if tag == "meta" and a.get("property") in ("og:title", "og:description") and a.get("content"):
            self.meta.setdefault(a["property"], a["content"])

    def handle_endtag(self, tag: str) -> None:
        if tag in ("script", "style") and self.skip:
            self.skip -= 1

    def handle_data(self, data: str) -> None:
        if not self.skip:
            self.parts.append(data)


def no_answer(error: OSError) -> str:
    reason = getattr(error, "reason", error)
    if isinstance(reason, (ssl.SSLError, ssl.CertificateError)):
        return "ssl"
    if isinstance(reason, socket.gaierror):
        return "dns"
    if isinstance(reason, TimeoutError):
        return "timeout"
    return "refused"


def main() -> None:
    args = base_parser(__doc__.splitlines()[0]).parse_args()
    day = (args.date or today()).isoformat()
    url = json.loads((newspaper_dir(args.vault, args.periodic) / f"{day}.json").read_text())["lead"]["url"]
    try:
        request = urllib.request.Request(url, headers={"User-Agent": AGENT})
        with urllib.request.urlopen(request, timeout=20) as response:
            html = response.read().decode(response.headers.get_content_charset() or "utf-8", errors="replace")
    except urllib.error.HTTPError as error:
        if error.code in (404, 410):
            print(f"error: lead url {url} is dead: {error.code}")
            sys.exit(1)
        print(f"error: lead url {url} refused the fetch: HTTP {error.code}")
        sys.exit(2)
    except OSError as error:
        print(f"error: lead url {url} is dead: {no_answer(error)}")
        sys.exit(1)
    parser = Text()
    parser.feed(html)
    for key in ("og:title", "og:description"):
        if key in parser.meta:
            print(f"{key}: {parser.meta[key]}")
    print(re.sub(r"\s+", " ", " ".join(parser.parts)).strip()[:LIMIT])


if __name__ == "__main__":
    main()
