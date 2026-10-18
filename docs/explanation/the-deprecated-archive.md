---
type: Explanation
title: The deprecated archive
description: Why superseded skills stay installable in the deprecated plugin, what each one was replaced by, and when to install it.
tags: [deprecated, archive, migration]
status: stable
---

# The deprecated archive

When a restructure replaces a skill, the old skill does not vanish. It moves into the `deprecated` plugin in the same pull request that removes it from its live plugin. Old workflows, prompts and notes that still call the old name keep working, and you can move to the replacement when it suits you.

## What the banner means

Each archived skill starts its description with "Deprecated, superseded by" and the replacement, and carries a one-line banner under its heading:

> **Deprecated.** Superseded by `workbench:pilot` [...]. This copy is archived and no longer maintained.

The skill is frozen. Nobody extends it or fixes it. Its references to its old siblings point inside `deprecated`, so the archive stays whole on its own.

## The four batches

| Batch   | Skill                         | Formerly in       | Replaced by                                                   |
| ------- | ----------------------------- | ----------------- | ------------------------------------------------------------- |
| 2026-07 | `crafting-presentations`      | `workbench`       | `presentations:creating-presentations`                        |
| 2026-07 | `perfecting-presentations`    | `workbench`       | `presentations:creating-presentations` (its perfecting phase) |
| 2026-07 | `exporting-decks-to-pptx`     | `workbench`       | `presentations:exporting-presentations-to-pptx`               |
| 2026-07 | `presentations`               | `writing`         | `presentations:designing-presentations`                       |
| 2026-08 | `autopilot`, `copilot`        | `workbench`       | `workbench:pilot`                                             |
| 2026-08 | `dispatching-parallel-agents` | `workbench`       | `workbench:subagent-driven-development`                       |
| 2026-08 | `terse-mode`                  | `workbench`       | nothing, retired                                              |
| 2026-09 | `writing`                     | `writing`         | `writing:ghostwrite` and `writing:coach`                      |
| 2026-09 | `pyramid`                     | `writing`         | `writing:ghostwrite` and `writing:coach`                      |
| 2026-09 | `tech-doc`                    | `writing`         | `writing:ghostwrite`                                          |
| 2026-10 | `frontend-design`             | `frontend-design` | `taste-skill:taste-skill`                                     |

The 2026-10 batch retired a whole plugin. The archived `frontend-design` skill is an Anthropic Apache 2.0 port, so its `LICENSE` and `NOTICE` moved into `deprecated` with it.

## When to install it

Install `deprecated` only when something you rely on still calls an old skill name. Otherwise use the replacement. Installing it beside `presentations`, `workbench` or `writing` puts two skills for the same job in front of the agent, and it may pick the frozen one.

Claude Code and Codex list the plugin; Cursor does not. For moving from `autopilot` or `copilot`, see [Move to workbench pilot](/how-to/move-to-workbench-pilot.md). The plugin's page is [deprecated](/reference/plugins/deprecated.md).

## The `deprecated` plugin is a registered, frozen archive

This section is for contributors; [AGENTS.md](../../AGENTS.md) states the rule in short.

When a restructure supersedes a skill, move it (SKILL.md plus references) into `plugins/deprecated/skills/<old-name>/` in the same pull request that removes it from its live plugin. Prefix its frontmatter description with "Deprecated, superseded by <replacement>." and add a one-line banner under the H1 that names the replacement. Rewrite its internal cross-references to the `deprecated:` namespace so the archive stays whole, and drop or de-brand any bundled asset that must not ship. Deprecated skills are never extended and are not listed one by one in `docs/reference/skills.md`. The plugin stays registered in both marketplaces so old workflows keep resolving. An archived port keeps its upstream attribution: move the `NOTICE` block with the file.

How each batch went:

- **2026-07:** `crafting-presentations`, `perfecting-presentations`, `exporting-decks-to-pptx` (from workbench 0.22.0) and `presentations` (from writing 2.0.0), all superseded by the `presentations` plugin. The branded example deck did not move with `crafting-presentations`; its de-branded successor became the presentations plugin's `default` preset.
- **2026-08:** `autopilot`, `copilot`, `dispatching-parallel-agents`, `terse-mode` (from workbench 0.22.0, superseded by workbench 1.0.0). `autopilot` and `copilot` gave way to `workbench:pilot`, whose `Gates:` profile row picks the old autopilot or copilot behavior. `dispatching-parallel-agents` gave way to the `## Parallel dispatch` section of `workbench:subagent-driven-development`. `terse-mode` retired without replacement.
- **2026-09:** `writing`, `pyramid`, `tech-doc` (from writing 2.0.0, superseded by writing 3.0.0). `writing` gave way to `writing:ghostwrite` (drafting) and `writing:coach` (learning to write), `pyramid` to the pyramid audits in `ghostwrite` and the Socratic structure drill in `coach`, and `tech-doc` to `ghostwrite`'s tech-doc route. Their kept parts (interview rules, throughline gate, pyramid audits, Diátaxis quadrants, reference schemas, three argument critics) were rewritten into the new skills' `references/`, not moved.
- **2026-10:** `frontend-design` (the Anthropic Apache-2.0 port), superseded by the external `taste-skill:taste-skill`. The whole `frontend-design` plugin retired and left both marketplaces, so its `LICENSE` and `NOTICE` moved into `plugins/deprecated/` with the skill. That made `deprecated` the first archive to carry port attribution.
