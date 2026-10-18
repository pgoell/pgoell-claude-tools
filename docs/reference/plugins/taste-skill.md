---
type: Reference
title: The taste-skill plugin
description: Frontend design skills against generic AI-looking UI, tracked from upstream for trial.
tags: [plugin, taste-skill, upstream, frontend, design]
status: stable
---

# taste-skill

Frontend design skills against generic "AI slop" UI: taste-driven landing pages and portfolios, redesign audits, style variants, and image-first workflows that generate a design reference before writing code. Added for trial.

**Runtimes:** Claude Code

Not in Codex or Cursor: it is registered in the Claude Code marketplace only, and Cursor manifests here come only from local plugin directories. See [Runtimes](/reference/runtimes.md).

**Source:** upstream, not vendored: tracks [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill) `main` unpinned (MIT).

**Setup:** None beyond install.

## Skills

| Invocation                                 | What it does                                                                                         |
| ------------------------------------------ | ---------------------------------------------------------------------------------------------------- |
| `/taste-skill:taste-skill`                 | The main skill (v2). Reads the brief, infers a design direction, and builds the page.                |
| `/taste-skill:taste-skill-v1`              | The original v1, frozen for projects that depend on its exact behavior.                              |
| `/taste-skill:taste-skill-v2-experimental` | The earlier experimental v2, kept for projects that depend on it.                                    |
| `/taste-skill:gpt-tasteskill`              | A variant tuned for GPT and Codex models.                                                            |
| `/taste-skill:redesign-skill`              | Audits an existing project for generic patterns and upgrades its design without breaking behavior.   |
| `/taste-skill:output-skill`                | Forces complete output: no placeholders, no truncation.                                              |
| `/taste-skill:minimalist-skill`            | Style variant: editorial minimalist.                                                                 |
| `/taste-skill:soft-skill`                  | Style variant: soft premium agency.                                                                  |
| `/taste-skill:brutalist-skill`             | Style variant: Swiss brutalist.                                                                      |
| `/taste-skill:image-to-code-skill`         | Generates a design reference image, then builds from it. Needs an image-generation tool in the host. |
| `/taste-skill:imagegen-frontend-web`       | Generates web design reference images. Needs an image-generation tool.                               |
| `/taste-skill:imagegen-frontend-mobile`    | Generates mobile design reference images. Needs an image-generation tool.                            |
| `/taste-skill:brandkit`                    | Generates a brand kit as reference images. Needs an image-generation tool.                           |
| `/taste-skill:stitch-skill`                | Writes a Google Stitch compatible `DESIGN.md`.                                                       |

Claude Code names each skill after its directory, not its frontmatter `name:`, so `skills/taste-skill/` loads as `taste-skill:taste-skill`. It overlaps with [emil](/reference/plugins/emil.md), and replaces the retired `frontend-design` plugin, whose skill is archived in [deprecated](/reference/plugins/deprecated.md).
