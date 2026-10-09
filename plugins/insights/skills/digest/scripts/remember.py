# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Keep memory/problems.jsonl, one line per problem fingerprint, in step with the pages.

Without --verdicts: folds <date>.json's problems into memory. A new
fingerprint gets a line; a known one gets its latest title, status, counts and
id, while its verdict stays. A rerun for the same date changes nothing twice.

With --verdicts FILE: records review outcomes from a JSON list of
`{"fingerprint", "id", "verdict", "ref", "reason", "until"}`. The verdicts:

- `applied`: the fix went out (`ref`: "todo", "feedback", or a merged PR).
  Also appends to memory/applied.jsonl, which the page footer reads.
- `pending`: a PR is open (`ref`: its URL). Not applied until it merges.
- `already-done`: nothing to change, the fix was in place already.
- `deferred`: not now (`reason`, and `until`, the condition that ends it).
- `rejected`, `watch`.

Each stores the problem's 14-day hits at that moment, which is what "comes
back only when hits triple" compares against. A verdict the fingerprint
already holds for the same id is skipped, so the first verdict date stays.

With --check-prs: asks `gh pr view` about every `pending` PR. A merged one
becomes `applied` as of its merge date; a closed one becomes `rejected`.
Prints what changed.
"""

import json
import subprocess
from datetime import datetime
from pathlib import Path

from common import BERLIN, analysed_day, base_parser, insights_dir, read_jsonl, today, write_jsonl

VERDICTS = ("applied", "pending", "already-done", "deferred", "rejected", "watch")


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


def set_verdict(m: dict, applied: list[dict], v: dict, stamp: str) -> None:
    m.update({"verdict": v["verdict"], "verdict_id": v["id"], "verdict_date": stamp, "hits_at_verdict": m.get("total"),
              "reason": v.get("reason"), "ref": v.get("ref"), "until": v.get("until")})
    if v["verdict"] == "applied":
        applied.append({"date": stamp, "id": v["id"], "fingerprint": m["fingerprint"], "title": m["title"],
                        "action": m["action"], "ref": v.get("ref", "")})


def record(memory: dict[str, dict], folder: Path, verdicts: list[dict]) -> int:
    applied = read_jsonl(folder / "memory" / "applied.jsonl")
    stamp = today().isoformat()
    n = 0
    for v in verdicts:
        if v["verdict"] not in VERDICTS:
            raise SystemExit(f"verdict must be one of {VERDICTS}: {v}")
        m = memory.get(v["fingerprint"])
        if m is None:
            raise SystemExit(f"unknown fingerprint {v['fingerprint']!r}; run remember.py on its page first")
        # Memory written before verdict_id existed counts as the same id.
        if m.get("verdict") == v["verdict"] and m.get("verdict_id", v["id"]) == v["id"]:
            continue
        set_verdict(m, applied, v, stamp)
        n += 1
    write_jsonl(folder / "memory" / "applied.jsonl", applied)
    return n


def check_prs(memory: dict[str, dict], folder: Path) -> list[dict]:
    applied = read_jsonl(folder / "memory" / "applied.jsonl")
    changed = []
    for m in memory.values():
        if m.get("verdict") != "pending":
            continue
        try:
            out = subprocess.run(["gh", "pr", "view", m["ref"], "--json", "state,mergedAt,closedAt"],
                                 capture_output=True, text=True, check=True).stdout
        except subprocess.CalledProcessError as e:
            changed.append({"fingerprint": m["fingerprint"], "ref": m["ref"], "error": e.stderr.strip()})
            continue
        pr = json.loads(out)
        if pr["state"] == "OPEN":
            continue
        when = datetime.fromisoformat(pr["mergedAt"] or pr["closedAt"]).astimezone(BERLIN).date().isoformat()
        if pr["state"] == "MERGED":
            set_verdict(m, applied, {"verdict": "applied", "id": m["verdict_id"], "ref": m["ref"]}, when)
        else:
            set_verdict(m, applied, {"verdict": "rejected", "id": m["verdict_id"], "ref": m["ref"],
                                     "reason": "PR closed without merging"}, when)
        changed.append({"fingerprint": m["fingerprint"], "ref": m["ref"], "state": pr["state"], "date": when})
    write_jsonl(folder / "memory" / "applied.jsonl", applied)
    return changed


def main() -> None:
    parser = base_parser(__doc__.splitlines()[0])
    parser.add_argument("--verdicts", type=Path, help="JSON list of review outcomes to record")
    parser.add_argument("--check-prs", action="store_true", help="settle pending verdicts whose PR merged or closed")
    args = parser.parse_args()
    folder = insights_dir(args.vault, args.periodic)
    path = folder / "memory" / "problems.jsonl"
    memory = {m["fingerprint"]: m for m in read_jsonl(path)}

    if args.check_prs:
        print(json.dumps({"prs": check_prs(memory, folder)}, indent=1))
    elif args.verdicts:
        verdicts = json.loads(args.verdicts.read_text())
        n = record(memory, folder, verdicts)
        print(f"recorded {n} verdicts in {path}, {len(verdicts) - n} already held")
    else:
        day = analysed_day(args).isoformat()
        page = json.loads((folder / f"{day}.json").read_text())
        fold(memory, page)
        print(f"remembered {len(page['problems'])} problems for {day} in {path}")
    write_jsonl(path, list(memory.values()))


if __name__ == "__main__":
    main()
