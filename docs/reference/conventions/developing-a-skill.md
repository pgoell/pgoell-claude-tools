---
type: Reference
title: Developing a skill
description: The steps to add a skill or plugin, the SKILL.md layout, the docs sites a new plugin or skill updates, and when a skill may ship code.
tags: [conventions, skills, plugins, contributing]
status: stable
---

# Developing a skill

Read this before you add a skill or a plugin, or before a skill ships code. The rules that apply to every task stay in [AGENTS.md](../../../AGENTS.md).

## How to Develop a New Skill

> **Tip:** `agent-system-management:creating-skills` automates this workflow (scaffolding, eval loops, pressure tests, description tuning). The steps below remain the canonical reference.

### 1. Plan the skill

- Identify the CLI tool or API the skill wraps.
- Call the CLI or `curl` directly in the skill. No wrapper scripts around an existing CLI; shipped code is allowed only when it does real work (see the "Skills may ship code" Design Decision), and a skill may tell the agent to write a one-off script at runtime.
- Define operation tiers: Tier 1 (Read), Tier 2 (Write), Tier 3 (Manage/Admin).

### 2. Create the plugin structure

To add to an existing plugin, add `skills/<service>/`. For a new plugin, create `plugins/<plugin-name>/.claude-plugin/plugin.json`:

```json
{
  "name": "<plugin-name>",
  "version": "0.1.0",
  "description": "<one-line description>",
  "author": { "name": "Pascal Göllner" },
  "license": "MIT",
  "keywords": ["<relevant>", "<keywords>"]
}
```

and `.codex-plugin/plugin.json`, which must point at the shared skills folder:

```json
{
  "name": "<plugin-name>",
  "version": "<same-version-as-claude-plugin>",
  "description": "<one-line description>",
  "author": { "name": "Pascal Göllner" },
  "license": "MIT",
  "keywords": ["<relevant>", "<keywords>"],
  "skills": "./skills/",
  "interface": {
    "displayName": "<Plugin Display Name>",
    "shortDescription": "<short human-facing description>",
    "longDescription": "<long human-facing description>",
    "developerName": "Pascal Göllner",
    "category": "Productivity",
    "capabilities": ["Interactive", "Write"],
    "defaultPrompt": ["<starter prompt>"],
    "screenshots": []
  }
}
```

Register the plugin in both marketplaces: `.claude-plugin/marketplace.json` (Claude Code) and `.agents/plugins/marketplace.json` (Codex; each entry must include `interface.displayName` and `interface.shortDescription`). Then run `mise run sync-cursor-manifests` for Cursor. A plugin with no `skills/` yet stays unregistered (see "Unregistered plugin directories" in [Skill design patterns](/reference/conventions/skill-design-patterns.md)).

### 3. Write SKILL.md

Both Claude Code and Codex read it. Follow this structure:

```markdown
---
name: <service>
description: Use when the user wants to <what this skill does>
---

# <Service> Skill

<One-line description>

---

## Auth Approach

<Lazy auth: do not check upfront, just run the command. Diagnose auth failures in Self-Healing>

## Tool Preference

<What tools to use and in what priority order>

## Operations: Tier 1 (Read)

<Read-only operations with exact commands>

## Operations: Tier 2 (Write)

<Create/update operations with exact commands>

## Operations: Tier 3 (Manage)

<Admin/destructive operations with exact commands>

## Self-Healing

<What to do when commands fail (help flags, schema inspection, error codes)>

## Behavioral Guidelines

<How Claude should infer intent and pick operations>
```

Key principles:

- **Exact commands.** Copy-pasteable commands, not pseudocode.
- **Auth is lazy.** Run the operation first, diagnose auth failures in Self-Healing. Never print credential values.
- **Prefer helpers over raw API** when the CLI has convenience commands.
- **Confirm before destructive ops.** Always ask before deleting.
- **Platform-aware tool names.** When a skill uses orchestration tools, include a short Claude Code and Codex mapping instead of hardcoding one runtime.
- **Self-healing is critical.** Tell the agent how to debug failures.

### 4. Add reference docs

Put query syntaxes, format references, recipes, or HTML templates in reference files, linked from SKILL.md as `See <filename>` or `See references/<filename>`. Two layouts coexist:

- **Flat** (`<service>-<topic>.md` next to `SKILL.md`): legacy, used by `gmail`, `calendar`, `claude-codex-bridge`, `running-research`, `visualizing-options`, and `databricks-core`. Fine for one or two short files. Verbatim ports keep the upstream layout; never refactor a port into `references/`, because that breaks the per-file `NOTICE` mapping.
- **`references/` subdirectory**: the modern convention and the choice for new skills. Required when a skill bundles HTML templates, several long references, or any non-markdown asset.

No authored file may pass 5000 tokens (bytes/4); `mise-tasks/check-file-size` checks it on commit, on push and in CI; the check ships as the [file-size](/reference/plugins/file-size.md) plugin. A new `SKILL.md` starts under the limit. When one grows past it, move step detail into `references/` and link each file from the step that needs it. Split along a deep module (a small interface over much hidden detail), never by line count or into files that only point onward.

### 5. Update docs and AGENTS.md

The README is a front page; the docs live in `docs/`. A new plugin updates, in one commit:

1. `README.md`: one line under `## Plugins` linking the plugin's reference page, and the plugin count in the first paragraph.
2. `docs/reference/plugins/<name>.md`, plus entries in `docs/reference/plugins/index.md`, `docs/reference/skills.md` (`docs/reference/upstream-skills.md` for an external git-URL entry) and `docs/reference/runtimes.md`.
3. A setup how-to under `docs/how-to/`, listed in `docs/how-to/index.md`, only if the plugin needs setup (no page means no setup).
4. The `README.md` install notes, only if the install command differs from the usual one.
5. A new log file under `docs/log/`, named and written as [log.md](/log.md) says.
6. A line in AGENTS.md "Current Plugins".

Then run `mise run sync-cursor-manifests`, or add the plugin to that task's `EXCLUDE` list with a reason. These sites come on top of the version-bump sites (AGENTS.md "Every plugin change bumps version"), in the same commit.

A new skill in an existing plugin updates `docs/reference/plugins/<plugin>.md`, `docs/reference/skills.md` (`docs/reference/upstream-skills.md` for an external git-URL entry), and adds a log file under `docs/log/`, plus one site nothing tests: the plugin's own `README.md` `## Skills` list (if it has one). Check it by hand.

## Skills may ship code

Reasons and history: [repo-conventions](/explanation/repo-conventions.md).

- **Skills may ship code; wrappers around an existing CLI stay banned.** A service skill calls its CLI (`gws`) or raw `curl` with env-var auth (Atlassian) directly. Ship code only for work prose cannot do reliably (layout, geometry validation, rendering, deterministic checks), and only if it (1) runs on a runtime the host has (Node 18+, Python through `uv`) with no install step, dependencies absent or committed; (2) makes no network request at runtime except for an action the user asks for (ports drop update notifiers and telemetry); (3) is driven from `SKILL.md` with exact commands and a fallback for hosts without the runtime; (4) follows the text conventions: dash lint (in string literals, write a backslash-u escape of U+2014 or U+2013, not the character), `NOTICE` attribution, version lockstep. A port runs the upstream test suite on the changed copy and records the result in `NOTICE`. Runtime codegen (the agent writes fresh code per run, as in `exporting-presentations-to-pptx`) is preferred when code must differ per run. Script templates copied into the user's space (issue-loop `assets/*.sh`) are allowed; shipped scripts that can run without a live service get a test beside them (`tests/run.sh`, stub driver, no network) with the last result in the plugin README.
