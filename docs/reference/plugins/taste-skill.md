---
type: Reference
title: The taste-skill plugin
description: Frontend design against generic AI-looking UI, tracked from upstream for trial.
tags: [plugin, taste-skill, upstream, frontend, design]
status: stable
---

# taste-skill

Frontend design against generic "AI slop" UI: one skill that deals a researched art direction, builds or redesigns a page or app screen from it, and checks the result in a real browser. Upstream folded its former style variants and `redesign-skill` into this skill, and moved its image skills to [Leonxlnx/imagegen-skills](https://github.com/Leonxlnx/imagegen-skills). Added for trial.

**Runtimes:** Claude Code, Codex

Not in Cursor: this marketplace's Cursor manifests are generated from local plugin directories, and taste-skill has none here. See [Runtimes](/reference/runtimes.md).

**Source:** upstream, not vendored: tracks [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill) `main` unpinned (MIT).

**Setup:** None beyond install.

## Skills

| Invocation                 | Name in Codex                       | What it does                                                                                         |
| -------------------------- | ----------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `/taste-skill:taste-skill` | `taste-skill:design-taste-frontend` | Builds or redesigns a page or app screen from a researched art direction and checks it in a browser. |

Claude Code names each skill after its directory, not its frontmatter `name:`, so `skills/taste-skill/` loads as `taste-skill:taste-skill`. Codex names each skill after its frontmatter `name:` instead, which gives the second column. It overlaps with [emil](/reference/plugins/emil.md) and [unslop](/reference/plugins/unslop.md), and replaces the retired `frontend-design` plugin, whose skill is archived in [deprecated](/reference/plugins/deprecated.md).
