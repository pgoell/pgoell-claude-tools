---
type: Reference
title: The unslop plugin
description: Damir Sokolovsky's redline pass that takes the AI look out of an existing screen, tracked from upstream.
tags: [plugin, unslop, upstream, frontend, design]
status: stable
---

# unslop

A redline pass over a screen that looks AI-generated. It audits the screen first, then does a full rework, a light polish or nothing, by how much it found. A polish keeps the existing brand. See [heydamir.design/unslop](https://heydamir.design/unslop).

**Runtimes:** Claude Code

Not in Codex or Cursor: the upstream ships no plugin manifest at all, so the Claude Code entry sets `strict: false` and supplies the manifest itself. See [Runtimes](/reference/runtimes.md).

**Source:** upstream, not vendored: tracks [heydamir/unslop](https://github.com/heydamir/unslop) `main` unpinned (CC BY 4.0, by Damir Sokolovsky).

**Setup:** None beyond install. The optional story video needs Playwright and ffmpeg.

## Skills

| Invocation       | What it does                                                                                      |
| ---------------- | ------------------------------------------------------------------------------------------------- |
| `/unslop:unslop` | Audits an existing screen for the AI look, then polishes it or reworks it in nine ordered passes. |

Use it to clean up a screen that already exists, and [taste-skill](/reference/plugins/taste-skill.md) to build a new page or to change a page's whole direction. Both skills' own descriptions name polish and redesign, and those descriptions live upstream, so name the skill when it matters.
