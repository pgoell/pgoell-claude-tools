# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Link the activity page from the daily note of the day the job runs.

Ensures <periodic>/00 Daily/<today>.md holds
`Aktivität: [[<periodic>/07 Activity/<analysed day>.html]]` before the first
`## ` heading, beside the `Einsichten:` and `Zeitung:` lines, and directly
under it the first five `needs` items that carry a link, one
`- [headline](https://...)` line each. A second run replaces the label line
and the lines of that exact form right under it, at most five, and leaves
every other line alone. It writes nothing else: no frontmatter, nothing at or
below the first heading. A missing note is created the way the
digest skill's link_daily.py creates one.
"""

import json
import re
import sys
from datetime import date
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parents[2] / "digest" / "scripts"))
from common import analysed_day, base_parser, daily_note, today  # noqa: E402

ACTIVITY = "07 Activity"
LABEL = "Aktivität:"
MAX_LINES = 5
OWN = re.compile(r"^- \[[^\]]*\]\(https://\S+\)$")


def with_block(text: str, block: list[str]) -> str:
    lines = text.split("\n")
    head = next((i for i, line in enumerate(lines) if line.startswith("## ")), None)
    at = next((i for i, line in enumerate(lines[:head]) if line.startswith(LABEL)), None)
    if at is not None:
        end = at + 1
        while end < min(len(lines), at + 1 + MAX_LINES) and OWN.match(lines[end]):
            end += 1
        return "\n".join([*lines[:at], *block, *lines[end:]])
    if head is None:
        return "\n".join([text.rstrip("\n"), "", *block, ""])
    return "\n".join([*lines[:head], *block, "", *lines[head:]])


def main() -> None:
    parser = base_parser(__doc__.splitlines()[0])
    parser.add_argument("--note-day", type=date.fromisoformat, default=None, help="daily note to link from, default today")
    args = parser.parse_args()
    day = analysed_day(args)
    note_day = args.note_day or today()
    note = args.vault / args.periodic / "00 Daily" / f"{note_day.isoformat()}.md"
    link = f"[[{args.periodic}/{ACTIVITY}/{day.isoformat()}.html]]"
    page = json.loads((args.vault / args.periodic / ACTIVITY / f"{day.isoformat()}.json").read_text())

    linked = [n for n in page["needs"] if n.get("links")][:MAX_LINES]
    block = [f"{LABEL} {link}", *(f"- [{n['headline']}]({n['links'][0]['url']})" for n in linked)]

    created = not note.exists()
    if created:
        note.parent.mkdir(parents=True, exist_ok=True)
        note.write_text(daily_note(note_day, args.periodic))
    note.write_text(with_block(note.read_text(), block))
    print(f"{note}: {'created and ' if created else ''}linked {link} with {len(block) - 1} lines")


if __name__ == "__main__":
    main()
