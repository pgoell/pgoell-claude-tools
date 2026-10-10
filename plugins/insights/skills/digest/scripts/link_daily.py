# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Link the insights page from the daily note of the day the job runs, once.

Ensures <periodic>/00 Daily/<today>.md holds
`Einsichten: [[<periodic>/06 Insights/<analysed day>.html]]` before the first
`## ` heading, the same spot the newspaper puts its `Zeitung:` line, so the two
sit together whichever runs first. The note for today, not for the analysed
day: the page is read the morning after. A missing note is created the way
kasten's `<leader>gd` creates one, as the news plugin's link_daily.py does.
"""

import argparse
from datetime import date

from common import INSIGHTS, analysed_day, base_parser, daily_note, today

LABEL = "Einsichten:"


def with_link(text: str, link: str) -> str:
    lines = text.split("\n")
    at = next((i for i, line in enumerate(lines) if line.startswith("## ")), None)
    if at is None:
        return f"{text.rstrip(chr(10))}\n\n{LABEL} {link}\n"
    return "\n".join([*lines[:at], f"{LABEL} {link}", "", *lines[at:]])


def main() -> None:
    parser = base_parser(__doc__.splitlines()[0])
    parser.add_argument("--note-day", type=date.fromisoformat, default=None, help="daily note to link from, default today")
    args: argparse.Namespace = parser.parse_args()
    day = analysed_day(args)
    note_day = args.note_day or today()
    note = args.vault / args.periodic / "00 Daily" / f"{note_day.isoformat()}.md"
    link = f"[[{args.periodic}/{INSIGHTS}/{day.isoformat()}.html]]"

    created = not note.exists()
    if created:
        note.parent.mkdir(parents=True, exist_ok=True)
        note.write_text(daily_note(note_day, args.periodic))

    text = note.read_text()
    if link in text:
        print(f"{note}: already linked")
        return
    note.write_text(with_link(text, link))
    print(f"{note}: {'created and ' if created else ''}linked {link}")


if __name__ == "__main__":
    main()
