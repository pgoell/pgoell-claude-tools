# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Boil 14 days of Claude Code transcripts down to a compact digest for one day.

Streams ~/.claude/projects/**/*.jsonl (main threads and subagents) and buckets
every record by its own `timestamp` in Europe/Berlin, never by file mtime:
sessions live for days. Only files modified since the window opened are read,
and files over 300 MB are skipped and listed.

What it keeps:
- tool errors (`tool_result` with `is_error`) and hook errors, normalized into
  shapes (paths, hex and numbers stripped) with per-day counts, projects,
  tools, the first word of the failing Bash command, two examples and session
  ids. "Exit code N" keeps its N, since the code is the signal.
- what the human typed on the analysed day, main threads only, capped per
  message. Sessions run inside a --private folder (the vault; also every path
  in $INSIGHTS_PRIVATE, colon-separated) give none unless they touched a path
  under `02 Projects/`.
- the newspaper's headless runs (their own group) and its logs.

Sessions of the insights job itself are dropped whole: they carry MARKER in
their prompt or start with /insights:. Prints the digest JSON, or writes --out.
"""

import argparse
import json
import os
import re
import sys
from collections import Counter, defaultdict
from datetime import date, datetime, time, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

BERLIN = ZoneInfo("Europe/Berlin")
WINDOW = 14
MAX_BYTES = 300_000_000
MARKER = "insights-self-run"
HOME = str(Path.home())
TEXT_CAP = 600
EXAMPLE_CAP = 300

GUARD = re.compile(r"Refusing|denied|[Bb]locked|hook|not permitted|not allowed")
REJECT = re.compile(r"doesn't want to proceed|rejected|interrupted by user")
EXIT = re.compile(r"^Exit code (\d+)")
PROJECT_TOUCH = ("02 Projects/", "02%20Projects/")
NEWS_CMD = "<command-name>/news:edition</command-name>"
SELF_CMD = "<command-name>/insights:"
# Lines worth a json.loads; everything else (most tool output) is skipped unparsed.
WANTED = (b'"is_error":true', b'"type":"tool_use"', b'"type":"user"', b"hook_non_blocking_error", b"hook_blocking_error")


def shape_of(text: str) -> str:
    first = text.strip().splitlines()[0][:200] if text.strip() else "(empty)"
    m = EXIT.match(first)
    if m:
        return f"Exit code {m.group(1)}"
    first = re.sub(r"https?://\S+", "<url>", first)
    first = re.sub(r"[~.]?/[\w./~@+%-]+", "<path>", first)
    first = re.sub(r"\b[0-9a-f]{7,}\b", "<hex>", first)
    return re.sub(r"\d+", "<n>", first)


def command_word(cmd: str) -> str:
    """The program a Bash call ran: past `cd DIR &&`, env assignments and a subshell paren."""
    cmd = re.sub(r"^\s*cd\s+\S+\s*(&&|;)\s*", "", cmd).lstrip("( ")
    words = [w for w in cmd.split() if not re.match(r"^\w+=", w)]
    return words[0] if words else ""


def kind_of(text: str) -> str:
    if REJECT.search(text[:300]):
        return "rejection"
    if GUARD.search(text[:400]):
        return "guard"
    return "error"


def project_of(cwd: str, folder: str, private: list[str]) -> str:
    if not cwd:
        return folder.replace("-home-pascal-Code-", "").replace("-home-pascal-", "")
    cwd = re.split(r"/\.(?:claude/)?worktrees/", cwd)[0]
    if any(cwd == p or cwd.startswith(p + "/") for p in private):
        return "vault"
    code = f"{HOME}/Code/"
    if cwd.startswith(code):
        return cwd[len(code) :].split("/")[0]
    return Path(cwd).name or cwd


def flat(content) -> str:
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return " ".join(b.get("text", "") for b in content if isinstance(b, dict))
    return str(content or "")


def human_text(record: dict) -> str | None:
    """The text a person typed, or None for skill bodies, notifications and commands."""
    if record.get("isMeta") or record.get("isSidechain"):
        return None
    if (record.get("origin") or {}).get("kind") not in (None, "human"):
        return None
    if record.get("promptSource") in ("system", "sdk"):
        return None
    content = (record.get("message") or {}).get("content")
    if isinstance(content, list):
        if any(isinstance(b, dict) and b.get("type") == "tool_result" for b in content):
            return None
        content = " ".join(b.get("text", "") for b in content if isinstance(b, dict) and b.get("type") == "text")
    text = (content or "").strip()
    if not text or text.startswith(("<", "[Request interrupted", "Caveat:")):
        return None
    return text


class Session:
    def __init__(self) -> None:
        self.project = ""
        self.cwd = ""
        self.headless = False
        self.news = False
        self.own = False
        self.touched_projects = False
        self.title = ""
        self.first: datetime | None = None
        self.days: set[str] = set()
        self.texts: list[dict] = []
        self.errors: list[dict] = []
        self.subagent_files = 0


def scan(path: Path, root: Path, start: date, end: date, sessions: dict[str, Session], private: list[str]) -> None:
    folder = path.relative_to(root).parts[0]
    is_sub = "subagents" in path.parts
    tools: dict[str, tuple[str, str]] = {}
    with path.open("rb") as fh:
        for raw in fh:
            if b'"type":"ai-title"' in raw:
                r = json.loads(raw)
                sessions.setdefault(r.get("sessionId", ""), Session()).title = r.get("aiTitle", "")
                continue
            if not any(w in raw for w in WANTED):
                continue
            # A tool result that is not an error is bulk output; only errors matter.
            if b'"tool_result"' in raw and b'"is_error":true' not in raw:
                continue
            try:
                r = json.loads(raw)
            except ValueError:
                continue
            ts = r.get("timestamp")
            sid = r.get("sessionId")
            if not ts or not sid:
                continue
            moment = datetime.fromisoformat(ts.replace("Z", "+00:00")).astimezone(BERLIN)
            day = moment.date()
            s = sessions.setdefault(sid, Session())
            if not s.cwd and r.get("cwd"):
                s.cwd = r["cwd"]
                s.project = project_of(s.cwd, folder, private)
            if r.get("entrypoint") == "sdk-cli":
                s.headless = True
            content = (r.get("message") or {}).get("content")
            if r.get("type") == "user" and not r.get("isSidechain"):
                text = flat(content)
                if MARKER in text or SELF_CMD in text:
                    s.own = True
                if NEWS_CMD in text:
                    s.news = True
            if day < start or day > end:
                continue
            s.days.add(day.isoformat())
            if s.first is None or moment < s.first:
                s.first = moment
            if r.get("type") == "attachment":
                a = r.get("attachment") or {}
                text = f"{a.get('hookEvent', 'hook')} hook failed: {a.get('stderr', '')}".strip()
                s.errors.append(
                    {"day": day.isoformat(), "tool": a.get("hookName", "hook"), "text": text, "cmd": "", "kind": "guard"}
                )
                continue
            if not isinstance(content, list):
                content = []
            for b in content:
                if not isinstance(b, dict):
                    continue
                if b.get("type") == "tool_use":
                    inp = b.get("input") or {}
                    cmd = str(inp.get("command", "")) if isinstance(inp, dict) else ""
                    tools[b.get("id", "")] = (b.get("name", "?"), cmd)
                    if not s.touched_projects and any(p in json.dumps(inp, ensure_ascii=False) for p in PROJECT_TOUCH):
                        s.touched_projects = True
                elif b.get("type") == "tool_result" and b.get("is_error"):
                    text = flat(b.get("content"))
                    name, cmd = tools.get(b.get("tool_use_id", ""), ("?", ""))
                    s.errors.append({"day": day.isoformat(), "tool": name, "text": text, "cmd": cmd, "kind": kind_of(text)})
            if r.get("type") == "user" and day == end:
                text = human_text(r)
                if text:
                    s.texts.append({"time": moment.strftime("%H:%M"), "text": text[:TEXT_CAP]})
    if is_sub:
        sid = path.parent.parent.name
        sessions.setdefault(sid, Session()).subagent_files += 1


def news_logs(folder: Path, days: list[date]) -> list[dict]:
    keep = re.compile(r"fail|403|429|401|timeout|time out|warn|error|not committed|fallback|gap|question|missing", re.I)
    out = []
    for d in days:
        log = folder / f"{d.isoformat()}.log"
        if not log.exists():
            continue
        lines = log.read_text(errors="replace").splitlines()
        stamps = [datetime.fromisoformat(m.group(1)) for m in map(re.compile(r"^== (\S+) ").match, lines) if m]
        exits = [m.group(1) for m in map(re.compile(r"^== \S+ exit (\d+)").match, lines) if m]
        minutes = round((stamps[-1] - stamps[0]).total_seconds() / 60) if len(stamps) >= 2 else None
        notes = [line.strip()[:EXAMPLE_CAP] for line in lines if not line.startswith("==") and keep.search(line)]
        out.append({"date": d.isoformat(), "minutes": minutes, "exit": exits[-1] if exits else None, "notes": notes[:10]})
    return out


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--date", type=date.fromisoformat, help="analysed day, default yesterday in Berlin")
    parser.add_argument("--projects", type=Path, default=Path.home() / ".claude" / "projects")
    parser.add_argument("--news-logs", type=Path, default=Path.home() / ".local" / "state" / "news")
    parser.add_argument("--private", action="append", default=[], help="folder whose sessions hide what was typed (repeatable)")
    parser.add_argument("--out", type=Path, help="write the digest here instead of stdout")
    args = parser.parse_args()
    private = [str(Path(p).expanduser().resolve()) for p in args.private + os.environ.get("INSIGHTS_PRIVATE", "").split(":") if p]
    end = args.date or datetime.now(BERLIN).date() - timedelta(days=1)
    start = end - timedelta(days=WINDOW - 1)
    days = [start + timedelta(days=i) for i in range(WINDOW)]
    since = datetime.combine(start, time(), BERLIN).timestamp()

    sessions: dict[str, Session] = {}
    skipped, main_files, read_bytes = [], 0, 0
    for path in args.projects.glob("*/**/*.jsonl"):
        st = path.stat()
        if st.st_mtime < since:
            continue
        if st.st_size > MAX_BYTES:
            skipped.append({"file": str(path.relative_to(args.projects)), "mb": round(st.st_size / 1e6)})
            continue
        read_bytes += st.st_size
        main_files += "subagents" not in path.parts
        scan(path, args.projects, start, end, sessions, private)

    live = {sid: s for sid, s in sessions.items() if s.days and not s.own}
    own = sum(1 for s in sessions.values() if s.days and s.own)

    shapes: dict[tuple, dict] = {}
    for sid, s in live.items():
        group = "news" if s.news else "dev"
        project = "newspaper" if s.news else s.project or "?"
        for e in s.errors:
            key = (group, shape_of(e["text"]))
            sh = shapes.setdefault(
                key,
                {"days": Counter(), "projects": Counter(), "tools": Counter(), "commands": Counter(),
                 "sessions": Counter(), "examples": [], "kind": e["kind"]},
            )
            sh["days"][e["day"]] += 1
            sh["projects"][project] += 1
            sh["tools"][e["tool"]] += 1
            sh["sessions"][sid[:8]] += 1
            if command_word(e["cmd"]):
                sh["commands"][command_word(e["cmd"])] += 1
            if len(sh["examples"]) < 2 and (e["day"] == end.isoformat() or not sh["examples"]):
                ex = e["text"].strip()[:EXAMPLE_CAP]
                if e["cmd"]:
                    ex = f"$ {e['cmd'][:160]}\n{ex}"
                sh["examples"].append(ex)

    out_shapes = []
    for (group, shape), sh in shapes.items():
        series = [sh["days"][d.isoformat()] for d in days]
        total, yesterday = sum(series), series[-1]
        if yesterday == 0 and total < 5:
            continue
        out_shapes.append(
            {
                "group": group,
                "shape": shape,
                "kind": sh["kind"],
                "yesterday": yesterday,
                "total": total,
                "days_hit": sum(1 for v in series if v),
                "series": series,
                "projects": dict(sh["projects"].most_common(8)),
                "tools": dict(sh["tools"].most_common(5)),
                "commands": dict(sh["commands"].most_common(6)),
                "sessions": [k for k, _ in sh["sessions"].most_common(6)],
                "examples": sh["examples"],
            }
        )
    out_shapes.sort(key=lambda x: (x["yesterday"] == 0, -x["total"]))

    today_sessions = {sid: s for sid, s in live.items() if end.isoformat() in s.days}
    typed, hidden = [], 0
    for sid, s in sorted(today_sessions.items(), key=lambda kv: kv[1].first or datetime.max.replace(tzinfo=BERLIN)):
        if not s.texts or s.news or s.headless:
            continue
        if s.project == "vault" and not s.touched_projects:
            hidden += 1
            continue
        typed.append({"session": sid[:8], "project": s.project, "title": s.title, "messages": s.texts})

    digest = {
        "date": end.isoformat(),
        "window": [start.isoformat(), end.isoformat()],
        "days": [d.isoformat() for d in days],
        "scope": {
            "main_sessions": sum(1 for s in today_sessions.values() if not s.news),
            "subagent_files": sum(s.subagent_files for s in today_sessions.values()),
            "newspaper_runs": sum(1 for s in today_sessions.values() if s.news),
            "projects": len({s.project for s in today_sessions.values() if not s.news}),
            "own_runs_skipped": own,
            "vault_sessions_hidden": hidden,
            "files_read": main_files,
            "mb_read": round(read_bytes / 1e6),
            "skipped_large": skipped,
        },
        "sessions": [
            {"id": sid[:8], "project": "newspaper" if s.news else s.project, "title": s.title, "headless": s.headless}
            for sid, s in today_sessions.items()
        ],
        "shapes": out_shapes[:150],
        "typed": typed,
        "newspaper_logs": news_logs(args.news_logs, days),
    }
    text = json.dumps(digest, ensure_ascii=False, indent=1)
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(text)
        print(f"wrote {args.out}: {len(out_shapes)} shapes, {len(typed)} sessions with typed text", file=sys.stderr)
    else:
        print(text)


if __name__ == "__main__":
    main()
