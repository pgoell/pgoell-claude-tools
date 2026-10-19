---
type: Explanation
title: Workbench routing and configuration
description: Why workbench picks the lighter lane by default, how optional required-skill rows work, and how workbench skills resolve format, path and design system.
tags: [workbench, triage, pilot, configuration, contributors]
status: stable
---

# Workbench routing and configuration

Workbench decides how much process a task gets and where its artifacts land. [Workbench routing and configuration](/reference/conventions/workbench-routing.md) states the rules; this page keeps the reasons and the history.

## Lane triage defaults to the lighter lane, and a reflex ladder runs before routing

Workbench 1.1.0 turned round the tiebreak in `workbench:using-workbench`. Through 1.0.0 the rule was "when unsure between two lanes, pick the heavier one", taken from the upstream superpowers framing. It is now "pick the lighter one". Escalation needs a named, concrete reason: a decision that is expensive to reverse, blast radius beyond the files in front of you, real disagreement about intent, or a requirement that cannot be stated in one sentence without guessing.

Two exceptions outrank the lighter default, because they guard against outcomes that cannot be undone rather than wasted effort. A user who asks for a spec, plan, or brainstorm by name never gets downgraded. Destructive or hard-to-reverse work (migrations, deletions, auth changes, public API breaks, money, credentials) routes heavy whatever the diff size.

Triage step 0 runs the six-rung reflex ladder (YAGNI, reuse, stdlib, native platform, installed dependency, one-liner) before any lane is chosen. If a rung holds, the task gets no lane at all. `workbench:pilot` mirrors both changes and logs an escalation on any other grounds as a deviation. The ladder is written into workbench, not cross-referenced, so it still runs when the optional `ponytail` plugin is missing.

This is the one place workbench breaks from the upstream superpowers default on purpose. The frozen snapshot in `using-workbench/references/using-superpowers-upstream.md` is left as it was. Any future skill that states a lane rule states it lighter-by-default, or it contradicts triage.

## Optional required-skill rows

The pilot required-skills table is a fixed floor ("removal not supported"). A row that points at a plugin the user may not have needs the optional shape, which arrived with `ponytail:ponytail` at step 5 in workbench 1.1.0. An optional row:

1. is never reported as a skipped requirement when its plugin is absent, unlike every mandatory row;
2. may need no call at all when the plugin's hooks inject its content on their own, as ponytail's `SessionStart`, `SubagentStart`, and `UserPromptSubmit` hooks do;
3. never overrides a mandatory row, and `references/required-skills.md` states the order: against `test-driven-development`, TDD wins; against `verification-before-completion`, verification wins.

Use this shape for any future cross-plugin row instead of a hard dependency, which would break every project that installed workbench alone.

## Per-artifact format, path, and design-system resolution via `.workbench/config.md`

Four workbench skills (`writing-spec`, `writing-plans`, `brainstorming`, `systematic-debugging`) read an optional `.workbench/config.md` at the repo root for each artifact's output format (`md` or `html`), output folder, and active design system. The three resolve independently.

- **Format:** the prompt, then `.workbench/config.md` `## Output formats`, then the skill's default.
- **Path:** for specs and plans, `.workbench/pilot.md` `## Documentation paths`, then `.workbench/config.md` `## Output paths`, then the project's `CLAUDE.md` or `AGENTS.md` convention, then an existing `docs/superpowers/specs` or `docs/superpowers/plans` folder, then the skill's default. Brainstorm summaries and debug reports use `## Output paths`, then the default. Each rung names a folder; the skill always appends the file name. `writing-spec`, `writing-plans` and `pilot` once each carried their own order, and they disagreed, so the order now lives in `config-schema.md` alone and the three skills point there. The HTML plan template has a Design section for the medium lane's `## Design` preamble, which had no place in it before; the large lane removes it, because its spec holds the design.
- **Design system:** the prompt, then `.workbench/config.md` `## Design system` `Name:`, then none (templates render with their defaults).

Defaults: specs `md` in `.workbench/specs`, plans `md` in `.workbench/plans`, brainstorm summaries `html` in `.workbench/brainstorms`, debug reports `html` in `.workbench/debug-reports`.

`research:running-research` ignores `.workbench/config.md` for format and path (the approved brief sets both; the default is HTML at `reports/<topic-slug>-<YYYY-MM-DD>/report.html`) but honors `## Design system` like the other HTML producers. `crafting-html` reads only `## Design system`. The full schema is in `plugins/workbench/skills/pilot/references/config-schema.md`. The HTML side of these skills is in [HTML producers, presets and themes](/explanation/html-producers-presets-and-themes.md).
