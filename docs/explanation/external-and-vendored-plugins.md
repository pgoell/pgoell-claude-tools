---
type: Explanation
title: External and vendored plugins
description: The difference between plugins kept in this repository and entries that point at an upstream repository, and what each means for you as a user.
tags: [upstream, licensing, ports, ponytail, emil, taste-skill, vercel]
status: stable
---

# External and vendored plugins

The marketplace lists two kinds of plugin. Most live in this repository under `plugins/<name>/`. Four are only an entry in the marketplace file that points at someone else's repository.

## Vendored plugins

A vendored plugin's files sit in this repository. Every change to it goes through a pull request here, bumps its version, and passes the checks in CI. When you install it you get the files as they were at the commit your marketplace points to.

## External plugins

`ponytail`, `emil`, `taste-skill` and `vercel` have no folder under `plugins/`. Their marketplace entries hold a git URL:

| Plugin        | Upstream                                                                | Runtimes              |
| ------------- | ----------------------------------------------------------------------- | --------------------- |
| `ponytail`    | [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail)   | Claude Code and Codex |
| `emil`        | [emilkowalski/skill](https://github.com/emilkowalski/skill)             | Claude Code           |
| `taste-skill` | [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill)         | Claude Code           |
| `vercel`      | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) | Claude Code           |

All four are MIT licensed. This shape fits when an upstream is permissive and you want its whole surface (skills, commands, hooks) as its author ships it, not a copy of the skill text.

None of the entries pins a commit or a version. When you refresh the marketplace you get whatever the upstream's `main` holds that day. That has three consequences:

- You get fixes and new skills without waiting for a release here.
- Code you have not reviewed runs on your machine after a refresh. `ponytail`, for example, ships hooks that run in every session. If that matters to you, read the upstream change before you update.
- This repository's rules (the dash lint, the version lockstep, the frontmatter checks) do not cover upstream files, because none are copied here.

`emil`, `taste-skill` and `vercel` are Claude Code only. `emil` and `vercel` ship no plugin manifest at all; `taste-skill` shipped none for Codex when it was added, and upstream has added one since without the marketplace registering it.

## Ports with attribution

A port copies upstream files into this repository and records where they came from. The upstream license decides the paperwork: a `LICENSE`, a `NOTICE` that maps each copied file to its source and commit, and a Credits section in the plugin's README.

- [`playground`](../../plugins/playground/NOTICE): from Anthropic's playground plugin, Apache 2.0, with this repository's MIT license for its own additions.
- [`terminal`](../../plugins/terminal/NOTICE): the tmux skill from Armin Ronacher's agent-stuff, Apache 2.0. The plugin ships the upstream license itself and declares Apache-2.0.
- [`databricks`](../../plugins/databricks/NOTICE): `databricks-core` from databricks/databricks-agent-skills under the Databricks License, which allows use only in connection with Databricks services. The upstream license sits in `LICENSE-upstream` beside MIT. By installing the plugin you accept that limit for that skill.
- [`diagrams`](../../plugins/diagrams/NOTICE): vendors the archify engine (MIT) and adapts design values from Cocoon AI's architecture diagram generator (MIT).
- [`deprecated`](../../plugins/deprecated/NOTICE): carries the archived `frontend-design` skill, an Anthropic Apache 2.0 port, with its attribution.

Ports also replace em-dashes and en-dashes with other punctuation, and each `NOTICE` lists the substitutions made, so a later diff against upstream can be repeated.

When a ported skill's upstream later becomes a permissive repository with its own plugin, the port gives way to an external entry. That happened with `emil`.

The full rules are in the design decisions of [AGENTS.md](../../AGENTS.md).
