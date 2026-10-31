# /// script
# requires-python = ">=3.11"
# dependencies = ["pyyaml>=6"]
# ///
"""Check an edition JSON file against the contract in references/edition-contract.md.

Exits 1 and lists every error when the edition breaks the contract; prints
warnings (summary length for the story's importance) without failing. With --memory, also fails on a
follow-up that links a story memory does not hold, and on a story whose URL an
earlier edition already ran without marking it as a follow-up.

It also fails on a story whose `published` day (Europe/Berlin) lies before the
edition date minus its section's `freshness_days`, or after the edition date.
The window comes from topics.yaml (`<edition folder>/config/topics.yaml`, or
--config): the section's `freshness_days`, else the top-level one, else 2. The
lead uses its `section` field. Without topics.yaml the check is skipped with a
warning.
"""

import argparse
import json
import re
import sys
from datetime import date, datetime, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

import yaml

DATE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
STORY_ID = re.compile(r"^\d{4}-\d{2}-\d{2}-[a-z0-9]+(?:-[a-z0-9]+)*-\d{2}$")
EDITION_HREF = re.compile(r"^\d{4}-\d{2}-\d{2}\.html$")
FOLLOWUP_HREF = re.compile(r"^(\d{4}-\d{2}-\d{2})\.html#(.+)$")
SCORE = re.compile(r"^\d+-\d+$")

SUMMARY_WORDS = {3: (90, 150), 2: (50, 90), 1: (25, 45)}
"""Summary length by importance; outside it is a warning, because a short story is no error."""

errors: list[str] = []
warnings: list[str] = []


def check(ok: bool, where: str, message: str) -> bool:
    if not ok:
        errors.append(f"{where}: {message}")
    return ok


def is_str(value: object) -> bool:
    return isinstance(value, str) and value.strip() != ""


def is_int(value: object) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


def story(s: object, where: str, day: str) -> None:
    if not check(isinstance(s, dict), where, "must be an object"):
        return
    sid = s.get("id")
    if check(is_str(sid) and STORY_ID.match(sid), where, f"id {sid!r} must look like {day}-<slug>-NN"):
        check(sid.startswith(day), where, f"id {sid!r} must start with the edition date {day}")
    for key in ("headline", "summary", "lang", "url", "source", "published"):
        check(is_str(s.get(key)), where, f"{key} must be a non-empty string")
    check(s.get("dek") is None or is_str(s.get("dek")), where, "dek must be a string or null")
    check(str(s.get("url", "")).startswith(("https://", "http://")), where, "url must be absolute http(s)")
    try:
        datetime.fromisoformat(str(s.get("published")))
    except ValueError:
        errors.append(f"{where}: published {s.get('published')!r} is not ISO 8601")
    check(s.get("importance") in (1, 2, 3), where, "importance must be 1, 2 or 3")
    check(isinstance(s.get("tags"), list) and all(is_str(t) for t in s["tags"]), where, "tags must be a list of strings")

    image = s.get("image")
    if image is not None and check(isinstance(image, dict), where, "image must be an object or null"):
        check(str(image.get("src", "")).startswith("https://"), where, "image.src must be https")
        check(isinstance(image.get("alt"), str), where, "image.alt must be a string")
        check(isinstance(image.get("credit"), str), where, "image.credit must be a string")

    followups = s.get("followups")
    if check(isinstance(followups, list), where, "followups must be a list"):
        for i, f in enumerate(followups):
            fw = f"{where}.followups[{i}]"
            if check(isinstance(f, dict), fw, "must be an object"):
                check(is_str(f.get("date")) and DATE.match(f["date"]), fw, "date must be YYYY-MM-DD")
                check(is_str(f.get("headline")), fw, "headline must be a non-empty string")
                check(is_str(f.get("href")) and FOLLOWUP_HREF.match(f["href"]), fw, "href must be YYYY-MM-DD.html#<id>")
        check(not followups or is_str(s.get("update_note")), where, "a follow-up needs an update_note saying what is new")
    check(s.get("update_note") is None or is_str(s.get("update_note")), where, "update_note must be a string or null")

    for key in ("entities", "key_facts"):
        value = s.get(key, [])
        check(isinstance(value, list) and all(is_str(v) for v in value), where, f"{key} must be a list of strings")

    bracket = s.get("bracket")
    if bracket is not None and check(isinstance(bracket, dict), where, "bracket must be an object or null"):
        tags = bracket.get("tags")
        check(tags is None or (isinstance(tags, dict) and all(is_str(k) and is_str(v) for k, v in tags.items())), where, "bracket.tags must map team names to tags")
        rounds = bracket.get("rounds")
        if check(isinstance(rounds, list) and 1 <= len(rounds) <= 8, where, "bracket.rounds must be a list of 1 to 8"):
            for i, r in enumerate(rounds):
                rw = f"{where}.bracket.rounds[{i}]"
                if not check(isinstance(r, dict) and is_str(r.get("name")), rw, "must be an object with a name"):
                    continue
                matches = r.get("matches")
                if check(isinstance(matches, list) and matches, rw, "matches must be a non-empty list"):
                    for j, m in enumerate(matches):
                        mw = f"{rw}.matches[{j}]"
                        if check(isinstance(m, dict), mw, "must be an object"):
                            check(is_str(m.get("a")) and is_str(m.get("b")), mw, "a and b must be non-empty strings")
                            check(m.get("winner") in ("a", "b", None), mw, 'winner must be "a", "b" or null')
                            check(m.get("score") is None or (is_str(m["score"]) and SCORE.match(m["score"])), mw, 'score must be like "3-2" or null')
                            check(m.get("when") is None or is_str(m.get("when")), mw, "when must be a string or null")
                            check(m.get("record") is None or (is_str(m["record"]) and SCORE.match(m["record"])), mw, 'record must be like "2-1" or null')

    words = len(str(s.get("summary", "")).split())
    low, high = SUMMARY_WORDS.get(s.get("importance"), (25, 150))
    if not low <= words <= high:
        warnings.append(f"{where}: summary has {words} words (importance {s.get('importance')}: {low}-{high})")


def edition(e: object) -> list[dict]:
    """Validate the edition and return its stories, lead first."""
    if not check(isinstance(e, dict), "edition", "must be an object"):
        return []
    for key in ("title", "tagline", "date_display", "feedback_hint"):
        check(is_str(e.get(key)), "edition", f"{key} must be a non-empty string")
    day = e.get("date")
    if not check(is_str(day) and DATE.match(day), "edition", "date must be YYYY-MM-DD"):
        day = "0000-00-00"
    check(is_int(e.get("number")) and e["number"] >= 1, "edition", "number must be a positive integer")
    check(e.get("previous") is None or (is_str(e["previous"]) and EDITION_HREF.match(e["previous"])), "edition", "previous must be null or YYYY-MM-DD.html")

    weather = e.get("weather")
    if weather is not None and check(isinstance(weather, dict), "edition.weather", "must be an object or null"):
        check(is_str(weather.get("place")) and is_str(weather.get("summary")), "edition.weather", "place and summary must be strings")
        check(is_int(weather.get("high_c")) and is_int(weather.get("low_c")), "edition.weather", "high_c and low_c must be integers")

    feedback = e.get("recent_feedback", [])
    check(isinstance(feedback, list) and all(is_str(f) for f in feedback), "edition", "recent_feedback must be a list of strings")

    stories = []
    if "lead" in e:
        story(e["lead"], "lead", day)
        stories.append(e["lead"])
    else:
        errors.append("edition: lead is missing")

    sections = e.get("sections")
    section_ids = set()
    if check(isinstance(sections, list) and 4 <= len(sections) <= 20, "edition", "sections must be a list of 4 to 20"):
        for i, sec in enumerate(sections):
            where = f"sections[{i}]"
            if not check(isinstance(sec, dict), where, "must be an object"):
                continue
            check(is_str(sec.get("id")) and is_str(sec.get("name")), where, "id and name must be strings")
            check(sec.get("kicker") is None or is_str(sec.get("kicker")), where, "kicker must be a string or null")
            check(isinstance(sec.get("local", False), bool), where, "local must be true or false")
            section_ids.add(sec.get("id"))
            tables = sec.get("tables", [])
            if check(isinstance(tables, list), where, "tables must be a list"):
                for k, t in enumerate(tables):
                    tw = f"{where}.tables[{k}]"
                    if not check(isinstance(t, dict) and is_str(t.get("name")) and is_str(t.get("url")), tw, "must be an object with a name and a url"):
                        continue
                    check(t.get("matchday") is None or is_str(t.get("matchday")), tw, "matchday must be a string or null")
                    rows = t.get("rows")
                    if check(isinstance(rows, list) and rows, tw, "rows must be a non-empty list"):
                        for r, row in enumerate(rows):
                            rw = f"{tw}.rows[{r}]"
                            if check(isinstance(row, dict) and is_str(row.get("team")), rw, "must be an object with a team"):
                                ints = ("rank", "played", "won", "drawn", "lost", "diff", "points")
                                check(all(is_int(row.get(key)) for key in ints), rw, f"{', '.join(ints)} must be integers")
                                check(row.get("trend") in ("up", "down", None), rw, 'trend must be "up", "down" or null')
            if check(isinstance(sec.get("stories"), list), where, "stories must be a list"):
                for j, s in enumerate(sec["stories"]):
                    story(s, f"{where}.stories[{j}]", day)
                    stories.append(s)

    ids = [s.get("id") for s in stories if isinstance(s, dict)]
    dupes = sorted({i for i in ids if ids.count(i) > 1})
    check(not dupes, "edition", f"duplicate story ids {dupes}")

    urls = {s.get("url") for s in stories if isinstance(s, dict)}
    briefs = e.get("briefs")
    if check(isinstance(briefs, list), "edition", "briefs must be a list"):
        for i, b in enumerate(briefs):
            where = f"briefs[{i}]"
            if check(isinstance(b, dict), where, "must be an object"):
                for key in ("headline", "url", "source", "section"):
                    check(is_str(b.get(key)), where, f"{key} must be a non-empty string")
                check(b.get("section") in section_ids, where, f"section {b.get('section')!r} is not a section id")
                check(b.get("url") not in urls, where, "url already runs as a story")
    return [s for s in stories if isinstance(s, dict)]


def against_memory(stories: list[dict], day: str, memory: Path) -> None:
    earlier = [json.loads(line) for line in memory.read_text().splitlines() if line.strip()]
    earlier = [m for m in earlier if m.get("date", "") < day]
    known_ids = {m.get("id") for m in earlier}
    known_urls = {m.get("url"): m for m in earlier}
    for s in stories:
        for f in s.get("followups", []):
            match = FOLLOWUP_HREF.match(str(f.get("href", "")))
            if match:
                check(match.group(2) in known_ids, s["id"], f"follow-up {f['href']} names no story in memory")
        seen = known_urls.get(s.get("url"))
        if seen and not s.get("followups"):
            errors.append(f"{s['id']}: url already ran on {seen.get('date')} as {seen.get('id')}; drop it or make it a follow-up")


def berlin_day(published: str) -> date | None:
    """The Berlin calendar day of `published`; a naive or date-only value counts as Berlin."""
    try:
        value = datetime.fromisoformat(published)
    except ValueError:
        return None
    if value.tzinfo is not None:
        value = value.astimezone(ZoneInfo("Europe/Berlin"))
    return value.date()


def freshness(e: dict, topics: dict) -> None:
    try:
        day = date.fromisoformat(str(e.get("date")))
    except ValueError:
        return
    default = topics.get("freshness_days", 2)
    windows = {s.get("id"): s.get("freshness_days", default) for s in topics.get("sections") or [] if isinstance(s, dict)}
    lead = e.get("lead") if isinstance(e.get("lead"), dict) else {}
    pairs = [(lead, lead.get("section"))]
    for sec in e.get("sections") if isinstance(e.get("sections"), list) else []:
        if isinstance(sec, dict) and isinstance(sec.get("stories"), list):
            pairs += [(s, sec.get("id")) for s in sec["stories"] if isinstance(s, dict)]
    for s, section in pairs:
        published = berlin_day(str(s.get("published")))
        if published is None:
            continue
        days = windows.get(section, default)
        start = day - timedelta(days=days)
        if published < start:
            errors.append(
                f"{s.get('id')}: published {published} is older than section {section or '(none)'} "
                f"(freshness_days {days}) allows; the window starts {start}. Drop it or fix the date"
            )
        elif published > day:
            errors.append(f"{s.get('id')}: published {published} is after the edition date {day}; the date is guessed or wrong")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("edition", type=Path)
    parser.add_argument("--memory", type=Path, help="memory/stories.jsonl to check follow-ups and repeats against")
    parser.add_argument("--config", type=Path, help="topics.yaml with freshness_days (default: config/topics.yaml beside the edition)")
    args = parser.parse_args()

    data = json.loads(args.edition.read_text())
    stories = edition(data)
    if args.memory and args.memory.exists():
        against_memory(stories, str(data.get("date")), args.memory)
    config = args.config or args.edition.parent / "config" / "topics.yaml"
    if not config.exists():
        warnings.append(f"no topics.yaml at {config}; published dates not checked against freshness_days")
    elif isinstance(data, dict):
        freshness(data, yaml.safe_load(config.read_text()) or {})

    for w in warnings:
        print(f"warning: {w}")
    for e in errors:
        print(f"error: {e}")
    print(f"{len(stories)} stories, {len(errors)} errors, {len(warnings)} warnings")
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
