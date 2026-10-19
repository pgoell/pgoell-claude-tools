---
type: Reference
title: The workbench plugin
description: The workflow skills for design, planning, test-first coding, debugging and shipping, with their config files and output paths.
tags: [plugin, workbench, pilot, workflow, html]
status: stable
---

# workbench

Workflow skills for taking a change from idea to pull request: triage, design dialogue, spec and plan, test-first implementation with subagents, debugging, verification, and HTML artifacts. `pilot` strings them together into one run with the human gates you choose.

**Runtimes:** Claude Code, Codex, Cursor

**Source:** vendored in `plugins/workbench/`; see the [plugin README](../../../plugins/workbench/README.md) for details and credits.

**Setup:** None beyond install.

**Upgrading from autopilot or copilot:** [Move to workbench pilot](/how-to/move-to-workbench-pilot.md)

## Skills

One skill sets `disable-model-invocation: true`, so it runs only when you type the slash command: `/workbench:pilot`.

| Invocation                                  | What it does                                                                                                                                                                                                     |
| ------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/workbench:using-workbench`                | Load the workbench rules and pick the right skill. Triages every task into the quick, medium or large lane, lighter lane when unsure.                                                                            |
| `/workbench:pilot`                          | Ship a feature end to end, from design through PR, driven by the `.workbench/pilot.md` profile. Replaces `autopilot` and `copilot`.                                                                              |
| `/workbench:brainstorming`                  | Question you one point at a time until you share a design concept. Hands off to `writing-spec` in the large lane, or to the design preamble of `writing-plans` in the medium lane.                               |
| `/workbench:writing-spec`                   | Write the design discussion into a spec, have a fresh subagent review it, wait for your approval, then hand off to `writing-plans`.                                                                              |
| `/workbench:writing-plans`                  | Turn an approved spec into a slice-ordered plan with exact file paths, signatures, test commands and acceptance criteria, which a fresh agent can execute.                                                       |
| `/workbench:visualizing-options`            | Show design options in the browser (mockups, layout comparisons, wireframes, architecture diagrams) from a local server, and let you click to choose.                                                            |
| `/workbench:test-driven-development`        | Enforce test-first RED-GREEN-REFACTOR before any implementation code.                                                                                                                                            |
| `/workbench:subagent-driven-development`    | Execute a plan with fresh subagents per task and two review gates, including parallel dispatch across independent tasks. The main session runs each brief's verification commands itself before review.          |
| `/workbench:systematic-debugging`           | Find the root cause before proposing a fix. Bundles notes on tracing back up the stack, defense in depth, and waiting on conditions instead of timeouts.                                                         |
| `/workbench:verification-before-completion` | Require fresh evidence (a command run now, its output read) before claiming work is done, fixed or ready to merge.                                                                                               |
| `/workbench:crafting-html`                  | Build a standalone HTML artifact that no other skill covers: PR walkthroughs, code explainers, slide decks, status and incident reports, prototypes, editing tools. Bundles 20 reference examples plus an index. |
| `/workbench:crafting-design-systems`        | Create or edit a design system (CSS variable overrides, optional components and images) that themes the HTML the other skills produce.                                                                           |

## Session hook

A `SessionStart` hook injects the full `using-workbench` skill into every session on startup, `/clear` and compaction, so triage runs without being invoked.

## pilot gates

The `Gates:` row in `.workbench/pilot.md` sets where pilot stops for you. A phrase in the prompt overrides it for one run.

| Value            | Behavior                                                                              | Prompt phrase           |
| ---------------- | ------------------------------------------------------------------------------------- | ----------------------- |
| `none`           | Fully autonomous (the old autopilot).                                                 | "auto mode", "no gates" |
| `design`         | You drive the brainstorm and approve the spec; the rest runs alone (the old copilot). | "co mode"               |
| `slices`         | Pause after each slice to review its diff.                                            |                         |
| `design, slices` | Both. The default when the row is absent.                                             |                         |

Profile schema: [profile-schema.md](../../../plugins/workbench/skills/pilot/references/profile-schema.md).

## Output formats and paths

`writing-spec`, `writing-plans`, `brainstorming` and `systematic-debugging` can write markdown or HTML. An optional `.workbench/config.md` at the repo root overrides the defaults; a phrase in the prompt overrides the file. Spec and plan paths can also come from `## Documentation paths` in `.workbench/pilot.md`.

| Artifact             | Default format | Default path               |
| -------------------- | -------------- | -------------------------- |
| Specs                | md             | `.workbench/specs`         |
| Plans                | md             | `.workbench/plans`         |
| Brainstorm summaries | html           | `.workbench/brainstorms`   |
| Debug reports        | html           | `.workbench/debug-reports` |

File names follow `YYYY-MM-DD-<topic>-<artifact>.<ext>`. Config schema: [config-schema.md](../../../plugins/workbench/skills/pilot/references/config-schema.md).

## Design systems

`crafting-design-systems` saves a design system at project scope, `.workbench/design-systems/<name>/`, or user scope, `~/.claude/workbench/design-systems/<name>/`; the project one wins on a name clash. Name the active one in the prompt or under `## Design system` in `.workbench/config.md`. The four skills above, `crafting-html` and `/research:research` then inline it over their template defaults. Each follows the steps in `crafting-design-systems`' `references/applying-a-design-system.md`. Slide decks use [presentations](/reference/plugins/presentations.md) presets instead.

## Licence

The plugin is MIT. Several skills and the session hook derive from Jesse Vincent's [Superpowers](https://github.com/obra/superpowers) 5.0.7 (MIT). The `crafting-html` gallery is vendored from `ThariqS/html-effectiveness`, which declares no licence. Workbench is built to run beside Superpowers; when a skill name exists in both, prefer the workbench one.
