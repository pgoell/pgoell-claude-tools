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
| `taste-skill` | [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill)         | Claude Code and Codex |
| `vercel`      | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) | Claude Code           |

All four are MIT licensed. This shape fits when an upstream is permissive and you want its whole surface (skills, commands, hooks) as its author ships it, not a copy of the skill text.

None of the entries pins a commit or a version. When you refresh the marketplace you get whatever the upstream's `main` holds that day. That has three consequences:

- You get fixes and new skills without waiting for a release here.
- Code you have not reviewed runs on your machine after a refresh. `ponytail`, for example, ships hooks that run in every session. If that matters to you, read the upstream change before you update.
- This repository's rules (the dash lint, the version lockstep, the frontmatter checks) do not cover upstream files, because none are copied here.

`emil` and `vercel` are Claude Code only: they ship no plugin manifest at all. `taste-skill` shipped no Codex manifest when it was added; upstream added one on 2026-10-13, and the Codex marketplace has listed it since 2026-10-18.

## Ports with attribution

A port copies upstream files into this repository and records where they came from. The upstream license decides the paperwork: a `LICENSE`, a `NOTICE` that maps each copied file to its source and commit, and a Credits section in the plugin's README.

- [`playground`](../../plugins/playground/NOTICE): from Anthropic's playground plugin, Apache 2.0, with this repository's MIT license for its own additions.
- [`terminal`](../../plugins/terminal/NOTICE): the tmux skill from Armin Ronacher's agent-stuff, Apache 2.0. The plugin ships the upstream license itself and declares Apache-2.0.
- [`databricks`](../../plugins/databricks/NOTICE): `databricks-core` from databricks/databricks-agent-skills under the Databricks License, which allows use only in connection with Databricks services. The upstream license sits in `LICENSE-upstream` beside MIT. By installing the plugin you accept that limit for that skill.
- [`diagrams`](../../plugins/diagrams/NOTICE): vendors the archify engine (MIT) and adapts design values from Cocoon AI's architecture diagram generator (MIT).
- [`workbench`](../../plugins/workbench/NOTICE): forked from Jesse Vincent's Superpowers 5.0.7, MIT. The `crafting-html` reference examples come from Thariq Shihipar's html-effectiveness gallery (commit 5d64f68), which declared no license at that commit; the `NOTICE` states the author's publishing intent and that all rights stay with the author.
- [`agent-system-management`](../../plugins/agent-system-management/NOTICE): `improving-instructions` and `capturing-session-learnings` from Anthropic's claude-md-management plugin, and `creating-skills`, with its eval viewer, from Anthropic's skill-creator skill, both Apache 2.0. Smaller parts of `creating-skills` adapt MIT skills by Matt Pocock, Jesse Vincent and swyx.
- [`deprecated`](../../plugins/deprecated/NOTICE): carries the archived `frontend-design` skill, an Anthropic Apache 2.0 port, with its attribution.

Ports also replace em-dashes and en-dashes with other punctuation, and each `NOTICE` lists the substitutions made, so a later diff against upstream can be repeated.

When a ported skill's upstream later becomes a permissive repository with its own plugin, the port gives way to an external entry. That happened with `emil`.

Which files each license shape needs, and why, is in [Ports and licenses](/explanation/ports-and-licenses.md). [External and deprecated plugins](/reference/conventions/external-and-deprecated-plugins.md) states the rules in short.

## External plugins are referenced by git URL, not vendored

A marketplace entry may point at an upstream repo instead of a local `plugins/<name>/` folder. Both runtimes support this. Claude Code accepts `github`, `url`, `git-subdir`, and `npm` source objects; Codex accepts `url` (plugin at the repo root) and `git-subdir` (plugin in a subfolder); each takes optional `ref` and `sha` pins.

`ponytail` (2026-08, `DietrichGebert/ponytail`, MIT) was the first: `{"source": "url", "url": "https://github.com/DietrichGebert/ponytail.git"}` in both marketplace files, unpinned on purpose so `/plugin marketplace update` tracks upstream `main`. Choose this shape over a port when the upstream is permissively licensed, ships a plugin manifest at its repo root for both runtimes, and you want its whole surface (skills, commands, hooks), not just the skill bodies.

Four consequences:

1. Both CI checks skip the entry. `check-plugin-versions` builds its work list from `git diff -- plugins/`, and `validate-plugin-schema` globs `plugins/*/.codex-plugin/plugin.json`. So no version lockstep applies, and the marketplace entry carries no `version` field (a pinned number would go stale on every upstream release).
2. This repo's conventions do not govern upstream bytes. The dash lint, the shipped-code rule, and the frontmatter rules apply only to files vendored here.
3. The port attribution files (`LICENSE`, `NOTICE`, README Credits) do not apply, because nothing is copied. The plugin's page under `docs/reference/plugins/` still names the upstream and its license.
4. Unpinned means upstream code runs on refresh without review. That is a supply-chain choice to make on purpose; pinning with `sha` is the remedy when it matters.

The docs sites for a new plugin still apply, minus any `plugins/<name>/README.md`, since there is no local folder.

Two later entries (2026-10) broke the both-runtimes condition and went into `.claude-plugin/marketplace.json` only, with [Runtimes](/reference/runtimes.md) saying why, the same shape `prose-styles` uses. `taste-skill` (`Leonxlnx/taste-skill`, MIT, added for trial) shipped only `.claude-plugin/plugin.json`. Upstream added `.codex-plugin/plugin.json` on 2026-10-13, so on 2026-10-18 it joined `.agents/plugins/marketplace.json` as well. `emil` (`emilkowalski/skill`, MIT) ships no manifest at all, so its entry sets `"strict": false`: the marketplace entry serves as the manifest and Claude Code finds `skills/` by convention. A third, `vercel` (`vercel-labs/agent-skills`), has the same no-manifest shape. Its license is MIT per the repo README and skill frontmatter, with no `LICENSE` file; that is fine for a linked plugin because nothing is vendored, but a port would need the LICENSE file read first.

Claude Code names a plugin skill after its folder, not its frontmatter `name:`. This was checked at install: taste-skill's `skills/taste-skill/` with `name: design-taste-frontend` loads as `taste-skill:taste-skill`. So docs name external skills by folder. Codex takes the frontmatter `name:` instead: an install on 2026-10-18 showed the same skill as `taste-skill:design-taste-frontend`. So the taste-skill page lists the Codex names beside the Claude Code ones. Upstream skills with `disable-model-invocation: true` (three in `emil`) run only as slash commands.

`emil` replaced a vendored copy of `emil-design-eng` in the `frontend-design` plugin, which then retired; its Anthropic skill went to `deprecated` 0.4.0, superseded by `taste-skill:taste-skill` (in Codex, `taste-skill:design-taste-frontend`). Prefer this swap whenever a vendored port's upstream becomes a permissively licensed repo.
