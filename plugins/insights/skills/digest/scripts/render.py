# /// script
# requires-python = ">=3.11"
# dependencies = ["jinja2>=3.1"]
# ///
"""Check a day's insights JSON against the contract and render it into its HTML page.

Reads <insights>/<date>.json, the review note <date>.md beside it, and
memory/applied.jsonl and problems.jsonl, and writes <insights>/<date>.html.
It works out everything a template cannot: totals, sparkline points, bar
widths, the sort order, the tally, each card's standing verdict, the fixes
waiting on a PR or deferred, and for each fix applied in the last 14 days
whether its problem still showed up on the analysed day. Exits 1 with every contract error
listed, rendering nothing, so a broken JSON never reaches the vault as a page.
"""

import json
import sys
from datetime import date, datetime, timedelta

import jinja2
from common import BERLIN, TEMPLATE, WINDOW, analysed_day, base_parser, insights_dir, read_jsonl

STATUSES = ("doc", "rec", "new", "fade")
ACTIONS = ("Opens a PR", "Adds a todo", "Adds a feedback line", "Watch only")
REQUIRED = ("id", "fingerprint", "group", "status", "kind", "title", "yesterday", "series", "projects", "what", "why",
            "verified", "fix", "destination", "action", "evidence")


def problems_errors(page: dict) -> list[str]:
    errors = []
    for key in ("date", "window", "scope", "problems", "seen"):
        if key not in page:
            errors.append(f"missing top-level key {key!r}")
    ids = set()
    for i, p in enumerate(page.get("problems", [])):
        where = f"problems[{i}] ({p.get('id', '?')})"
        errors += [f"{where}: missing {k!r}" for k in REQUIRED if k not in p]
        if p.get("id") in ids:
            errors.append(f"{where}: duplicate id")
        ids.add(p.get("id"))
        if p.get("status") not in STATUSES:
            errors.append(f"{where}: status must be one of {STATUSES}")
        if p.get("group") not in ("dev", "news"):
            errors.append(f"{where}: group must be 'dev' or 'news'")
        if p.get("action") not in ACTIONS:
            errors.append(f"{where}: action must be one of {ACTIONS}")
        if len(p.get("series", [])) != WINDOW:
            errors.append(f"{where}: series must hold {WINDOW} daily counts, oldest first")
        if p.get("action") == "Opens a PR" and not (p.get("target") or {}).get("repo"):
            errors.append(f"{where}: 'Opens a PR' needs target.repo")
        for line in p.get("fix", []):
            if not (isinstance(line, list) and len(line) == 2 and line[0] in ("a", "d", "c")):
                errors.append(f"{where}: fix lines are [\"a\"|\"d\"|\"c\", text]")
                break
    return errors


def decorate(p: dict, max_total: int) -> dict:
    series = p["series"]
    p["total"] = sum(series)
    p["days_hit"] = sum(1 for v in series if v)
    p["peak"] = max(series) if series else 0
    top = max(p["peak"], 1)
    step = (210 - 8) / (len(series) - 1)
    points = [(round(4 + i * step, 1), round(40 - v / top * 36, 1)) for i, v in enumerate(series)]
    p["spark_line"] = " ".join(f"{x},{y}" for x, y in points)
    p["spark_last"] = points[-1]
    p["bar_total"] = round(p["total"] / max_total * 100, 1)
    p["bar_yesterday"] = max(round(p["yesterday"] / max_total * 100, 1), 0.8)
    return p


def applied_lately(folder, day: date, page: dict) -> list[dict]:
    hits = {p["fingerprint"]: p["yesterday"] for p in page["problems"]}
    hits.update({s["fingerprint"]: s["yesterday"] for s in page["seen"] if s.get("fingerprint")})
    since = (day - timedelta(days=WINDOW)).isoformat()
    out = []
    for a in read_jsonl(folder / "memory" / "applied.jsonl"):
        if a["date"] < since or a["date"] > day.isoformat():
            continue
        n = hits.get(a["fingerprint"], 0)
        a["effect"] = f"Still {n} hit{'s' if n != 1 else ''} on {day.isoformat()}." if n else f"No hits on {day.isoformat()}."
        out.append(a)
    return out[::-1]


def standing(folder, day: date) -> dict[str, list[dict]]:
    """Memory lines by verdict: every pending and deferred one, already-done ones from the window."""
    since = (day - timedelta(days=WINDOW)).isoformat()
    out = {"pending": [], "deferred": [], "already-done": []}
    for m in read_jsonl(folder / "memory" / "problems.jsonl"):
        v = m.get("verdict")
        if v in ("pending", "deferred") or v == "already-done" and m["verdict_date"] >= since:
            out[v].append(m)
    return out


def main() -> None:
    args = base_parser(__doc__.splitlines()[0]).parse_args()
    day = analysed_day(args)
    folder = insights_dir(args.vault, args.periodic)
    page = json.loads((folder / f"{day.isoformat()}.json").read_text())

    errors = problems_errors(page)
    if errors:
        print("\n".join(errors), file=sys.stderr)
        print(f"{len(errors)} errors; nothing rendered", file=sys.stderr)
        sys.exit(1)

    order = {s: i for i, s in enumerate(STATUSES)}
    max_total = max([sum(p["series"]) for p in page["problems"]] + [1])
    problems = [decorate(p, max_total) for p in page["problems"]]
    page["sorted"] = sorted(problems, key=lambda p: (order[p["status"]], -p["total"]))
    page["dev"] = [p for p in page["sorted"] if p["group"] == "dev"]
    page["news"] = [p for p in page["sorted"] if p["group"] == "news"]
    page["tally"] = {s: sum(1 for p in problems if p["status"] == s) for s in STATUSES}
    n = len(problems)
    page["headline"] = (
        f"{n} problem{'s' if n != 1 else ''} in yesterday's sessions, each with a fix"
        if n
        else "Nothing in yesterday's sessions cleared the bar"
    )
    page["date_display"] = f"{day:%A} {day.day} {day:%B %Y}"
    page["window_start_short"] = page["window"][0][5:]
    page["window_end_short"] = page["window"][1][5:]
    page["note_path"] = f"{args.periodic}/06 Insights/{day.isoformat()}.md"
    note = folder / f"{day.isoformat()}.md"
    text = note.read_text() if note.exists() else ""
    page["note_text"] = text.split("---\n", 2)[2].strip() if text.startswith("---\n") else text.strip()
    page["applied"] = applied_lately(folder, day, page)
    page["standing"] = standing(folder, day)
    memory = {m["fingerprint"]: m for m in read_jsonl(folder / "memory" / "problems.jsonl")}
    for p in problems:
        m = memory.get(p["fingerprint"]) or {}
        p["verdict"] = m if m.get("verdict") else None
    page["generated_display"] = datetime.now(BERLIN).strftime("%Y-%m-%d %H:%M")

    env = jinja2.Environment(loader=jinja2.FileSystemLoader(TEMPLATE.parent), autoescape=True)
    out = folder / f"{day.isoformat()}.html"
    out.write_text(env.get_template(TEMPLATE.name).render(page=page))
    print(f"rendered {out}: {n} problems, {len(page['seen'])} seen, {len(page['applied'])} applied lately")


if __name__ == "__main__":
    main()
