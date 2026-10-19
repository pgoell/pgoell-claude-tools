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

## Evals

`plugins/research/evals/` holds 11 `claude plugin eval` cases that test when the skill fires. Cases 01 and 02 are triggers: a sourced investigation and a market comparison, where `research:research` must fire. Cases 21 to 23 are negatives (a concept question, a translation, a one-paragraph summary): neither `research:research` nor `anthropic-skills:deep-research` may fire.

Cases 31 to 36 are near-misses. Cases 31 and 32 ask in the words of the anthropic-skills `deep-research` skill (a literature review; the history and trends of an industry): `research:research` must fire and `anthropic-skills:deep-research` must not. Cases 33 to 36 are plain web lookups (one fact, a current version, a docs page, a given URL): neither skill may fire, and an `llm` grader checks that the answer came straight back, with no plan, report or subagents. These four allow WebSearch and WebFetch. WebFetch is a gated tool that `allowed_tools` alone does not grant, so the run command below grants it with `--allow-tools WebFetch`; a run of these four needs network.

No prompt uses the word "research", so the model must route on meaning. The graders match the full names `research:research` and `anthropic-skills:deep-research`, so a word in a call's args does not match. The `anthropic-skills:deep-research` graders pass on their own unless the eval run loads the anthropic-skills plugin. With that plugin loaded, cases 31 and 32 may fail and the run exit 1: a routing check picked `deep-research` for both, since its description names literature reviews and trends and the `research` description does not (#237). They may still pass, because `deep-research` asks for a subagent tool and these cases allow none.

No one has run the suite yet; a run costs money, so the user decides when. Run from `plugins/research`:

```bash
claude plugin eval . --trust-plugin --tag core --runs 1 -j 4 --max-cost-usd 10 --no-publish --allow-tools WebFetch
```
