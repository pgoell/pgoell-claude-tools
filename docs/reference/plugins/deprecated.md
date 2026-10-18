---
type: Reference
title: The deprecated plugin
description: The frozen archive of superseded skills and the replacement each one points at.
tags: [plugin, deprecated, archive]
status: stable
---

# deprecated

An archive of superseded skills, kept installable so old workflows keep resolving. Each skill is frozen, carries a deprecation banner, and names its replacement. Install it only if an old workflow still calls the old names; next to `presentations`, `workbench` or `writing` it duplicates their triggers.

**Runtimes:** Claude Code, Codex

Not in Cursor: a frozen archive has no reason to reach a new runtime. See [Runtimes](/reference/runtimes.md).

**Source:** vendored in `plugins/deprecated/`; see the [plugin README](../../../plugins/deprecated/README.md) for details and credits. `frontend-design` is a port of the [frontend-design](https://github.com/anthropics/skills/tree/ef740771ac901e03fbca3ce4e1c453a96010f30a/skills/frontend-design) skill in Anthropic's `anthropics/skills` repository (Apache 2.0); see `plugins/deprecated/NOTICE`.

**Setup:** None beyond install.

## Skills

| Invocation                                | Moved from                           | Replacement                                                                             |
| ----------------------------------------- | ------------------------------------ | --------------------------------------------------------------------------------------- |
| `/deprecated:crafting-presentations`      | `workbench`                          | `/presentations:creating-presentations`                                                 |
| `/deprecated:perfecting-presentations`    | `workbench`                          | `/presentations:creating-presentations` (the review loop is an opt-in phase there)      |
| `/deprecated:exporting-decks-to-pptx`     | `workbench`                          | `/presentations:exporting-presentations-to-pptx`                                        |
| `/deprecated:presentations`               | `writing`                            | `/presentations:designing-presentations`                                                |
| `/deprecated:autopilot`                   | `workbench`                          | `/workbench:pilot` with `Gates: none`                                                   |
| `/deprecated:copilot`                     | `workbench`                          | `/workbench:pilot` with `Gates: design`                                                 |
| `/deprecated:dispatching-parallel-agents` | `workbench`                          | `/workbench:subagent-driven-development` (its parallel dispatch section)                |
| `/deprecated:terse-mode`                  | `workbench`                          | Retired without replacement                                                             |
| `/deprecated:writing`                     | `writing`                            | `/writing:ghostwrite` (drafting) and `/writing:coach` (learning to write)               |
| `/deprecated:pyramid`                     | `writing`                            | `/writing:ghostwrite` (pyramid audits) and `/writing:coach` (structure drill)           |
| `/deprecated:tech-doc`                    | `writing`                            | `/writing:ghostwrite` (tech docs from the repository)                                   |
| `/deprecated:frontend-design`             | the retired `frontend-design` plugin | `/taste-skill:taste-skill` in Claude Code, `taste-skill:design-taste-frontend` in Codex |

Why the archive exists and how a skill moves into it: [The deprecated archive](/explanation/the-deprecated-archive.md).
