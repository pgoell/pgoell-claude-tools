---
type: Reference
title: The research plugin
description: The two research skills (clarify a brief, then run the research), the report format and where the report goes.
tags: [plugin, research, report]
status: stable
---

# research

Two skills that research a complex topic and write a sourced report. `research` asks one question at a time until the brief is complete (topic, scope, audience, purpose, deliverable, deadline), writes `brief.md`, waits for your approval and recommends the next skill. You then call `running-research`: it plans the work as clusters of questions, sends researcher subagents to search each cluster until new rounds add nothing, synthesizes the findings, and runs review gates before the final report.

The split is on purpose. While `research` asks, it cannot see the plan, search and report steps, so it does not rush past the questions to start them. `running-research` stops and sends you back to `research` when it finds no approved brief.

You may skip a question. After you hear once why it matters, the field goes into the brief as `open (user skipped)`; `running-research` makes that choice while it plans and lists it under `## Open fields` in `plan.md`. The report fits the brief's deliverable: a two-page summary gets only the sections that fit two pages, in the language the brief names, and the report review fails a draft that runs longer or uses another language.

**Runtimes:** Claude Code, Codex, Cursor

**Source:** vendored in `plugins/research/`; the plugin has no README of its own.

**Setup:** None beyond install.

## Skills

| Invocation                   | What it does                                                                                                                  |
| ---------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `/research:research`         | Ask one question at a time, write `brief.md`, get your approval, and recommend `/research:running-research`. Plans nothing.   |
| `/research:running-research` | From the approved `brief.md`: plan the investigation, gather sources, synthesize, review the conclusions, and write a report. |

## How it checks its own work

- Each researcher ends its reply on `ARTIFACT-VERIFIED <sha256>` or `ARTIFACT-MISSING <reason>`. `running-research` runs `sha256sum` on the researcher's file, compares the hash, and counts its `[source:` lines against a floor: 2 per sub-question, and 2 for a gap-fill file. A file that fails is sent back to the researcher once; a second failure goes to you.
- Each review round fetches up to 5 cited URLs again, numbers first, then the claims the thesis rests on. The reviewer marks each claim `confirmed`, `rejected` or `unresolved`, with a quote from the page, in a `REFETCH:` block of the review file. A rejected claim is a critical `source-quality` issue that brings a gap-fill researcher. A URL that is dead, moved or refused after one try is `unresolved`, a minor issue, and the review goes on.
- Every review round with a critical issue writes the synthesis again, once, after its gap-fill researchers end. The feedback names each issue and each gap-fill file, so the next review sees the new sources and does not stall on the same gap.

## Output

- Format: the brief's `Format:` line, HTML unless you ask for markdown. Asking `running-research` for "a markdown research report" overrides the brief for one run.
- Path: the brief's folder, `reports/<topic-slug>-<YYYY-MM-DD>/` by default, holding `brief.md` and later the report. You can name another folder while `research` asks its questions.
- Files: the last step renames the reviewed draft to `report.md`. For HTML, the orchestrator then renders `report.html` from `report.md` with the bundled template, keeps every heading and link, and checks that no link or template sample text went missing; `report.html` is the report and `report.md` its markdown source. If the render fails its check, you get `report.md` alone and a note saying why. For markdown, `report.md` is the report.
- Config: `running-research` ignores `.workbench/config.md` for format and path. It does honor that file's `## Design system` section, so a project-wide design system themes research reports too (see [workbench](/reference/plugins/workbench.md)). Applying a design system needs workbench 1.2.2 or later installed; without it, the skill says so and the report keeps the template's defaults.

## Evals

`plugins/research/evals/` holds 16 `claude plugin eval` cases that test when `research` fires. Cases 01 to 04 are triggers: a sourced investigation, a market comparison, a market or industry analysis and a trend or history ask, where `research:research` must fire. In cases 03 and 04 `anthropic-skills:deep-research` must not fire either. Cases 21 to 23 are negatives (a concept question, a translation, a one-paragraph summary): neither `research:research` nor `anthropic-skills:deep-research` may fire.

Cases 31 to 36 are near-misses. Cases 31 and 32 ask in the words of the anthropic-skills `deep-research` skill (a literature review; the history and trends of an industry): `research:research` must fire and `anthropic-skills:deep-research` must not. Cases 33 to 36 are plain web lookups (one fact, a current version, a docs page, a given URL): neither skill may fire, and an `llm` grader checks that the answer came straight back, with no plan, report or subagents. These four allow WebSearch and WebFetch. WebFetch is a gated tool that `allowed_tools` alone does not grant, so the run command below grants it with `--allow-tools WebFetch`; a run of these four needs network.

Cases 37 to 39 are near-misses that use literature, comparison and trend words but want a direct answer from the given text or from what the model knows (rank three given study abstracts; pick between two options in a paragraph; a two-sentence trend answer): neither skill may fire, and an `llm` grader checks for a direct answer. They need no WebSearch or WebFetch.

No prompt uses the word "research", so the model must route on meaning. The graders match the full names `research:research` and `anthropic-skills:deep-research`, so a word in a call's args does not match. The `anthropic-skills:deep-research` graders pass on their own unless the eval run loads the anthropic-skills plugin. With that plugin loaded, `research` should win cases 03, 04, 31 and 32: its description now names literature and study reviews, trends and history, markets and comparisons, and says to prefer it over other deep-research skills for these asks. They may also pass for another reason: `deep-research` asks for a subagent tool, and these cases allow none.

No one has run the suite yet; a run costs money, so the user decides when. Run from `plugins/research`:

```bash
claude plugin eval . --trust-plugin --tag core --runs 1 -j 4 --max-cost-usd 10 --no-publish --allow-tools WebFetch
```
