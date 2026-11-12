---
type: How-to Guide
title: Install with the skills CLI
description: Install this repository's skills into Claude Code, Codex, Cursor, OpenCode and other agents with npx skills or bunx skills.
tags: [install, skills-cli, npx, bun, agents]
status: stable
---

# Install with the skills CLI

The [`skills` CLI](https://github.com/vercel-labs/skills) copies skills into the folder each agent reads, for about 80 agents, among them Claude Code, Codex, Cursor, OpenCode, Windsurf, Goose and Gemini CLI. It reads `.claude-plugin/marketplace.json`, so it finds every skill in this repository without extra setup. Use it for an agent this repository has no marketplace for, or when you want the skills without the plugin system.

It installs skills only. Hooks (`guards`, `session-title`), output styles (`prose-styles`) and the five upstream entries (`ponytail`, `emil`, `taste-skill`, `vercel`, `unslop`) do not come with it; install the upstream ones from their own repositories. Skills run under their bare names, so `/research:research` becomes the `research` skill.

## Pick a runner

Either works:

```
npx skills add pgoell/pgoell-claude-tools
bunx skills add pgoell/pgoell-claude-tools
```

`npx` needs Node 22.20 or later. With no flags the CLI asks which skills and which agents you want, and shows the skills grouped by plugin.

## Install a whole plugin

Some skills read files from a sibling skill in the same plugin (the presentations skills read each other's references; `news:edition` and `news:feedback` share rules). Install every skill of a plugin together so those links resolve. The CLI has no plugin filter, so name the skills:

```
npx skills add pgoell/pgoell-claude-tools --skill research --skill running-research
npx skills add pgoell/pgoell-claude-tools --skill edition --skill feedback --skill tune
```

[Skills](/reference/skills.md) lists each plugin's skills. To see what the CLI finds, add `--list`.

## Choose agents and scope

- `-a <agent>` picks the agent, for example `-a codex` or `-a opencode`. Repeat it for several. `--agent '*'` picks every supported agent.
- Without `-g` the skills go into the current project (`.agents/skills/` for most agents, plus a `skills-lock.json`). With `-g` they go into your home folder and work in every project.
- `-y` skips the prompts. `--copy` copies files instead of linking them from one shared copy.

```
bunx skills add pgoell/pgoell-claude-tools --skill creating-diagrams -a codex -a opencode -g -y
```

## What the CLI hides

Two sets of skills are marked `internal` and do not show up by default:

- The archived skills in `deprecated`, which are superseded or retired.
- The `issue-loop` skills, which drive Claude Code sessions and run nowhere else.

To see them anyway, set `INSTALL_INTERNAL_SKILLS=1` before the command.

## Known gap: presentations presets

The presentations skills read brand presets from `plugins/presentations/presets/`, a folder beside the skills that the CLI does not copy. Installed this way, they find no bundled preset. A local preset in `.pgoell/presentations/presets/` still works. The plugin is being rebuilt; until then, install it through a marketplace (Claude Code, Codex or Cursor) if you need the bundled presets.

## Update or remove

`npx skills update` pulls new versions of what you installed; `npx skills remove <skill>` takes one out. Both work with `bunx` too.
