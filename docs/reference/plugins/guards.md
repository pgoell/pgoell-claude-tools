---
type: Reference
title: The guards plugin
description: The Claude Code hook that blocks shell commands known to kill the agent's own shell or loop forever.
tags: [plugin, guards, hooks, bash]
status: stable
---

# guards

Claude Code hooks that block shell commands known to fail. Each hook denies the call and tells the agent what to run instead, so the agent fixes the command on the next try instead of losing its shell.

**Runtimes:** Claude Code

Not in Codex or Cursor: the hook uses Claude Code's `PreToolUse` format, and no Cursor port exists yet. See [Runtimes](/reference/runtimes.md).

**Source:** vendored in `plugins/guards/`; see the [plugin README](../../../plugins/guards/README.md) for details and credits.

**Setup:** None beyond install. The hook is a Python 3 script.

## Hooks

| Hook               | Event                  | What it does                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| ------------------ | ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `pkill-self-match` | `PreToolUse` on `Bash` | Denies `pkill -f` (also `--full` and combined flags such as `-9f`) with a plain pattern, because Claude Code runs each command in a `bash -c` whose command line holds the pattern, so `pkill -f` kills the agent's own shell (exit 144). Also denies `pgrep -f` with a plain pattern in an `until` or `while` condition, which never ends for the same reason. The deny message offers `fuser -k <port>/tcp` or a bracketed pattern such as `pkill -f '[u]vicorn app'`. |

`pkill` or `pgrep` without `-f`, bracketed patterns, a one-shot `pgrep -f`, and every other command pass through untouched.
