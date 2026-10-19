---
type: Reference
title: External and deprecated plugins
description: How to register an upstream plugin by git URL, and how to move a superseded skill into the deprecated archive.
tags: [conventions, plugins, upstream, deprecated]
status: stable
---

# External and deprecated plugins

Read this before you add or change a git-URL marketplace entry, or before you retire a skill. Reasons and history: [external-and-vendored-plugins](/explanation/external-and-vendored-plugins.md), [the-deprecated-archive](/explanation/the-deprecated-archive.md).

- **External plugins are referenced by git URL, not vendored.** A marketplace entry may point at an upstream repo (`{"source": "url", "url": "https://github.com/<owner>/<repo>.git"}`; Claude Code also takes `github`, `git-subdir`, `npm`; Codex takes `url`, `git-subdir`; both allow `ref`/`sha` pins). Use it for a permissively licensed upstream whose whole surface you want. The entry has no `version`, no version lockstep, no CI check, no `LICENSE`/`NOTICE`/Credits, and this repo's lint and frontmatter rules do not apply to its files; its `docs/reference/plugins/` page still names the upstream and license, and the other new-plugin docs sites apply (no plugin README; its skill rows go in `docs/reference/upstream-skills.md`). Unpinned means unreviewed upstream code runs on refresh; pin with `sha` when that matters. An upstream with no Codex manifest is registered for Claude Code only, with the reason in `docs/reference/runtimes.md`; one with no manifest at all sets `"strict": false`. Once an upstream ships `.codex-plugin/plugin.json`, read it and its `LICENSE` at a pinned SHA and add it to `.agents/plugins/marketplace.json` too (`taste-skill`). Document external skills by folder name, which is what Claude Code uses, not frontmatter `name:`; Codex uses the frontmatter `name:`, so a plugin page for a Codex-registered upstream also lists the Codex name where the two differ (`taste-skill`). When a vendored port's upstream turns into a permissive plugin repo, swap the port for an external entry.
- **The `deprecated` plugin is a registered, frozen archive.** When a restructure supersedes a skill, move it (SKILL.md plus references) to `plugins/deprecated/skills/<old-name>/` in the same PR that removes it, prefix its description with "Deprecated, superseded by <replacement>.", add a one-line banner under the H1 naming the replacement, rewrite internal cross-references to `deprecated:`, and drop or de-brand assets that must not ship. Move an archived port's `NOTICE` block with it. Never extend a deprecated skill; do not list them in `docs/reference/skills.md`; keep the plugin registered in both marketplaces.
