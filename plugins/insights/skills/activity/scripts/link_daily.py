# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Link the activity page from the daily note of the day the job runs.

Ensures <periodic>/00 Daily/<today>.md holds
`Aktivität: [[<periodic>/07 Activity/<analysed day>.html]]` before the first
`## ` heading, beside the `Einsichten:` and `Zeitung:` lines, and directly
under it the first five `needs` headlines of the page, one `- ` line each. A
second run replaces that block where it stands. It writes nothing else: no
frontmatter, nothing under a heading. A missing note is created the way the
digest skill's link_daily.py creates one.
"""

import json
import sys
from datetime import date
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parents[2] / "digest" / "scripts"))
from common import analysed_day, base_parser, daily_note, today  # noqa: E402

ACTIVITY = "07 Activity"
LABEL = "Aktivität:"
MAX_LINES = 5


def with_block(text: str, link: str, block: list[str]) -> str:
    lines = text.split("\n")
    at = next((i for i, line in enumerate(lines) if link in line), None)
    if at is not None:
        end = at + 1
        while end < len(lines) and lines[end].startswith("- "):
            end += 1
        return "\n".join([*lines[:at], *block, *lines[end:]])
    at = next((i for i, line in enumerate(lines) if line.startswith("## ")), None)
    if at is None:
        return "\n".join([text.rstrip("\n"), "", *block, ""])
    return "\n".join([*lines[:at], *block, "", *lines[at:]])


def main() -> None:
    parser = base_parser(__doc__.splitlines()[0])
    parser.add_argument("--note-day", type=date.fromisoformat, default=None, help="daily note to link from, default today")
    args = parser.parse_args()
    day = analysed_day(args)
    note_day = args.note_day or today()
    note = args.vault / args.periodic / "00 Daily" / f"{note_day.isoformat()}.md"
    link = f"[[{args.periodic}/{ACTIVITY}/{day.isoformat()}.html]]"
    page = json.loads((args.vault / args.periodic / ACTIVITY / f"{day.isoformat()}.json").read_text())

    block = [f"{LABEL} {link}"]
    for need in page["needs"][:MAX_LINES]:
        links = need.get("links") or []
        block.append(f"- [{need['headline']}]({links[0]['url']})" if links else f"- {need['headline']}")

    created = not note.exists()
    if created:
        note.parent.mkdir(parents=True, exist_ok=True)
        note.write_text(daily_note(note_day, args.periodic))
    note.write_text(with_block(note.read_text(), link, block))
    print(f"{note}: {'created and ' if created else ''}linked {link} with {len(block) - 1} lines")


if __name__ == "__main__":
    main()
