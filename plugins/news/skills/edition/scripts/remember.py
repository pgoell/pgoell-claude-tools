# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Record an edition's stories in memory/stories.jsonl, the record of what already ran.

One line per story (lead, section stories, then briefs). A rerun for the same
date replaces that date's lines instead of adding a second copy.
"""

import json

from common import base_parser, newspaper_dir, today


def short(summary: str, limit: int = 240) -> str:
    first = summary.split("\n\n")[0].strip()
    return first if len(first) <= limit else first[: limit - 1].rsplit(" ", 1)[0] + "…"


def main() -> None:
    args = base_parser(__doc__.splitlines()[0]).parse_args()
    day = (args.date or today()).isoformat()
    folder = newspaper_dir(args.vault, args.periodic)
    edition = json.loads((folder / f"{day}.json").read_text())

    records = []
    stories = [(edition["lead"], None)] + [(s, sec["id"]) for sec in edition["sections"] for s in sec["stories"]]
    for s, section in stories:
        records.append(
            {
                "id": s["id"],
                "date": day,
                "section": section or s.get("section") or "lead",
                "headline": s["headline"],
                "url": s["url"],
                "source": s["source"],
                "entities": s.get("entities", []),
                "summary_short": short(s["summary"]),
                "key_facts": s.get("key_facts", []),
                "followup_of": [f["href"] for f in s.get("followups", [])],
            }
        )
    for b in edition.get("briefs", []):
        records.append(
            {
                "id": None,
                "date": day,
                "section": b["section"],
                "headline": b["headline"],
                "url": b["url"],
                "source": b["source"],
                "brief": True,
            }
        )

    memory = folder / "memory" / "stories.jsonl"
    kept = [line for line in memory.read_text().splitlines() if line.strip() and json.loads(line).get("date") != day] if memory.exists() else []
    memory.parent.mkdir(parents=True, exist_ok=True)
    memory.write_text("".join(f"{line}\n" for line in kept + [json.dumps(r, ensure_ascii=False) for r in records]))
    print(f"remembered {len(records)} items for {day} in {memory}")


if __name__ == "__main__":
    main()
