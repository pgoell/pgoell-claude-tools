---
type: Explanation
title: One skill directory, three runtimes
description: Why Claude Code, Codex and Cursor read the same skill files through separate manifests, and why some plugins ship to Claude Code alone.
tags: [runtimes, manifests, codex, cursor]
status: stable
---

# One skill directory, three runtimes

Each skill lives once, at `plugins/<plugin>/skills/<skill>/SKILL.md`. Claude Code, Codex and Cursor all read that same file. Nobody keeps a second copy for another runtime, so a fix lands in all three at once and the copies cannot drift apart.

## Separate manifests

What differs between runtimes is the metadata that tells each one a plugin exists:

| Runtime     | Marketplace file                   | Per-plugin manifest                         |
| ----------- | ---------------------------------- | ------------------------------------------- |
| Claude Code | `.claude-plugin/marketplace.json`  | `plugins/<name>/.claude-plugin/plugin.json` |
| Codex       | `.agents/plugins/marketplace.json` | `plugins/<name>/.codex-plugin/plugin.json`  |
| Cursor      | `.cursor-plugin/marketplace.json`  | `plugins/<name>/.cursor-plugin/plugin.json` |

The Codex manifest points at the shared folder with `"skills": "./skills/"`. Where a skill uses a tool that differs between runtimes, such as the subagent tool, the skill body carries a short mapping table instead of forking into two files.

Nobody writes the Cursor files by hand. `mise run sync-cursor-manifests` builds them from the Claude Code and Codex manifests: name, description, version and the rest from the Claude Code side, the display name and skills path from the Codex side. CI runs the same task with `--check` and fails when the Cursor files drift from their sources.

## Why some plugins are Claude Code only

A plugin stays out of a runtime's marketplace when it would not work there. Four local plugins ship to Claude Code alone, for three reasons:

- **It drives Claude Code itself.** `issue-loop` has one session type `/clear` into another Claude Code session, start sessions with `--permission-mode auto`, and answer Claude Code's own dialogs. Nobody has run it under Codex or Cursor, so neither lists it.
- **It ships output styles.** `prose-styles` has no skills, only Claude Code output styles. Codex and Cursor have no output-style mechanism.
- **It ships Claude Code hooks.** `guards` and `session-title` use Claude Code's hook format. Neither has a port to another runtime's hooks.

Two more gaps have other causes. Cursor leaves out `deprecated`, a frozen archive. The upstream plugins (`ponytail`, `emil`, `taste-skill`, `vercel`) have no local folder to hold a Cursor manifest, and only `ponytail` is registered for Codex. [Runtimes](/reference/runtimes.md) lists every plugin against every runtime.

A plugin left out of a marketplace still keeps its `.codex-plugin/plugin.json`, because the version check in CI needs one for every local plugin.

The full rules, with their history, are in the design decisions of [AGENTS.md](../../AGENTS.md).
