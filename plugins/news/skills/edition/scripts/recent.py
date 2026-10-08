# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Print what recent editions already ran, compactly, for deduplication.

One line per item, newest first: date, id, section, headline, source, url,
then entities and key facts when the story has them. Briefs show `brief`
instead of an id.
"""

import json
from datetime import timedelta

from common import base_parser, newspaper_dir, today


def main() -> None:
    parser = base_parser(__doc__.splitlines()[0])
    parser.add_argument("--days", type=int, default=30, help="how far back to look (default 30)")
    parser.add_argument("--section", help="only this section id")
    args = parser.parse_args()
    day = args.date or today()
    since = (day - timedelta(days=args.days)).isoformat()

    memory = newspaper_dir(args.vault, args.periodic) / "memory" / "stories.jsonl"
    lines = memory.read_text().splitlines() if memory.exists() else []
    items = [json.loads(line) for line in lines if line.strip()]
    items = [i for i in items if since <= i.get("date", "") < day.isoformat()]
    if args.section:
        items = [i for i in items if i.get("section") == args.section]

    for i in sorted(items, key=lambda i: i.get("date", ""), reverse=True):
        row = [i.get("date"), i.get("id") or "brief", i.get("section"), i.get("headline"), i.get("source"), i.get("url")]
        print(" | ".join(str(c) for c in row))
        if i.get("entities"):
            print(f"    entities: {', '.join(i['entities'])}")
        if i.get("key_facts"):
            print(f"    facts: {'; '.join(i['key_facts'])}")
    if not items:
        print(f"nothing in memory since {since}")


if __name__ == "__main__":
    main()
