---
type: Explanation
title: Ports and licenses
description: How a port from an upstream repository carries its license, which files each license shape needs, and why ports replace dashes.
tags: [ports, licensing, notice, attribution, contributors]
status: stable
---

# Ports and licenses

A port copies upstream files into this repository. The upstream license decides the paperwork the plugin ships with, so the first step of any port is to read the upstream `LICENSE` file itself. Secondary signals (a CONTRIBUTING.md, DCO mentions, a README badge, an agent's summary) can make a restricted or source-available license look permissive, and the wrong license shape spreads through every file the port adds. [Ports and licenses](/reference/conventions/ports-and-licenses.md) states the rules; this page keeps the reasons and the examples. For the plugins this applies to today, see [External and vendored plugins](/explanation/external-and-vendored-plugins.md).

## Upstream-port attribution

When a plugin ports a skill from a non-MIT upstream (such as Anthropic's Apache 2.0 `playground`), the plugin folder ships three files: `LICENSE` (this repo's MIT license), `NOTICE` (per-file upstream attribution and the original license), and a plugin `README.md` with a Credits section that links the source. The SKILL.md frontmatter drops upstream-only fields such as `license:`.

`NOTICE` records the upstream commit SHA. When the port fetches upstream content with `gh api`, it adds `?ref=<commit-sha>` so the fetch matches that SHA; without it the fetch reads the default branch, which may have moved. `plugins/playground/` is the model layout. `plugins/deprecated/` also ships `LICENSE`, `NOTICE` and a README Credits section for the archived `frontend-design` skill. Since deprecated 0.4.2 that `NOTICE` pins a commit of `anthropics/skills`, after its old link to `anthropics/claude-plugins` died. The same text also sat in `anthropics/claude-code` and `anthropics/claude-plugins-official`, but only `anthropics/skills` ships a `LICENSE.txt` (Apache 2.0) beside the skill, and the `LICENSE.md` of `claude-code` reserves all rights. The `LICENSE` file at the SHA picked the source.

The manifest `license:` says MIT, because the plugin's own additions (the SKILL.md changes, NOTICE, README) are MIT. The Apache-2.0 files stay under their own license, as `NOTICE` records.

## Upstream-port attribution, vendored-LICENSE variant

A second Apache-2.0 shape vendors the upstream LICENSE verbatim at `plugins/<plugin>/LICENSE` and declares that license in the manifest, instead of laying MIT over it. The `terminal` plugin uses it: Apache-2.0 LICENSE from `mitsuhiko/agent-stuff`, manifest `"license": "Apache-2.0"`. Use it when the upstream license already allows redistribution with attribution and the plugin's own additions (such as inline command patterns that replace helper scripts) can go out under the same license. `NOTICE` still maps each file, and the README still needs Credits.

Pick the MIT overlay when you want the additions plainly under MIT (playground); pick the vendored LICENSE when one license across all files keeps attribution simpler (terminal). Both are valid; `NOTICE` says which one the port chose, so a later re-port can follow it.

## Upstream with no declared license

If the upstream declares no license (the GitHub API reports `license: null`, no `LICENSE` file), do not relicense it and do not refuse the port. Vendor it verbatim and say in `NOTICE` that it has no license: record the commit SHA, the author's publishing intent (for example "distributed via `npx skills add <user>/<repo>` for AI agent use, per its README"), and that all rights to the text stay with the author. Mechanical changes such as the dash substitution add no authorship.

The `emil-design-eng` port was the only case. It went away in 2026-10, after the upstream adopted MIT and became the external `emil` plugin, so no live example remains; its old `NOTICE` text is in git history.

## Upstream with restricted-license upstream (use-scope restriction)

Some licenses limit use to a service or context. The Databricks License, for instance, allows use only "in connection with Databricks Services". For such an upstream, vendor its LICENSE verbatim at `plugins/<plugin>/LICENSE-upstream` and ship MIT at `plugins/<plugin>/LICENSE` for the plugin's own work. `NOTICE` holds:

- the upstream commit SHA;
- the license name and its key limit, stated in one plain sentence so a casual reader sees it;
- the dash substitution rules applied at port time;
- the per-file mapping (upstream path to local path);
- which files are original work under MIT.

The plugin README's Credits section names the limit, so users know what they accept by installing. The `databricks` plugin (`databricks-core`, ported from `databricks/databricks-agent-skills` at commit `bf6d932`) is the model.

This shape differs from the Apache-2.0 one in three ways. The upstream LICENSE sits beside MIT instead of being replaced. `NOTICE` states the limit in plain English. And the port removes cross-references to upstream skills that were not also ported, or the body would point at skills this marketplace lacks.

The manifest `license:` (in both `.claude-plugin/plugin.json` and `.codex-plugin/plugin.json`) describes only the plugin's own work, so `databricks` declares `"license": "MIT"` though most of its bytes fall under the Databricks License. Do not change the field to the upstream license, and do not drop MIT because most of the plugin is vendored. `NOTICE` and `LICENSE-upstream` document the limit.

## Idea adaptation ("steal like an artist") is distinct from a verbatim port

A plugin that rebuilds an upstream idea (for example from an unlicensed gist) in this repo's own words, copying no upstream text, is original MIT work, not a port. It ships MIT `LICENSE` and a README with an `## Inspiration` (or Credits) section that links the source and names the author, and no `NOTICE` or `LICENSE-upstream`: there are no copied files to map and no dashes to substitute.

The `learning` plugin (`quizzing-the-session`, `quizzing-a-topic`), adapted from Thariq Shihipar's "Learn Quiz" gist, is the model. Its SKILL.md bodies are rewritten, not copied. Choose this shape only when you truly rewrote the content: once you paste upstream text it is a port, and the port rules apply.

## Verbatim ports must substitute em-dashes/en-dashes inline at port time

The repo bans U+2014 and U+2013 (see [Repository conventions](/explanation/repo-conventions.md)), so a verbatim port replaces them before commit. Five rules have served across the `emil-design-eng` (removed in 2026-10), `playground`, and `databricks-core` ports:

1. A sentence pause, `<space>U+2014<space>`, becomes a comma and space.
2. A labelled bullet, `**name** U+2014 description`, becomes a colon and space, which keeps the list's feel.
3. A number range, `<digit>U+2013<digit>` (such as `0-24px`, `1-500`), becomes a hyphen.
4. A heading that splits title from subtitle, `## Title U+2014 Subtitle`, becomes a colon and space, as in `## Data Exploration: Use AI Tools`.
5. A dash inside a fenced code block, typically a bash comment `# Label U+2014 Description`, becomes a colon and space, as in `# Unity Catalog: POSITIONAL arguments`.

Periods, semicolons, parentheses, or a split sentence are fine where the context calls for them. Each port's `NOTICE` records the rules it applied, so a later diff against upstream can be repeated; `plugins/playground/NOTICE` and `plugins/databricks/NOTICE` show the wording. The Anthropic `frontend-design` port (archived in `deprecated` since 0.4.0) records no such clause. Its `NOTICE` records that the upstream file at the pinned commit holds neither character, so no clause applies. The right arrow (U+2192) and other punctuation the lint does not flag stay as they are.
