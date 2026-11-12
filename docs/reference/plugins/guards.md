---
type: Reference
title: The guards plugin
description: The Claude Code hooks that block shell commands known to kill the agent's own shell, loop forever or always fail.
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

| Hook                    | Event                  | What it does                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| ----------------------- | ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `pkill-self-match`      | `PreToolUse` on `Bash` | Denies `pkill -f` (also `--full` and combined flags such as `-9f`) with a plain pattern, because Claude Code runs each command in a `bash -c` whose command line holds the pattern, so `pkill -f` kills the agent's own shell (exit 144). Also denies `pgrep -f` with a plain pattern in an `until` or `while` condition, which never ends for the same reason. The hook tests each pattern against the command's own text, so a bracketed pattern beside a later plain mention (`pkill -f '[p]ytest x' ; pytest x`) is denied too. The deny message offers `fuser -k <port>/tcp` or a bracketed pattern in a Bash call of its own, such as `pkill -f '[u]vicorn app'`; it brackets the first letter or digit, and for a pattern already bracketed it says to run the call on its own. |
| `rev-parse-short-multi` | `PreToolUse` on `Bash` | Denies `git rev-parse --short` with two or more revisions (`git rev-parse --short HEAD origin/main`): `--short` implies `--verify`, which takes one revision, so the call always exits 128 and skips the rest of an `&&` chain. Only a `git` command word followed by `rev-parse` counts, so a commit message or a `grep` that quotes the form passes. The deny message offers one call per revision.                                                                                                                                                                                                                                                                                                                                                                                  |

`pkill` or `pgrep` without `-f`, a pattern that does not match the command's own text (a bracketed pattern on its own), a one-shot `pgrep -f`, and every other command pass through untouched. `git rev-parse --short` with one revision passes too.
