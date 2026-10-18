# /// script
# requires-python = ">=3.11"
# dependencies = ["pyyaml>=6"]
# ///
"""Fill league tables into an edition from sportschau.de.

Reads `tables:` on each section of config/topics.yaml, a list of
`{name, slug}` where slug is the league's path on sportschau.de
(`deutschland-bundesliga` for /live-und-ergebnisse/fussball/deutschland-bundesliga/tabelle),
fetches each table page and writes the rows into that section of
<newspaper>/<date>.json as `tables`. A league that fails to fetch or parse is
left out with a warning, and a section the edition does not carry is skipped,
so a morning run still produces a paper.
"""

import html
import json
import re
import sys
import urllib.error
import urllib.request

import yaml
from common import base_parser, newspaper_dir, today

BASE = "https://www.sportschau.de/live-und-ergebnisse/fussball/{slug}/tabelle"
AGENT = "Mozilla/5.0 (X11; Linux x86_64) Chrome/128.0 Safari/537.36"
ROW = re.compile(r'<tr class="[^"]*\bstanding standing-\d+">(.*?)</tr>', re.S)
CELL = re.compile(r'<td class="([^"]*)">(.*?)</td>', re.S)
TAG = re.compile(r"<[^>]+>")
MATCHDAY = re.compile(r"<title>[^<]*Tabelle - ([^<|]*?) - \d{4}/\d{4}")


def text(cell: str) -> str:
    return html.unescape(TAG.sub("", cell)).strip()


def parse(page: str) -> tuple[str | None, list[dict]]:
    rows = []
    for row in ROW.findall(page):
        cells = {cls.split()[0]: (cls, text(body)) for cls, body in CELL.findall(row)}
        trend = cells.get("standing-tendency", ("", ""))[0].rsplit("-", 1)[-1]
        rows.append(
            {
                "rank": int(cells["standing-rank"][1]),
                "team": cells["team-shortname"][1],
                "played": int(cells["standing-games_played"][1]),
                "won": int(cells["standing-win"][1]),
                "drawn": int(cells["standing-draw"][1]),
                "lost": int(cells["standing-lost"][1]),
                "goals": cells["standing-goaldiff"][1],
                "diff": int(cells["standing-difference"][1]),
                "points": int(cells["standing-points"][1]),
                "trend": trend if trend in ("up", "down") else None,
            }
        )
    match = MATCHDAY.search(page)
    return (match.group(1).strip() if match else None), rows


def fetch(slug: str) -> str:
    request = urllib.request.Request(BASE.format(slug=slug), headers={"User-Agent": AGENT})
    with urllib.request.urlopen(request, timeout=20) as response:
        return response.read().decode("utf-8", "replace")


def main() -> None:
    args = base_parser(__doc__.splitlines()[0]).parse_args()
    day = (args.date or today()).isoformat()
    folder = newspaper_dir(args.vault, args.periodic)
    path = folder / f"{day}.json"

    topics = yaml.safe_load((folder / "config" / "topics.yaml").read_text()) or {}
    edition = json.loads(path.read_text())
    sections = {s["id"]: s for s in edition.get("sections", [])}
    for config in topics.get("sections", []):
        leagues = config.get("tables") or []
        if not leagues:
            continue
        section = sections.get(config["id"])
        if section is None:
            print(f"warning: section {config['id']!r} is not in the edition; its tables are skipped", file=sys.stderr)
            continue
        section["tables"] = []
        for league in leagues:
            try:
                matchday, rows = parse(fetch(league["slug"]))
            except (urllib.error.URLError, TimeoutError, KeyError, ValueError) as error:
                print(f"warning: no table for {league['name']} ({error})", file=sys.stderr)
                continue
            if not rows:
                print(f"warning: no table rows for {league['name']} on {BASE.format(slug=league['slug'])}", file=sys.stderr)
                continue
            section["tables"].append({"name": league["name"], "matchday": matchday, "url": BASE.format(slug=league["slug"]), "rows": rows})
            print(f"table: {league['name']}, {matchday}, {len(rows)} rows")
    path.write_text(json.dumps(edition, ensure_ascii=False, indent=2) + "\n")


if __name__ == "__main__":
    main()
