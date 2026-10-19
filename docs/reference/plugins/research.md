---
type: Reference
title: The research plugin
description: The multi-agent research skill, its report format and where the report goes.
tags: [plugin, research, report]
status: stable
---

# research

One skill that researches a complex topic and writes a sourced report. It plans the work as clusters of questions, sends researcher subagents to search each cluster until new rounds add nothing, synthesizes the findings, and runs review gates before the final report.

**Runtimes:** Claude Code, Codex, Cursor

**Source:** vendored in `plugins/research/`; the plugin has no README of its own.

**Setup:** None beyond install.

## Skills

| Invocation           | What it does                                                                                    |
| -------------------- | ----------------------------------------------------------------------------------------------- |
| `/research:research` | Plan the investigation, gather sources, synthesize, review the conclusions, and write a report. |

## Output

- Format: HTML by default. Ask for "a markdown research report" to get markdown for one run.
- Path: `reports/<topic-slug>-<YYYY-MM-DD>/report.html` (or `report.md`). You can name another path.
- Config: the skill ignores `.workbench/config.md` for format and path. It does honor that file's `## Design system` section, so a project-wide design system themes research reports too (see [workbench](/reference/plugins/workbench.md)). Applying a design system needs workbench 1.2.2 or later installed; without it, the skill says so and the report keeps the template's defaults.
