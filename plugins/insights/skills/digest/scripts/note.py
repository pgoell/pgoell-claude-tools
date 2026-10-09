# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Write the day's review note, <insights>/<date>.md, from <date>.json.

One line per problem under `## Proposed`: `- #MM-DD-NN title -> destination`.
No checkboxes, because kasten counts every checkbox line as a todo. A note
already reviewed (it holds `## Keep` or `## Done`) is never overwritten; an
untouched one is rewritten, so a rerun for the same day stays in step with
the page. Frontmatter carries `type` only; kasten adds id and dates itself.
"""

import json

from common import INSIGHTS, analysed_day, base_parser, insights_dir

HOWTO = (
    "Keep a line to accept its fix, edit it to change the fix, delete it to reject it, "
    "or start it with `no:` to reject it with a reason. A bullet indented under a line is a note "
    "for that fix (an indented `no:` rejects it). Then rename `## Proposed` to `## Keep`; "
    "the next morning's run acts on it. Running `/insights:apply` yourself acts on it renamed or not."
)
EMPTY = "nothing to decide today"


def proposal(p: dict) -> str:
    return f"- #{p['id']} {p['title']} -> {p['destination']}"


def main() -> None:
    args = base_parser(__doc__.splitlines()[0]).parse_args()
    day = analysed_day(args).isoformat()
    folder = insights_dir(args.vault, args.periodic)
    page = json.loads((folder / f"{day}.json").read_text())
    note = folder / f"{day}.md"

    if note.exists() and any(line in ("## Keep", "## Done") for line in note.read_text().splitlines()):
        print(f"{note}: already reviewed, left alone")
        return
    lines = [proposal(p) for p in page["problems"]] or [f"- {EMPTY}"]
    note.write_text(
        "---\ntype: Note\n---\n\n"
        f"# Insights {day}\n\n"
        f"Page: [[{args.periodic}/{INSIGHTS}/{day}.html]]\n\n"
        f"{HOWTO}\n\n"
        "## Proposed\n\n" + "\n".join(lines) + "\n"
    )
    print(f"wrote {note}: {len(page['problems'])} proposals")


if __name__ == "__main__":
    main()
