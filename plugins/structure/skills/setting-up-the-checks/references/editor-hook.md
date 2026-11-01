# The Claude Code editor hook

`scripts/structure-hook` is a Claude Code `PostToolUse` hook. After each `Edit`, `Write` or `MultiEdit`, Claude Code sends it JSON on stdin; the hook reads `tool_input.file_path` and runs `check-file-size` and `check-fan-out` (from its own folder) on that file. On a failure it prints their message to stderr and exits 2, which Claude Code shows to Claude after the tool ran. Otherwise it exits 0 and says nothing. A file outside a git repo, ignored by git, or gone passes.

The hook acts only for a repo that set the checks up. It looks for a copy of itself in the edited file's repo, at the path it has in its own repo, and a `scripts/` that is a symlink counts as `scripts/`. The file's path alone picks the repo: the hook drops `GIT_DIR`, `GIT_WORK_TREE` and the other variables a git hook exports. No copy: the file passes, and the hook writes nothing there. So a nested repo the project ignores (a vault, a colocated jj repo) gets no fan-out message and no loose objects. A copy in another repo or linked worktree: the file meets that checkout's baseline and excludes, through this copy's scripts. The hook never runs that other copy, since the edited repo may be a clone nobody has read.

That goes for git too. Git obeys the repo it works in, and `core.fsmonitor`, `filter.*`, hooks (`core.hooksPath`, `.git/hooks`), `pager.*` and a partial clone's lazy fetch all run commands. So the hook asks the edited repo only where its top and its `info/exclude` are, and runs every other git against an empty throwaway git dir with that repo as the work tree. It writes nothing to that repo, not even loose objects. This has a price. Settings in the repo's own config do not apply: a filter, `core.excludesFile` or `core.autocrlf` there changes nothing, so a file counts at its size on disk. The user's global config does apply, and a filter's command there runs, since it is the user's own; but its `includeIf "gitdir:..."` lines do not match, because the git dir is the throwaway one. With no copy of the real index, a tracked file that `.gitignore` also matches passes, and fan-out counts only what sits on disk: not that file, an uninitialised submodule or a tracked file gone from disk. Pre-commit still counts them, so such a folder fails there rather than at the edit.

Nor does the hook hang on that repo, whose files may be FIFOs or symlinks to `/dev/zero` or `/dev/urandom`. `check-file-size`, `check-fan-out` and the hook read `.file-size-excludes`, `.fan-out-excludes`, `.fan-out-baseline` and `info/exclude` only if each is a regular file, and only its first MiB. Git opens `.gitignore`, `.gitattributes` and what lies in `.git` itself, so those have other guards: git runs under a 4 GiB `ulimit -v` (a system that ignores it, such as macOS, has no such limit), and a job kills the check's process group after 30 s. Then the hook prints `structure-hook: gave up on <file>` (`the edited file` if it did not get as far as the name) and exits 1, which Claude Code reports and does not block. So does an edited file of several GB that git cannot hash in that time, and a huge `.gitignore` makes git fail, so the file passes. A SIGTERM to the hook's bash kills the group at once and removes the scratch folder. The check runs in a process group of its own, so a kill sent to the hook's group alone does not reach it, and a SIGKILL to the hook's bash leaves the scratch folder; the job still ends the check within the 30 s.

The hook starts as `#!/bin/sh`, because `env bash` could find a `bash` in the current folder. It first drops every `PATH` entry that does not start with `/` (`.`, an empty entry, `bin`, `~/bin`), and uses `/usr/bin:/bin` if none is left. This has a limit: an absolute entry stays, even one inside the edited repo, such as a folder that direnv added, and the hook then runs that folder's tools. A mise shim on `PATH` likewise reads the mise config of the folder it runs in, though mise refuses an untrusted one. The hook does not drop such an entry, because the entry is the user's own setting: every command of the session runs those tools too, the hook could not tell which repo the file is in without running a tool first, and the folder may hold the very `jq` or `git` the user wants. If you do not trust a repo, keep its folders off `PATH`.

A repo with an older copy gets this by overwriting its copy where it sits. With the copies in `scripts/`, rerun `/structure:setting-up-the-checks`: step 2 overwrites the three scripts and leaves the baseline and excludes alone. A repo that keeps them elsewhere copies `assets/structure-hook` over its own.

It needs `jq`, on `PATH` or through `mise exec --`. Without either it exits 1, which Claude Code reports as a hook error and does not block. With stdin closed it has no event, so it exits 0.

## The settings block

A project hook in `.claude/settings.json`, versioned with the repo. Never put it in a plugin's `hooks/hooks.json` or in `~/.claude/settings.json`: there it would fire in every repo, and most have no `scripts/structure-hook`.

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PROJECT_DIR}\"/scripts/structure-hook"
          }
        ]
      }
    ]
  }
}
```

## Merging

Read `.claude/settings.json` in full first, if it exists, and keep every key it has.

- No file: write the block as it stands.
- No `hooks` key, or no `PostToolUse` list: add the key or the list.
- A `PostToolUse` list: append the object above to it. If an entry already runs `scripts/structure-hook`, leave it.

Check the result is valid JSON: `jq empty .claude/settings.json`. Settings with a trailing comma or comments fail there; fix them before you go on.

## Test

Feed it a fake event for a file over the limit and expect exit 2 and a `file-size:` line:

```bash
truncate -s 20004 x.txt
printf '{"tool_name":"Write","tool_input":{"file_path":"%s/x.txt"}}' "$PWD" | scripts/structure-hook; echo "exit $?"
rm x.txt
```

If the hook does not fire in a session that was already open, tell the user to restart it. If it still stays silent, check that the session's project folder is this repo (`${CLAUDE_PROJECT_DIR}` points there), that `scripts/structure-hook` is executable, and that the edited file's repo holds a copy of the hook at that path.
