---
type: Reference
title: The deprecated plugin
description: The frozen archive of superseded skills and the replacement each one points at.
tags: [plugin, deprecated, archive]
status: stable
---

# deprecated

An archive of superseded and retired skills, kept installable so old workflows keep resolving. Each skill is frozen, carries a deprecation banner, and names its replacement or says it retired without one. Install it only if an old workflow still calls the old names; next to `presentations` or `writing` it duplicates their triggers.

**Runtimes:** Claude Code, Codex

Not in Cursor: a frozen archive has no reason to reach a new runtime. See [Runtimes](/reference/runtimes.md).

**Source:** vendored in `plugins/deprecated/`; see the [plugin README](../../../plugins/deprecated/README.md) for details and credits. `frontend-design` is a port of the [frontend-design](https://github.com/anthropics/skills/tree/ef740771ac901e03fbca3ce4e1c453a96010f30a/skills/frontend-design) skill in Anthropic's `anthropics/skills` repository (Apache 2.0). Most former `workbench` skills derive from Jesse Vincent's [Superpowers](https://github.com/obra/superpowers) 5.0.7 (MIT), and the `crafting-html` references from Thariq Shihipar's [html-effectiveness](https://github.com/ThariqS/html-effectiveness) gallery (no license at the ported commit). See `plugins/deprecated/NOTICE`.

**Setup:** None beyond install.

## Skills

| Invocation                                   | Moved from                           | Replacement                                                                               |
| -------------------------------------------- | ------------------------------------ | ----------------------------------------------------------------------------------------- |
| `/deprecated:crafting-presentations`         | `workbench`                          | `/presentations:creating-presentations`                                                   |
| `/deprecated:perfecting-presentations`       | `workbench`                          | `/presentations:creating-presentations` (the review loop is an opt-in phase there)        |
| `/deprecated:exporting-decks-to-pptx`        | `workbench`                          | `/presentations:exporting-presentations-to-pptx`                                          |
| `/deprecated:presentations`                  | `writing`                            | `/presentations:designing-presentations`                                                  |
| `/deprecated:autopilot`                      | `workbench`                          | Retired without replacement (its successor `pilot` is archived too)                       |
| `/deprecated:copilot`                        | `workbench`                          | Retired without replacement (its successor `pilot` is archived too)                       |
| `/deprecated:dispatching-parallel-agents`    | `workbench`                          | Retired without replacement (its successor `subagent-driven-development` is archived too) |
| `/deprecated:terse-mode`                     | `workbench`                          | Retired without replacement                                                               |
| `/deprecated:writing`                        | `writing`                            | `/writing:ghostwrite` (drafting) and `/writing:coach` (learning to write)                 |
| `/deprecated:pyramid`                        | `writing`                            | `/writing:ghostwrite` (pyramid audits) and `/writing:coach` (structure drill)             |
| `/deprecated:tech-doc`                       | `writing`                            | `/writing:ghostwrite` (tech docs from the repository)                                     |
| `/deprecated:frontend-design`                | the retired `frontend-design` plugin | `/taste-skill:taste-skill` in Claude Code, `taste-skill:design-taste-frontend` in Codex   |
| `/deprecated:pilot`                          | the retired `workbench` plugin       | Retired without replacement                                                               |
| `/deprecated:using-workbench`                | the retired `workbench` plugin       | Retired without replacement                                                               |
| `/deprecated:brainstorming`                  | the retired `workbench` plugin       | Retired without replacement                                                               |
| `/deprecated:writing-spec`                   | the retired `workbench` plugin       | Retired without replacement                                                               |
| `/deprecated:writing-plans`                  | the retired `workbench` plugin       | Retired without replacement                                                               |
| `/deprecated:visualizing-options`            | the retired `workbench` plugin       | Retired without replacement                                                               |
| `/deprecated:test-driven-development`        | the retired `workbench` plugin       | Retired without replacement                                                               |
| `/deprecated:subagent-driven-development`    | the retired `workbench` plugin       | Retired without replacement                                                               |
| `/deprecated:systematic-debugging`           | the retired `workbench` plugin       | Retired without replacement                                                               |
| `/deprecated:verification-before-completion` | the retired `workbench` plugin       | Retired without replacement                                                               |
| `/deprecated:crafting-html`                  | the retired `workbench` plugin       | Retired without replacement                                                               |
| `/deprecated:crafting-design-systems`        | the retired `workbench` plugin       | Retired without replacement                                                               |

Why the archive exists and how a skill moves into it: [The deprecated archive](/explanation/the-deprecated-archive.md).
