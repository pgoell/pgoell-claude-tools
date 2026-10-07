# /// script
# requires-python = ">=3.11"
# dependencies = ["jinja2>=3.1", "pyyaml>=6"]
# ///
"""Render an edition's JSON into its HTML page with one of the shipped designs.

Reads <newspaper>/<date>.json and config/design.yaml, and writes
<newspaper>/<date>.html (or --out). The design is --design, else design.yaml's
`design:`. A design that is not installed falls back to `plain` with a warning,
so a morning run still produces a paper. Before rendering it sets
`edition.design_overrides` from design.yaml `overrides:` and, when the JSON
carries no `recent_feedback`, the three newest lines of memory/changelog.md.
It also adds `published_display` to every story and `generated_display` to the
edition, both in Europe/Berlin time ("7.10., 15:46"), because Jinja has no
time zones and the reader's clock is Berlin's.
"""

import json
import re
import sys
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

import jinja2
import yaml
from common import DESIGNS, base_parser, newspaper_dir, today

CHANGE = re.compile(r"^- (\d{4}-\d{2}-\d{2}): (.+)$")
FALLBACK = "plain"
BERLIN = ZoneInfo("Europe/Berlin")


def published(value: str) -> str:
    # A source that gives only a day (release notes, leaderboards) arrives as a bare
    # date or as midnight UTC; a clock time would be invented, so show the day alone.
    if len(value) == 10 or value.endswith(("T00:00:00Z", "T00:00:00+00:00")):
        return f"{int(value[8:10])}.{int(value[5:7])}."
    return berlin(datetime.fromisoformat(value))


def berlin(moment: datetime) -> str:
    # A time without an offset is taken as UTC, which is what the sources mostly mean.
    if moment.tzinfo is None:
        moment = moment.replace(tzinfo=ZoneInfo("UTC"))
    local = moment.astimezone(BERLIN)
    return f"{local.day}.{local.month}., {local:%H:%M}"


def stories(edition: dict) -> list[dict]:
    return [edition["lead"], *(s for sec in edition.get("sections", []) for s in sec.get("stories", []))]


def recent_feedback(changelog: Path, count: int = 3) -> list[str]:
    if not changelog.exists():
        return []
    lines = [m for m in map(CHANGE.match, changelog.read_text().splitlines()) if m]
    return [f"{m.group(1)}: {m.group(2)}" for m in lines[-count:]][::-1]


def main() -> None:
    parser = base_parser(__doc__.splitlines()[0])
    parser.add_argument("--design", help="design name, default from config/design.yaml")
    parser.add_argument("--out", type=Path, help="output file, default <newspaper>/<date>.html")
    args = parser.parse_args()
    day = (args.date or today()).isoformat()
    folder = newspaper_dir(args.vault, args.periodic)

    config = yaml.safe_load((folder / "config" / "design.yaml").read_text()) or {}
    design = args.design or config.get("design") or FALLBACK
    if not (DESIGNS / design / "template.html.j2").exists():
        installed = sorted(p.parent.name for p in DESIGNS.glob("*/template.html.j2"))
        print(f"warning: design {design!r} is not installed (have {installed}); using {FALLBACK!r}", file=sys.stderr)
        design = FALLBACK

    edition = json.loads((folder / f"{day}.json").read_text())
    edition["design_overrides"] = config.get("overrides") or {}
    edition.setdefault("recent_feedback", recent_feedback(folder / "memory" / "changelog.md"))
    edition["generated_display"] = berlin(datetime.now(BERLIN))
    for story in stories(edition):
        story["published_display"] = published(story["published"])

    env = jinja2.Environment(loader=jinja2.FileSystemLoader(DESIGNS / design), autoescape=True)
    html = env.get_template("template.html.j2").render(edition=edition)
    out = args.out or folder / f"{day}.html"
    out.write_text(html)
    print(f"rendered {out} with design {design!r}")


if __name__ == "__main__":
    main()
