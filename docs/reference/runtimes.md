---
type: Reference
title: Runtimes
description: Which plugin ships to Claude Code, Codex and Cursor, and why each absent one is absent.
tags: [runtimes, claude-code, codex, cursor, marketplace]
status: stable
---

# Runtimes

Each runtime reads its own marketplace file: Claude Code reads `.claude-plugin/marketplace.json`, Codex reads `.agents/plugins/marketplace.json`, and Cursor reads `.cursor-plugin/marketplace.json`, which `mise run sync-cursor-manifests` generates from the other two. All 25 plugins ship to Claude Code; 18 ship to Codex and 16 to Cursor.

| Plugin                                                                   | Claude Code | Codex | Cursor |
| ------------------------------------------------------------------------ | ----------- | ----- | ------ |
| [atlassian](/reference/plugins/atlassian.md)                             | yes         | yes   | yes    |
| [google-workspace](/reference/plugins/google-workspace.md)               | yes         | yes   | yes    |
| [research](/reference/plugins/research.md)                               | yes         | yes   | yes    |
| [writing](/reference/plugins/writing.md)                                 | yes         | yes   | yes    |
| [runtime-bridge](/reference/plugins/runtime-bridge.md)                   | yes         | yes   | yes    |
| [agent-system-management](/reference/plugins/agent-system-management.md) | yes         | yes   | yes    |
| [workbench](/reference/plugins/workbench.md)                             | yes         | yes   | yes    |
| [terminal](/reference/plugins/terminal.md)                               | yes         | yes   | yes    |
| [playground](/reference/plugins/playground.md)                           | yes         | yes   | yes    |
| [databricks](/reference/plugins/databricks.md)                           | yes         | yes   | yes    |
| [learning](/reference/plugins/learning.md)                               | yes         | yes   | yes    |
| [critique](/reference/plugins/critique.md)                               | yes         | yes   | yes    |
| [presentations](/reference/plugins/presentations.md)                     | yes         | yes   | yes    |
| [diagrams](/reference/plugins/diagrams.md)                               | yes         | yes   | yes    |
| [news](/reference/plugins/news.md)                                       | yes         | yes   | yes    |
| [insights](/reference/plugins/insights.md)                               | yes         | yes   | yes    |
| [issue-loop](/reference/plugins/issue-loop.md)                           | yes         | no    | no     |
| [prose-styles](/reference/plugins/prose-styles.md)                       | yes         | no    | no     |
| [guards](/reference/plugins/guards.md)                                   | yes         | no    | no     |
| [session-title](/reference/plugins/session-title.md)                     | yes         | no    | no     |
| [ponytail](/reference/plugins/ponytail.md)                               | yes         | yes   | no     |
| [emil](/reference/plugins/emil.md)                                       | yes         | no    | no     |
| [taste-skill](/reference/plugins/taste-skill.md)                         | yes         | yes   | no     |
| [vercel](/reference/plugins/vercel.md)                                   | yes         | no    | no     |
| [deprecated](/reference/plugins/deprecated.md)                           | yes         | yes   | no     |

## Why some are absent from Codex

- **issue-loop**: its skills drive Claude Code sessions themselves (`/clear`, permission modes, Claude Code's own dialogs), and the loop was never run under Codex. Its `.codex-plugin/plugin.json` exists for the version check and the manifest rule, not for the Codex marketplace.
- **prose-styles**: Codex has no output-style mechanism.
- **guards** and **session-title**: their hooks use Claude Code's hook format.
- **emil** and **vercel**: the upstream repos ship no plugin manifest at all.

## Why some are absent from Cursor

The generator skips the plugins on its `EXCLUDE` list and every upstream entry.

- **issue-loop**: drives Claude Code sessions.
- **prose-styles**: Cursor has no output-style mechanism.
- **guards**: its hook uses Claude Code's `PreToolUse` format; it would need a port to Cursor's `beforeShellExecution`.
- **session-title**: it sets a Claude Code session title, which Cursor has no equivalent for.
- **deprecated**: a frozen archive.
- **ponytail**, **emil**, **taste-skill** and **vercel**: upstream repos, with no local directory to carry a generated Cursor manifest.

Why one skill directory serves all three runtimes: [Shared skills](/explanation/shared-skills.md).
