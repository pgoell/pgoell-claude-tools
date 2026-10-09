# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Keep memory/problems.jsonl, one line per problem fingerprint, in step with the pages.

Without --verdicts: folds <date>.json's problems into memory. A new
fingerprint gets a line; a known one gets its latest title, status, counts and
id, while its verdict stays. A rerun for the same date changes nothing twice.

With --verdicts FILE: records review outcomes from a JSON list of
`{"fingerprint", "id", "verdict", "ref", "reason"}`, where verdict is
`applied`, `rejected` or `watch`. Each stores the problem's 14-day hits at
that moment, which is what "comes back only when hits triple" compares
against. An `applied` verdict also appends to memory/applied.jsonl, which the
page footer reads.
"""

import json
from pathlib import Path

from common import analysed_day, base_parser, insights_dir, read_jsonl, today, write_jsonl

VERDICTS = ("applied", "rejected", "watch")


def fold(memory: dict[str, dict], page: dict) -> None:
    day = page["date"]
    for p in page["problems"]:
        m = memory.setdefault(p["fingerprint"], {"fingerprint": p["fingerprint"], "first_seen": day, "ids": [],
                                                   "verdict": None, "verdict_date": None, "hits_at_verdict": None})
        m.update({k: p[k] for k in ("title", "kind", "group", "status", "destination", "action", "yesterday")})
        m["total"] = sum(p["series"])
        m["days_hit"] = sum(1 for v in p["series"] if v)
        m["last_proposed"] = day
        if p["id"] not in m["ids"]:
            m["ids"] = (m["ids"] + [p["id"]])[-5:]


def record(memory: dict[str, dict], folder: Path, verdicts: list[dict]) -> int:
    applied = read_jsonl(folder / "memory" / "applied.jsonl")
    stamp = today().isoformat()
    for v in verdicts:
        if v["verdict"] not in VERDICTS:
            raise SystemExit(f"verdict must be one of {VERDICTS}: {v}")
        m = memory.get(v["fingerprint"])
        if m is None:
            raise SystemExit(f"unknown fingerprint {v['fingerprint']!r}; run remember.py on its page first")
        m.update({"verdict": v["verdict"], "verdict_date": stamp, "hits_at_verdict": m.get("total"),
                  "reason": v.get("reason")})
        if v["verdict"] == "applied":
            applied.append({"date": stamp, "id": v["id"], "fingerprint": v["fingerprint"], "title": m["title"],
                            "action": m["action"], "ref": v.get("ref", "")})
    write_jsonl(folder / "memory" / "applied.jsonl", applied)
    return len(verdicts)


def main() -> None:
    parser = base_parser(__doc__.splitlines()[0])
    parser.add_argument("--verdicts", type=Path, help="JSON list of review outcomes to record")
    args = parser.parse_args()
    folder = insights_dir(args.vault, args.periodic)
    path = folder / "memory" / "problems.jsonl"
    memory = {m["fingerprint"]: m for m in read_jsonl(path)}

    if args.verdicts:
        n = record(memory, folder, json.loads(args.verdicts.read_text()))
        print(f"recorded {n} verdicts in {path}")
    else:
        day = analysed_day(args).isoformat()
        page = json.loads((folder / f"{day}.json").read_text())
        fold(memory, page)
        print(f"remembered {len(page['problems'])} problems for {day} in {path}")
    write_jsonl(path, list(memory.values()))


if __name__ == "__main__":
    main()
