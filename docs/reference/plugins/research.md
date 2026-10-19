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

## How it checks its own work

- Each researcher ends its reply on `ARTIFACT-VERIFIED <sha256>` or `ARTIFACT-MISSING <reason>`. The skill runs `sha256sum` on the researcher's file, compares the hash, and counts its `[source:` lines against a floor: 2 per sub-question, and 2 for a gap-fill file. A file that fails is sent back to the researcher once; a second failure goes to you.
- Each review round fetches up to 5 cited URLs again, numbers first, then the claims the thesis rests on. The reviewer marks each claim `confirmed`, `rejected` or `unresolved`, with a quote from the page, in a `REFETCH:` block of the review file. A rejected claim is a critical `source-quality` issue that brings a gap-fill researcher. A URL that is dead, moved or refused after one try is `unresolved`, a minor issue, and the review goes on.
- Every review round with a critical issue writes the synthesis again, once, after its gap-fill researchers end. The feedback names each issue and each gap-fill file, so the next review sees the new sources and does not stall on the same gap.

## Output

- Format: HTML by default. Ask for "a markdown research report" to get markdown for one run.
- Path: `reports/<topic-slug>-<YYYY-MM-DD>/report.html` (or `report.md`). You can name another path.
- Config: the skill ignores `.workbench/config.md` for format and path. It does honor that file's `## Design system` section, so a project-wide design system themes research reports too (see [workbench](/reference/plugins/workbench.md)). Applying a design system needs workbench 1.2.2 or later installed; without it, the skill says so and the report keeps the template's defaults.
