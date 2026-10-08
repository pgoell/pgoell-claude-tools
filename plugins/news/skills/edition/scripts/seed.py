# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Seed the newspaper folder in a vault and print what the edition needs to know.

Copies config/topics.yaml, config/design.yaml, feedback.md and
memory/changelog.md from the plugin defaults when they are missing, creates an
empty memory/stories.jsonl, and never overwrites a file that exists: the
config in the vault is the user's. Prints one JSON object with the folder,
the files it created, the edition number and the previous edition's href.
"""

import json
import shutil

from common import DEFAULTS, base_parser, edition_dates, newspaper_dir, today

SEEDS = {
    "config/topics.yaml": "topics.yaml",
    "config/design.yaml": "design.yaml",
    "feedback.md": "feedback.md",
    "memory/changelog.md": "changelog.md",
}


def main() -> None:
    args = base_parser(__doc__.splitlines()[0]).parse_args()
    day = args.date or today()
    folder = newspaper_dir(args.vault, args.periodic)

    created = []
    for target, source in SEEDS.items():
        path = folder / target
        if not path.exists():
            path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(DEFAULTS / source, path)
            created.append(target)

    stories = folder / "memory" / "stories.jsonl"
    if not stories.exists():
        stories.touch()
        created.append("memory/stories.jsonl")

    earlier = [d for d in edition_dates(folder) if d < day]
    print(
        json.dumps(
            {
                "newspaper_dir": str(folder),
                "date": day.isoformat(),
                "created": created,
                "number": len(earlier) + 1,
                "previous": f"{earlier[-1].isoformat()}.html" if earlier else None,
                "feedback_note": f"{args.periodic}/05 Newspaper/feedback.md",
            },
            ensure_ascii=False,
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
