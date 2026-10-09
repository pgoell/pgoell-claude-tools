# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Read a reviewed note against its page and print what the reader decided, as JSON.

Compares <insights>/<date>.md with the problems in <date>.json:
- `state`: `proposed` (not reviewed yet: act on nothing), `keep`, or `done`
  (already applied).
- `kept`: lines that still carry a problem id, with the problem attached and
  `edited: true` when the reader changed the words after the id.
- `no`: lines starting `no:`, with the id they name (if any) and the reason.
- `dropped`: problems whose line the reader deleted, the rejections.
- `other`: lines with no id, free text the reader added.
"""

import json
import re

from common import analysed_day, base_parser, insights_dir
from note import proposal

ID = re.compile(r"#(\d{2}-\d{2}-\d{2})\b")
NO = re.compile(r"^(?:-\s*)?no:\s*(.*)$", re.I)


def main() -> None:
    args = base_parser(__doc__.splitlines()[0]).parse_args()
    day = analysed_day(args).isoformat()
    folder = insights_dir(args.vault, args.periodic)
    problems = {p["id"]: p for p in json.loads((folder / f"{day}.json").read_text())["problems"]}
    lines = (folder / f"{day}.md").read_text().splitlines()

    state = "done" if "## Done" in lines else "keep" if "## Keep" in lines else "proposed"
    section = lines[lines.index("## Keep") + 1 :] if "## Keep" in lines else []
    if "## Done" in section:
        section = section[: section.index("## Done")]

    kept, no, other, seen = [], [], [], set()
    for line in (raw.strip() for raw in section):
        if not line or line.startswith("#") and not ID.match(line):
            continue
        found = ID.search(line)
        pid = found.group(1) if found and found.group(1) in problems else None
        m = NO.match(line)
        if m:
            no.append({"id": pid, "reason": ID.sub("", m.group(1)).strip(" -:"), "line": line,
                       "fingerprint": problems[pid]["fingerprint"] if pid else None})
        elif pid:
            p = problems[pid]
            kept.append({"id": pid, "line": line, "edited": line != proposal(p), "problem": p})
        else:
            other.append(line)
        if pid:
            seen.add(pid)

    dropped = [{"id": pid, "fingerprint": p["fingerprint"], "title": p["title"]}
               for pid, p in problems.items() if pid not in seen] if state == "keep" else []
    print(json.dumps({"date": day, "state": state, "kept": kept, "no": no, "dropped": dropped, "other": other},
                     ensure_ascii=False, indent=1))


if __name__ == "__main__":
    main()
