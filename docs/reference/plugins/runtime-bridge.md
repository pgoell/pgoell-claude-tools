---
type: Reference
title: The runtime-bridge plugin
description: The skill that keeps a project's Claude Code and Codex configuration in step.
tags: [plugin, runtime-bridge, codex, claude-code]
status: stable
---

# runtime-bridge

One skill that aligns a project's Claude Code and Codex CLI configuration in both directions. It finds which runtime files exist, writes the missing side, reports drift, and shows which plugins each runtime has. It works on local files only, makes no network calls, and never edits skill content.

**Runtimes:** Claude Code, Codex, Cursor

**Source:** vendored in `plugins/runtime-bridge/`; the plugin has no README of its own.

**Setup:** None beyond install.

## Skills

| Invocation                            | What it does                                                                                                                                                                                                                                                                              |
| ------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/runtime-bridge:claude-codex-bridge` | Align project instruction files, settings, hooks, agents and plugin availability across Claude Code and Codex. The main session scouts the project and builds a manifest, you approve it, the main session writes the files, and a fresh reviewer subagent checks them. Offers a dry run. |
