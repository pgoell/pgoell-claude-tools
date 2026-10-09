# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Read a reviewed note against its page and print what is left to apply, as JSON.

Compares <insights>/<date>.md with the problems in <date>.json and with memory:
- `state`: `keep` (the reader renamed `## Proposed`), `proposed` (not
  renamed), or `done` (nothing left to apply).
- `handled`: problems that already carry a verdict for this note, from an
  earlier run. They are left out of everything below, so a partly applied
  note picks up where it stopped.
- `kept`: lines that carry a problem id, with the problem attached, `edited:
  true` when the reader changed the words after the id, and `notes`, the
  reader's sub-bullets under the line.
- `no`: lines starting `no:`, or kept lines with an indented `no:` under
  them, with the id, the reason and the other `notes`.
- `dropped`: problems whose line the reader deleted, the rejections.
- `unmatched`: lines with a `#<id>` that names no problem on the page. When
  any exist, `dropped` stays empty and its problems go to `unsure`, because
  a mistyped id would otherwise read as a deleted line.
- `other`: lines with no id, free text the reader added, minus those already
  in feedback.md.

An id matches when it is a problem id on the page or the unique tail of one
(`#08-01` for `10-08-01`).
"""

import json
import re
from pathlib import Path

from common import analysed_day, base_parser, insights_dir, read_jsonl
from note import EMPTY, proposal

TOKEN = re.compile(r"#(\d+(?:-\d+)+)\b")
NO = re.compile(r"^(?:-\s*)?no:\s*(.*)$", re.I)
BULLET = re.compile(r"^(\s*)(?:[-*+]\s+)?(.*)$")


def matcher(ids: list[str]):
    """Map a `#token` to a problem id: an exact id, or the unique tail of one."""

    def find(token: str) -> str | None:
        if token in ids:
            return token
        tails = [i for i in ids if i.endswith("-" + token)]
        return tails[0] if len(tails) == 1 else None

    return find


def handled_ids(folder: Path, day: str, problems: dict[str, dict]) -> dict[str, str]:
    """Problem ids that already carry a verdict given on or after the note's day."""
    memory = {m["fingerprint"]: m for m in read_jsonl(folder / "memory" / "problems.jsonl")}
    done = {}
    for pid, p in problems.items():
        m = memory.get(p["fingerprint"]) or {}
        if not m.get("verdict") or (m.get("verdict_date") or "") < day:
            continue
        # Memory written before verdict_id existed only knows the fingerprint's ids.
        if m.get("verdict_id", pid) == pid and pid in m.get("ids", [pid]):
            done[pid] = m["verdict"]
    for a in read_jsonl(folder / "memory" / "applied.jsonl"):
        if a.get("id") in problems and a["date"] >= day:
            done.setdefault(a["id"], "applied")
    return done


def section(lines: list[str]) -> tuple[str, list[str]]:
    """The decision section and its heading: `## Keep`, else `## Proposed`, up to the next `## `."""
    for state, head in (("keep", "## Keep"), ("proposed", "## Proposed")):
        if head in lines:
            rest = lines[lines.index(head) + 1 :]
            end = next((i for i, line in enumerate(rest) if line.startswith("## ")), len(rest))
            return state, rest[:end]
    return "proposed", []


def read_review(folder: Path, day: str) -> dict:
    problems = {p["id"]: p for p in json.loads((folder / f"{day}.json").read_text())["problems"]}
    state, body = section((folder / f"{day}.md").read_text().splitlines())
    find = matcher(list(problems))
    handled = handled_ids(folder, day, problems)

    # Group each top-level line with the indented lines under it.
    items: list[dict] = []
    for raw in body:
        if not raw.strip():
            continue
        indent, text = BULLET.match(raw).groups()
        if indent and items:
            items[-1]["notes"].append(text.strip())
        elif text != EMPTY and (not text.startswith("#") or TOKEN.match(text)):
            items.append({"line": raw.strip(), "text": text.strip(), "notes": []})

    kept, no, other, unmatched, seen = [], [], [], [], set()
    for it in items:
        tokens = TOKEN.findall(it["line"])
        pid = next((p for p in map(find, tokens) if p), None)
        if tokens and not pid:
            unmatched.append(it["line"])
            continue
        if pid:
            seen.add(pid)
            if pid in handled:
                continue
        m = NO.match(it["line"])
        sub_no = [NO.match(n) for n in it["notes"] if NO.match(n)]
        notes = [n for n in it["notes"] if not NO.match(n)]
        if m or (pid and sub_no):
            reason = TOKEN.sub("", m.group(1)).strip(" -:") if m else sub_no[0].group(1).strip()
            no.append({"id": pid, "reason": reason, "notes": notes, "line": it["line"],
                       "fingerprint": problems[pid]["fingerprint"] if pid else None})
        elif pid:
            p = problems[pid]
            kept.append({"id": pid, "line": it["line"], "edited": it["line"] != proposal(p), "notes": notes,
                         "problem": p})
        else:
            other.append(" ".join([it["text"], *it["notes"]]))

    feedback = folder / "feedback.md"
    known = feedback.read_text() if feedback.exists() else ""
    other = [o for o in other if o not in known]

    left = [{"id": pid, "fingerprint": p["fingerprint"], "title": p["title"]}
            for pid, p in problems.items() if pid not in seen and pid not in handled]
    if state == "proposed" and not body:
        left = []
    dropped, unsure = ([], left) if unmatched else (left, [])
    if not (kept or no or dropped or unsure or unmatched or other):
        state = "done"
    return {"date": day, "state": state, "handled": [{"id": k, "verdict": v} for k, v in handled.items()],
            "kept": kept, "no": no, "dropped": dropped, "unsure": unsure, "unmatched": unmatched, "other": other}


def main() -> None:
    args = base_parser(__doc__.splitlines()[0]).parse_args()
    day = analysed_day(args).isoformat()
    print(json.dumps(read_review(insights_dir(args.vault, args.periodic), day), ensure_ascii=False, indent=1))


if __name__ == "__main__":
    main()
