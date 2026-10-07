# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Link the edition from the day's kasten daily note, once.

Ensures <periodic>/00 Daily/<date>.md holds the line
`Zeitung: [[<periodic>/05 Newspaper/<date>.html]]`, placed after the title and
navigation, before the first `## ` heading. A note that already holds the
wikilink is left alone. A missing note is created the way kasten's
`<leader>gd` creates one (kasten_backend/periodic.py `daily_note`), so kasten
adds its own id and dates on the first save, as it does for its own notes.
"""

from datetime import date, timedelta

from common import NEWSPAPER, base_parser, today

LABEL = "Zeitung:"
WEEKDAYS = ("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")


def daily_note(day: date, periodic: str) -> str:
    """Mirror of kasten's `daily_note`; keep the two in step."""
    year, week, _ = day.isocalendar()
    before = f"{periodic}/00 Daily/{(day - timedelta(days=1)).isoformat()}"
    after = f"{periodic}/00 Daily/{(day + timedelta(days=1)).isoformat()}"
    nav = f"[[{before}]] | [[{periodic}/01 Weekly/{year}-W{week:02d}]] | [[{after}]]"
    return f"---\ntype: Periodic Note\n---\n\n# {day.isoformat()} {WEEKDAYS[day.weekday()]}\n\n{nav}\n\n## TODOs\n"


def with_link(text: str, link: str) -> str:
    lines = text.split("\n")
    at = next((i for i, line in enumerate(lines) if line.startswith("## ")), None)
    if at is None:
        return f"{text.rstrip(chr(10))}\n\n{LABEL} {link}\n"
    return "\n".join([*lines[:at], f"{LABEL} {link}", "", *lines[at:]])


def main() -> None:
    args = base_parser(__doc__.splitlines()[0]).parse_args()
    day = args.date or today()
    note = args.vault / args.periodic / "00 Daily" / f"{day.isoformat()}.md"
    link = f"[[{args.periodic}/{NEWSPAPER}/{day.isoformat()}.html]]"

    created = not note.exists()
    if created:
        note.parent.mkdir(parents=True, exist_ok=True)
        note.write_text(daily_note(day, args.periodic))

    text = note.read_text()
    if link in text:
        print(f"{note}: already linked")
        return
    note.write_text(with_link(text, link))
    print(f"{note}: {'created and ' if created else ''}linked {link}")


if __name__ == "__main__":
    main()
