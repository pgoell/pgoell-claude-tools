---
type: Reference
title: The agent-system-management plugin
description: The skills that audit and update agent instruction files and build or tune skills.
tags: [plugin, agent-system-management, agents-md, claude-md, skills]
status: stable
---

# agent-system-management

Skills for the host agent's instruction layer and skill layer: audit `AGENTS.md` and `CLAUDE.md` files, write a session's learnings into the right one, and create or tune skills.

**Runtimes:** Claude Code, Codex, Cursor

**Source:** vendored in `plugins/agent-system-management/`; see the [plugin README](../../../plugins/agent-system-management/README.md) for details and credits.

**Setup:** None beyond install.

## Skills

| Invocation                                             | What it does                                                                                                                                                                                  |
| ------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/agent-system-management:improving-instructions`      | Audit `AGENTS.md` and `CLAUDE.md` files across project and user scopes, score them against a quality rubric, and propose fixes.                                                               |
| `/agent-system-management:capturing-session-learnings` | At the end of a session, write what it taught into the right instruction file. Also runs on `/revise-agents-md` and `/revise-claude-md`.                                                      |
| `/agent-system-management:creating-skills`             | Create a skill, improve one through eval loops, benchmark it against a baseline, tune its description so it triggers when it should, cut it to its core, or turn a conversation into a skill. |

## Files in scope

The two instruction skills read `AGENTS.md`, `AGENTS.local.md`, `CLAUDE.md`, `CLAUDE.local.md`, the legacy `.claude.md` and `.claude.local.md`, plus the user-global `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`. They dedupe by `realpath`, so a `CLAUDE.md` symlinked to `AGENTS.md` counts once. `GEMINI.md` is out of scope.

## Licence

The plugin is MIT. The two instruction skills derive from Anthropic's `claude-md-management` plugin and `creating-skills` from Anthropic's `skill-creator`, both Apache 2.0, with MIT-licensed writing guidance from other authors. The plugin's `NOTICE` lists every file.
