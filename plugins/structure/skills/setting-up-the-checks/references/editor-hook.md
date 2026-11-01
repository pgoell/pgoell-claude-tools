# The Claude Code editor hook

`scripts/structure-hook` is a Claude Code `PostToolUse` hook. After each `Edit`, `Write` or `MultiEdit`, Claude Code sends it JSON on stdin; the hook reads `tool_input.file_path` and runs `check-file-size` and `check-fan-out` (from its own folder) on that file. On a failure it prints their message to stderr and exits 2, which Claude Code shows to Claude after the tool ran. Otherwise it exits 0 and says nothing. A file outside a git repo, ignored by git, or gone passes.

The hook acts only for a repo that set the checks up. It looks for a copy of itself in the edited file's repo, at the path it has in its own repo. No copy: the file passes, and the hook writes nothing there. So a nested repo the project ignores (a vault, a colocated jj repo) gets no fan-out message and no loose objects. A copy in another repo or linked worktree: the file meets that checkout's baseline and excludes, through this copy's scripts. The hook never runs that other copy, since the edited repo may be a clone nobody has read.

A repo with an older copy gets this by overwriting its copy where it sits. With the copies in `scripts/`, rerun `/structure:setting-up-the-checks`: step 2 overwrites the three scripts and leaves the baseline and excludes alone. A repo that keeps them elsewhere copies `assets/structure-hook` over its own.

It needs `jq`, on `PATH` or through `mise exec --`. Without either it exits 1, which Claude Code reports as a hook error and does not block.

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
