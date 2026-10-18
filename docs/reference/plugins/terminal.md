---
type: Reference
title: The terminal plugin
description: The tmux skill, which drives interactive command-line programs from the agent.
tags: [plugin, terminal, tmux]
status: stable
---

# terminal

One skill that drives interactive terminal programs through `tmux`: REPLs, debuggers, TUI tools, and nested Claude Code or Codex sessions. It needs local Unix tools, so it lives apart from the other plugins and Windows users can skip it.

**Runtimes:** Claude Code, Codex, Cursor

**Source:** vendored in `plugins/terminal/`; see the [plugin README](../../../plugins/terminal/README.md) for details and credits.

**Setup:** [Set up the terminal plugin](/how-to/set-up-terminal.md)

## Skills

| Invocation       | What it does                                                                                                                                                          |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/terminal:tmux` | Start a tmux session, send keys, and read pane output to drive a REPL, debugger or TUI, or to try steering a nested agent session. Tells you how to attach and watch. |

## Sessions

The skill runs `tmux` directly, with no helper scripts, on a private socket under `$CLAUDE_TMUX_SOCKET_DIR` (default `${TMPDIR:-/tmp}/agent-tmux-sockets`), so its panes stay apart from your own tmux server. It needs `tmux` on Linux, macOS or WSL; native Windows terminals are not supported.

## Licence

Adapted from the tmux skill in Armin Ronacher's [agent-stuff](https://github.com/mitsuhiko/agent-stuff) (Apache 2.0). The plugin vendors that Apache 2.0 licence as its own `LICENSE` and its manifest declares Apache-2.0.
