# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Count one day of agent work per repository and write <activity>/<date>.json.

Sources, each of which may be missing; a missing one is marked "unavailable"
under `sources` and the run goes on:
- gh: pull requests you opened or merged on the day in your own repositories,
  every such pull request that is open now, issues opened and closed there, and
  CI of the day that ended red: the newest finished run per branch and
  workflow failed, on the default branch or a branch with an open pull
  request.
- git: commits of the day on the default branch of each repository under
  --code, so a squash or rebase copy on a side branch is not counted twice.
- issue-loop ledgers (ledger.tsv): the day's task lines.
- ~/.claude/projects: sessions with a record on the day (Europe/Berlin, by the
  record's own timestamp, through the digest skill's extract.scan), folded
  into the repository their working directory belongs to. The insights jobs'
  own sessions are left out. Sessions in a --private folder are counted under
  "vault" and give nothing else.
- bunx ccusage@20.0.28: tokens and cost per project folder and in total.
- cron logs of the insights and news jobs, and the vault's git log.

It judges nothing: the model adds `needs` and `shipped` through render.py.
"""

import json
import os
import re
import subprocess
import sys
from collections import Counter
from datetime import datetime, time, timedelta, timezone
from pathlib import Path
from urllib.parse import quote

sys.path.append(str(Path(__file__).resolve().parents[2] / "digest" / "scripts"))
from common import BERLIN, analysed_day, base_parser, insights_dir, read_jsonl  # noqa: E402
from extract import MAX_BYTES, Session, scan  # noqa: E402

ACTIVITY = "07 Activity"
STALE_DAYS = 7
PR_FIELDS = "number,title,url,repository,createdAt,isDraft"
FAILED = ("failure", "timed_out", "startup_failure")
EXTRA = (b'"type":"bridge-session"', b'"type":"pr-link"')


def run(cmd: list[str], timeout: int = 300) -> str | None:
    """A command's stdout, or None when it is missing, fails or hangs."""
    try:
        done = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
    except (OSError, subprocess.TimeoutExpired):
        return None
    return done.stdout if done.returncode == 0 else None


def run_json(cmd: list[str]):
    out = run(cmd)
    try:
        return None if out is None else json.loads(out)
    except ValueError:
        return None


def stamp(text: str) -> datetime:
    return datetime.fromisoformat(text.replace("Z", "+00:00"))


def blank(name: str) -> dict:
    return {"name": name, "slug": None, "sessions": 0, "commits": 0,
            "prs_opened": 0, "prs_merged": 0, "issues_opened": 0, "issues_closed": 0,
            "loop_tasks": 0, "loop_minutes": 0, "tokens": None, "cost": None, "merged": [],
            "_branch": None, "_numbers": set()}


def local_repos(code: Path, start: datetime, end: datetime) -> dict[str, dict]:
    """Every checkout under the code root with its GitHub slug and the day's commits."""
    repos = {}
    for path in sorted(code.iterdir()) if code.is_dir() else []:
        if not (path / ".git").is_dir():
            continue  # a `.git` file is a worktree of a checkout counted here
        repo = repos[path.name] = blank(path.name)
        m = re.search(r"github\.com[:/](.+?)(?:\.git)?$", (run(["git", "-C", str(path), "remote", "get-url", "origin"]) or "").strip())
        repo["slug"] = m.group(1) if m else None
        # The default branch as origin has it; a checkout with no remote counts its own HEAD.
        refs = ("origin/HEAD", "origin/main", "origin/master", "HEAD")
        ref = next((r for r in refs if run(["git", "-C", str(path), "rev-parse", "--verify", "-q", r]) is not None), None)
        if ref is None:
            continue  # no commit yet
        name = run(["git", "-C", str(path), "rev-parse", "--abbrev-ref", ref]) or ""
        repo["_branch"] = name.strip().removeprefix("origin/")
        log = run(["git", "-C", str(path), "log", ref, f"--since={start.isoformat()}", f"--until={end.isoformat()}", "--format=%H"])
        repo["commits"] = len((log or "").split())
    return repos


def repo_of(cwd: str, code: Path, known: dict, private: list[str]) -> str:
    """The repository a working directory belongs to: "vault" for a private folder, "other" outside the code root."""
    if any(cwd == p or cwd.startswith(p + "/") for p in private):
        return "vault"
    top = run(["git", "-C", cwd, "rev-parse", "--path-format=absolute", "--git-common-dir"]) if Path(cwd).is_dir() else None
    if top and Path(top.strip()).parent.name in known and Path(top.strip()).parent.parent == code:
        return Path(top.strip()).parent.name
    # A worktree that is gone: <repo>/.worktrees/x, <repo>/.claude/worktrees/x or <repo>-wt/x.
    try:
        first = Path(cwd).relative_to(code).parts[0]
    except (ValueError, IndexError):
        return "other"
    if first in known:
        return first
    return first[:-3] if first.endswith("-wt") and first[:-3] in known else "other"


def read_sessions(projects: Path, day, start: datetime, code: Path, known: dict, private: list[str]) -> dict:
    sessions: dict[str, Session] = {}
    folder_of: dict[str, str] = {}
    bridge: dict[str, str] = {}
    pr_session: dict[str, str] = {}
    skipped = []
    for path in projects.glob("*/**/*.jsonl"):
        st = path.stat()
        if st.st_mtime < start.timestamp():
            continue
        if st.st_size > MAX_BYTES:
            skipped.append({"file": str(path.relative_to(projects)), "mb": round(st.st_size / 1e6)})
            continue
        scan(path, projects, day, day, sessions, private)
        if "subagents" in path.parts:
            continue
        folder_of[path.stem] = path.relative_to(projects).parts[0]
        with path.open("rb") as fh:
            for raw in fh:
                if not any(w in raw for w in EXTRA):
                    continue
                try:
                    r = json.loads(raw)
                except ValueError:
                    continue  # a torn line
                if not r.get("sessionId"):
                    continue
                if r.get("bridgeSessionId"):
                    bridge[r["sessionId"]] = "https://claude.ai/code/session_" + r["bridgeSessionId"].removeprefix("cse_")
                elif r.get("prUrl"):
                    pr_session[r["prUrl"]] = r["sessionId"]

    cache: dict[str, str] = {}
    counts, folders = Counter(), {}
    for sid, s in sessions.items():
        if s.cwd not in cache:
            cache[s.cwd] = repo_of(s.cwd, code, known, private) if s.cwd else "other"
        if sid in folder_of:
            folders.setdefault(folder_of[sid], Counter())[cache[s.cwd]] += 1
        if s.days and not s.own:
            counts[cache[s.cwd]] += 1
    return {
        "counts": counts,
        "folder_repo": {f: c.most_common(1)[0][0] for f, c in folders.items()},
        "session_of": {
            url: {"id": sid, "resume": f"claude --resume {sid}", "url": bridge.get(sid)}
            for url, sid in pr_session.items()
            if sid in sessions and cache[sessions[sid].cwd] != "vault"
        },
        "own": sum(1 for s in sessions.values() if s.days and s.own),
        "skipped": skipped,
    }


def github(day_range: str, by_slug: dict, repo, now: datetime, session_of: dict, pending: set) -> tuple[list, bool]:
    """Fill PR and issue counts into the repos; return the open pull requests and whether gh answered."""
    owner = (run(["gh", "api", "user", "--jq", ".login"]) or "").strip()
    if not owner:
        return [], False
    # --owner on both searches: a title from another organisation never reaches the vault or the model.
    search = ["gh", "search", "prs", "--author=@me", f"--owner={owner}", "--limit", "1000", "--json", PR_FIELDS]
    opened = run_json([*search, f"--created={day_range}"])
    merged = run_json([*search, f"--merged-at={day_range}"])
    still_open = run_json([*search, "--state=open"])
    issues = ["gh", "search", "issues", f"--owner={owner}", "--limit", "1000", "--json", "number,repository"]
    issues_opened = run_json([*issues, f"--created={day_range}"])
    issues_closed = run_json([*issues, f"--closed={day_range}"])
    if None in (opened, merged, still_open, issues_opened, issues_closed):
        return [], False

    def of(item: dict) -> dict:
        slug = item["repository"]["nameWithOwner"]
        r = repo(by_slug.get(slug, slug.split("/")[1]))
        r["slug"] = slug
        return r

    for key, items in (("prs_opened", opened), ("prs_merged", merged),
                       ("issues_opened", issues_opened), ("issues_closed", issues_closed)):
        for item in items:
            of(item)[key] += 1
    for pr in [*opened, *merged, *still_open]:
        of(pr)["_numbers"].add(pr["number"])
    for pr in merged:
        of(pr)["merged"].append({"number": pr["number"], "title": pr["title"], "url": pr["url"]})
    open_prs = []
    for pr in sorted(still_open, key=lambda p: p["createdAt"]):
        age = (now - stamp(pr["createdAt"])).days
        open_prs.append({"repo": of(pr)["name"], "number": pr["number"], "title": pr["title"], "url": pr["url"],
                         "created": pr["createdAt"][:10], "age_days": age, "stale": age > STALE_DAYS,
                         "draft": pr["isDraft"], "insights": pr["url"] in pending, "session": session_of.get(pr["url"])})
    return open_prs, True


def failed_ci(repos: list[dict], start: datetime, end: datetime) -> tuple[list, bool]:
    """Branches whose newest finished run of the day failed, per workflow: the default branch and those with an open PR."""
    utc = "%Y-%m-%dT%H:%M:%SZ"
    created = f"{start.astimezone(timezone.utc).strftime(utc)}..{end.astimezone(timezone.utc).strftime(utc)}"
    out, ok = [], True
    for repo in repos:
        runs = run_json(["gh", "run", "list", "-R", repo["slug"], "--created", created, "--limit", "1000",
                         "--json", "conclusion,status,createdAt,headBranch,workflowName,url"])
        heads = run_json(["gh", "pr", "list", "-R", repo["slug"], "--state", "open", "--limit", "1000", "--json", "headRefName"])
        if runs is None or heads is None:
            ok = False
            continue
        watched = {h["headRefName"] for h in heads} | {repo["_branch"]}
        groups: dict[tuple, list] = {}
        for r in sorted(runs, key=lambda r: r["createdAt"]):
            if r["status"] == "completed" and r["headBranch"] in watched:
                groups.setdefault((r["headBranch"], r["workflowName"]), []).append(r)
        for (branch, workflow), group in groups.items():
            if group[-1]["conclusion"] in FAILED:
                out.append({"repo": repo["name"], "branch": branch, "workflow": workflow,
                            "failures": sum(r["conclusion"] in FAILED for r in group), "url": group[-1]["url"]})
    return out, ok


def pr_numbers(row: dict) -> list[int]:
    """The PR numbers of a ledger line; "226 (open, rule 16)" is PR 226."""
    return [int(n) for n in re.findall(r"\d+", row["prs"].split("(")[0])]


def read_ledgers(files: list[Path], day: str, repos: dict[str, dict], code: Path) -> list[dict]:
    """The day's lines of each ledger: date, issues, PRs, minutes, closed, opened, not fixed, notes."""
    rows = []
    for file in files:
        mine = []
        for line in file.read_text(errors="replace").splitlines():
            cells = (line.split("\t") + [""] * 8)[:8]
            if cells[0] == day:
                mine.append(dict(zip(("date", "issues", "prs", "minutes", "closed", "opened", "not_fixed", "notes"), cells)))
        if not mine:
            continue
        # The repo the loop works on: loop.env names it; else the one whose pull requests carry the ledger's numbers.
        env = file.parent / "loop.env"
        m = re.search(r"^REPO=(.+)$", env.read_text(), re.M) if env.exists() else None
        name = Path(m.group(1).strip("'\" ")).name if m else None
        if name not in repos:
            numbers = {n for row in mine for n in pr_numbers(row)}
            hits = {r["name"]: len(numbers & r["_numbers"]) for r in repos.values()}
            best = max(hits, key=hits.get, default=None)
            inside = file.relative_to(code).parts[0] if file.is_relative_to(code) else "other"
            name = best if best and hits[best] else inside
        repo = repos.setdefault(name, blank(name))
        for row in mine:
            row["file"], row["repo"] = str(file), name
            row["pr_urls"] = [f"https://github.com/{repo['slug']}/pull/{n}" for n in pr_numbers(row)] if repo["slug"] else []
            repo["loop_tasks"] += 1
            repo["loop_minutes"] += int((re.match(r"\d+", row["minutes"]) or [0])[0])
        rows += mine
    return rows


def usage(day, repos, folder_repo: dict) -> dict | None:
    """Tokens and cost from ccusage, per project folder and in total."""
    compact = day.strftime("%Y%m%d")
    data = run_json(["bunx", "ccusage@20.0.28", "claude", "daily", "--json", "--instances", "--since", compact, "--until", compact,
                     "--timezone", "Europe/Berlin"])
    if not data or "projects" not in data:
        return None
    for folder, days in data["projects"].items():
        repo = repos(folder_repo.get(folder, "other"))
        for row in days:
            repo["tokens"] = (repo["tokens"] or 0) + row["totalTokens"]
            repo["cost"] = round((repo["cost"] or 0) + row["totalCost"], 2)
    totals = data.get("totals") or {}
    return {"tokens": totals.get("totalTokens"), "cost": round(totals.get("totalCost") or 0, 2)}


def cron_jobs(state: Path, day) -> list[dict]:
    """How each insights and news cron run of the day, and of the morning after, ended."""
    out = []
    for folder in ("insights", "news"):
        for d in (day, day + timedelta(days=1)):
            for log in sorted((state / folder).glob(f"{d.isoformat()}*.log")):
                exits = re.findall(r"^== \S+ exit (\d+)", log.read_text(errors="replace"), re.M)
                state_word = "running or died" if not exits else "ok" if exits[-1] == "0" else f"failed, exit {exits[-1]}"
                out.append({"job": f"{folder}{log.stem[10:]}", "date": d.isoformat(), "state": state_word, "log": str(log)})
    return out


def vault_notes(vault: Path, start: datetime, end: datetime) -> dict | None:
    """How many notes the vault's git log shows written or changed on the day, by top folder. No names."""
    log = run(["git", "-C", str(vault), "-c", "core.quotepath=off", "log", f"--since={start.isoformat()}",
               f"--until={end.isoformat()}", "--name-only", "--format="])
    if log is None:
        return None
    notes = {p for p in log.splitlines() if p.endswith(".md") and not p.startswith(".")}
    folders = Counter(p.split("/")[0] if "/" in p else "(root)" for p in notes)
    return {"notes": len(notes), "folders": folders.most_common(5)}


def main() -> None:
    home = Path.home()
    parser = base_parser(__doc__.splitlines()[0])
    parser.add_argument("--code", type=Path, default=home / "Code", help="folder that holds the git checkouts")
    parser.add_argument("--ledger", type=Path, action="append", help="an issue-loop ledger.tsv (repeatable; default: every one two levels under --code)")
    parser.add_argument("--projects", type=Path, default=home / ".claude" / "projects")
    parser.add_argument("--state", type=Path, default=home / ".local" / "state", help="folder that holds the insights and news cron logs")
    parser.add_argument("--private", action="append", default=[], help="folder whose sessions are only counted (repeatable)")
    args = parser.parse_args()
    day = analysed_day(args)
    code = args.code.expanduser().resolve()
    private = [str(Path(p).expanduser().resolve()) for p in args.private + os.environ.get("INSIGHTS_PRIVATE", "").split(":") if p]
    start = datetime.combine(day, time(), BERLIN)
    end = datetime.combine(day, time(23, 59, 59), BERLIN)
    now = datetime.now(BERLIN)

    repos = local_repos(code, start, end)

    def repo(name: str) -> dict:
        return repos.setdefault(name, blank(name))

    seen = read_sessions(args.projects, day, start, code, repos, private)
    for name, n in seen["counts"].items():
        repo(name)["sessions"] = n

    pending = {m.get("ref") for m in read_jsonl(insights_dir(args.vault, args.periodic) / "memory" / "problems.jsonl")
               if m.get("verdict") == "pending"}
    by_slug = {r["slug"]: r["name"] for r in repos.values() if r["slug"]}
    open_prs, gh_ok = github(f"{start.isoformat()}..{end.isoformat()}", by_slug, repo, now, seen["session_of"], pending)

    ledgers = args.ledger or sorted({*code.glob("*/ledger.tsv"), *code.glob("*/*/ledger.tsv")})
    ledger = read_ledgers([f for f in ledgers if f.exists()], day.isoformat(), repos, code)
    cost = usage(day, repo, seen["folder_repo"])

    def active(r: dict) -> bool:
        return any(r[k] for k in ("sessions", "commits", "prs_opened", "prs_merged", "issues_opened", "issues_closed", "loop_tasks", "tokens"))

    ci, ci_ok = failed_ci([r for r in repos.values() if r["slug"] and active(r)], start, end) if gh_ok else ([], False)
    for r in repos.values():
        if r["slug"]:
            r["url"] = f"https://github.com/{r['slug']}"
            merged = f"is:pr is:merged author:@me merged:{start.isoformat()}..{end.isoformat()}"
            r["merged_url"] = f"{r['url']}/pulls?q={quote(merged)}"
    notes = vault_notes(args.vault, start, end)

    def word(ok: bool) -> str:
        return "ok" if ok else "unavailable"

    page = {
        "date": day.isoformat(),
        "sources": {
            "github": word(gh_ok),
            "ci": word(ci_ok),
            "ledger": "ok" if ledgers else "no ledger found",
            "usage": word(cost is not None),
            "vault": word(notes is not None),
        },
        "repos": sorted(({k: v for k, v in r.items() if not k.startswith("_")} for r in repos.values() if active(r)),
                        key=lambda r: (-r["sessions"], -r["commits"], r["name"])),
        "open_prs": open_prs,
        "failed_ci": ci,
        "ledger": ledger,
        "usage": cost,
        "cron": cron_jobs(args.state, day),
        "vault": notes,
        "scope": {"own_runs_skipped": seen["own"], "skipped_large": seen["skipped"]},
        "needs": [],
        "shipped": {},
    }
    out = args.vault / args.periodic / ACTIVITY / f"{day.isoformat()}.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(page, ensure_ascii=False, indent=1))
    print(f"wrote {out}: {len(page['repos'])} repos, {sum(r['sessions'] for r in page['repos'])} sessions, "
          f"{len(open_prs)} open PRs, {len(ci)} failed CI, {len(ledger)} ledger lines; " + ", ".join(f"{k} {v}" for k, v in page["sources"].items()))


if __name__ == "__main__":
    main()
