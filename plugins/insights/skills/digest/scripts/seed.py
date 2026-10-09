# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Seed the insights folder in a vault and say which review notes wait to be applied.

Copies feedback.md and memory/rules.md from the plugin defaults when they are
missing and creates empty memory/problems.jsonl and memory/applied.jsonl,
never overwriting a file that exists. Prints one JSON object: the folder, what
it created, and `to_apply`, the dates of review notes from the analysed day and the 7 before it
whose `## Proposed` was renamed `## Keep` and that hold no `## Done` yet.
"""

import json
import shutil
from datetime import timedelta

from common import DEFAULTS, analysed_day, base_parser, insights_dir

SEEDS = {"feedback.md": "feedback.md", "memory/rules.md": "rules.md"}


def main() -> None:
    args = base_parser(__doc__.splitlines()[0]).parse_args()
    day = analysed_day(args)
    folder = insights_dir(args.vault, args.periodic)

    created = []
    for target, source in SEEDS.items():
        path = folder / target
        if not path.exists():
            path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(DEFAULTS / source, path)
            created.append(target)
    for name in ("problems.jsonl", "applied.jsonl"):
        path = folder / "memory" / name
        if not path.exists():
            path.touch()
            created.append(f"memory/{name}")

    to_apply = []
    for back in range(8):
        note = folder / f"{(day - timedelta(days=back)).isoformat()}.md"
        if not note.exists():
            continue
        lines = note.read_text().splitlines()
        if "## Keep" in lines and "## Done" not in lines:
            to_apply.append(note.stem)

    print(json.dumps({"insights_dir": str(folder), "date": day.isoformat(), "created": created,
                      "to_apply": sorted(to_apply)}, indent=2))


if __name__ == "__main__":
    main()
