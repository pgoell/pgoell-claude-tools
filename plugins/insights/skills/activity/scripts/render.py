# /// script
# requires-python = ">=3.11"
# dependencies = ["jinja2>=3.1"]
# ///
"""Add the model's notes to a day's activity JSON, check them, and render the HTML page.

Reads <activity>/<date>.json as collect.py wrote it. With --notes FILE it
first takes `needs` and `shipped` from that file and saves them into the JSON.
It then checks every rule the contract marks as checked: the brevity limits,
the banned punctuation, and that every link and session id it is about to
print came from collect.py, so the page cannot point at something nobody
counted. Exits 1 with every error listed and renders nothing. It works out the
totals and the outlier flags itself.
"""

import json
import re
import sys
from datetime import datetime
from pathlib import Path

import jinja2

sys.path.append(str(Path(__file__).resolve().parents[2] / "digest" / "scripts"))
from common import BERLIN, analysed_day, base_parser  # noqa: E402

ACTIVITY = "07 Activity"
TEMPLATE = Path(__file__).resolve().parent.parent / "references" / "page.html.j2"
HEADLINE_MAX, WHY_MAX, SUMMARY_MAX, LABEL_MAX = 80, 160, 300, 40
MAX_NEEDS = 8
URL_KEYS = ("url", "merged_url", "pr_urls")
BANNED = re.compile("[\u2014\u2013\u00b7]| - ")
LIMITS = {"sessions": 40, "commits": 40, "prs_opened": 20, "issues_opened": 30, "loop_minutes": 480, "cost": 200}
"""A churn cell at or over its limit is flagged as an outlier."""
SUMS = ("sessions", "commits", "prs_opened", "prs_merged", "issues_opened", "issues_closed", "loop_minutes")


def urls(node):
    """Every https link collect.py put in a URL field. A title or a path that looks like a link is not one."""
    if isinstance(node, dict):
        for k, v in node.items():
            if k in URL_KEYS:
                yield from (u for u in ([v] if isinstance(v, str) else v or []) if u.startswith("https://"))
            else:
                yield from urls(v)
    elif isinstance(node, list):
        for v in node:
            yield from urls(v)


def check(page: dict) -> list[str]:
    collected = {k: v for k, v in page.items() if k not in ("needs", "shipped")}
    known = set(urls(collected))
    sessions = {pr["session"]["id"] for pr in page["open_prs"] if pr["session"]}
    merged = {r["name"] for r in page["repos"] if r["prs_merged"]}
    errors = []

    def prose(where: str, text, limit: int) -> None:
        if not isinstance(text, str) or not text.strip():
            errors.append(f"{where}: missing")
        elif len(text) > limit:
            errors.append(f"{where}: {len(text)} characters, the limit is {limit}")
        elif BANNED.search(text):
            errors.append(f"{where}: holds a dash, an interpunct or a hyphen used as punctuation")

    if len(page["needs"]) > MAX_NEEDS:
        errors.append(f"needs: {len(page['needs'])} items, the limit is {MAX_NEEDS}; fold the rest into grouped items that keep their links")
    for i, n in enumerate(page["needs"]):
        where = f"needs[{i}]"
        prose(f"{where}.headline", n.get("headline"), HEADLINE_MAX)
        if re.search(r"[\[\]<>]", n.get("headline") or ""):
            errors.append(f"{where}.headline: holds a bracket, which breaks the daily note link")
        prose(f"{where}.why", n.get("why"), WHY_MAX)
        for link in n.get("links", []):
            if link.get("url") not in known:
                errors.append(f"{where}: link {link.get('url')!r} is not in the collected data")
            prose(f"{where}: link label", link.get("label"), LABEL_MAX)
        if n.get("resume") and n["resume"] not in sessions:
            errors.append(f"{where}: session {n['resume']!r} is not in the collected data")
    for name, summary in page["shipped"].items():
        where = f"shipped[{name!r}]"
        if name not in merged:
            errors.append(f"{where}: no repo of that name merged a PR")
        prose(where, summary, SUMMARY_MAX)
        if isinstance(summary, str) and len(re.findall(r"[.!?](?:\s|$)", summary)) > 2:
            errors.append(f"{where}: more than two sentences")
    return errors


def main() -> None:
    parser = base_parser(__doc__.splitlines()[0])
    parser.add_argument("--notes", type=Path, help="JSON file with the model's `needs` and `shipped`")
    args = parser.parse_args()
    day = analysed_day(args)
    folder = args.vault / args.periodic / ACTIVITY
    source = folder / f"{day.isoformat()}.json"
    page = json.loads(source.read_text())
    if args.notes:
        notes = json.loads(args.notes.read_text())
        page["needs"], page["shipped"] = notes.get("needs", []), notes.get("shipped", {})

    errors = check(page)
    if errors:
        print("\n".join(errors), file=sys.stderr)
        print(f"{len(errors)} errors; nothing rendered", file=sys.stderr)
        sys.exit(1)
    source.write_text(json.dumps(page, ensure_ascii=False, indent=1))

    for r in page["repos"]:
        r["flags"] = [k for k, limit in LIMITS.items() if (r.get(k) or 0) >= limit]
    view = {
        "totals": {k: sum(r[k] for r in page["repos"]) for k in SUMS},
        "shipped": [r for r in page["repos"] if r["prs_merged"]],
        "flagged": sum(len(r["flags"]) for r in page["repos"]),
        "unavailable": [k for k, v in page["sources"].items() if v != "ok"],
        "date_display": f"{day:%A} {day.day} {day:%B %Y}",
        "generated": datetime.now(BERLIN).strftime("%Y-%m-%d %H:%M"),
        "limits": LIMITS,
    }
    env = jinja2.Environment(loader=jinja2.FileSystemLoader(TEMPLATE.parent), autoescape=True)
    env.filters["tokens"] = lambda n: "n/a" if n is None else f"{n / 1e6:.1f}M" if n >= 1e6 else f"{n / 1e3:.0f}k"
    env.filters["usd"] = lambda n: "n/a" if n is None else f"${n:,.2f}"
    out = folder / f"{day.isoformat()}.html"
    out.write_text(env.get_template(TEMPLATE.name).render(page=page, view=view))
    print(f"rendered {out}: {len(page['needs'])} need you, {len(view['shipped'])} repos shipped, {len(page['repos'])} repos in churn")


if __name__ == "__main__":
    main()
