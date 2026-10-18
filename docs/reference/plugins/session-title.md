---
type: Reference
title: The session-title plugin
description: The Claude Code hook that names each new session after its folder, branch and start time.
tags: [plugin, session-title, hooks]
status: stable
---

# session-title

A Claude Code hook that names each new session after the last part of its working directory, its git branch and its start time, such as `server-infra main 10-18 11:09`, so sessions stay apart in the Remote Control list.

**Runtimes:** Claude Code

Not in Codex or Cursor: it sets a Claude Code session title, which neither has. See [Runtimes](/reference/runtimes.md).

**Source:** vendored in `plugins/session-title/`; see the [plugin README](../../../plugins/session-title/README.md) for details and credits.

**Setup:** None beyond install. The hook needs `jq` and `git` on the `PATH`.

## Hooks

| Hook            | Event                                    | What it does                                                                                                                                                                                                    |
| --------------- | ---------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `session-title` | `SessionStart`, matcher `startup\|clear` | Sets the session title (the same field `/rename` writes) to folder, branch and `MM-DD HH:MM`. Without a current branch it leaves the branch out. A resumed session keeps its title, and `/rename` overrides it. |
