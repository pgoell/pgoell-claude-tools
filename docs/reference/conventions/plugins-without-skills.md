---
type: Reference
title: Plugins without skills
description: The rules for output styles and for plugins that ship no skills.
tags: [conventions, plugins, output-styles, hooks]
status: stable
---

# Plugins without skills

Read this before you add an output style or a plugin that ships no skills. Reasons and history: [plugins-without-skills](/explanation/plugins-without-skills.md).

- **Output styles are a plugin surface, and a skill-less plugin is a valid shape.** Styles in `output-styles/*.md` set `keep-coding-instructions: true` when they only shape prose (or Claude Code drops its coding prompt). Each style file stands alone, so shared blocks are duplicated on purpose. A skill-less plugin registers in `.claude-plugin/marketplace.json` only, keeps a `.codex-plugin/plugin.json` without `skills` for the version check, gets no `docs/reference/skills.md` rows, and says in `docs/reference/runtimes.md` why Codex lacks it; every other docs site (including a setup how-to, since picking a style is setup), the lint, the version lockstep and strict YAML still apply. Add new prose styles to `prose-styles`, not a new plugin.
