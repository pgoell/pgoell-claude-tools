# Workbench

Workbench skills for design dialogue, skill routing, and profile driven feature shipping.

## Skills

- `brainstorming`: Turn ideas into clear design decisions.
- `writing-spec`: Synthesize a design discussion into a spec doc with fresh-eyes self-review and an approval gate.
- `writing-plans`: Turn approved specs into concrete implementation plans.
- `visualizing-options`: Browser-based visual companion for mockups, layout comparisons, wireframes, and architecture diagrams.
- `using-workbench`: Load Workbench skill rules and routing.
- `pilot`: Ship a feature end to end with configurable human gates; replaces autopilot and copilot.
- `verification-before-completion`: Require fresh verification evidence before completion claims.
- `test-driven-development`: Enforce test-first RED-GREEN-REFACTOR implementation discipline.
- `subagent-driven-development`: Execute implementation plans with fresh agents and review gates; absorbs dispatching-parallel-agents' parallel dispatch rules.
- `systematic-debugging`: Root-cause investigation before proposing bug fixes.
- `crafting-html`: Reference gallery of 20 HTML artifact patterns, plus an index, for standalone HTML artifacts.
- `crafting-design-systems`: Design systems (CSS variables, components, images) that theme HTML producers.

Multi-slide presentation skills (building, perfecting, PPTX export) moved to the `presentations` plugin. `terse-mode` retires without replacement.

## Project profiles

Workbench owns reusable workflow kernels. Projects own local policy through small profile files at `.workbench/<skill>.md`. See [`skills/pilot/references/profile-schema.md`](skills/pilot/references/profile-schema.md) for the pilot schema and [`skills/pilot/references/example-project-profile.md`](skills/pilot/references/example-project-profile.md) for examples.

Workbench ships the steps and invariants. The project profile carries PR behavior and hooks. Project information that already lives in `CLAUDE.md` or `AGENTS.md` stays there.

## Coexistence

Workbench is designed to run alongside the upstream `superpowers` plugin. When a slug exists in both plugins, prefer the Workbench version.

## Credits

This plugin includes content derived from the Superpowers plugin by Jesse Vincent (https://github.com/obra/superpowers), version 5.0.7, MIT-licensed. See the NOTICE file for the full list of derived files and the LICENSE file for the upstream license text.

This plugin also includes content derived from [`ThariqS/html-effectiveness`](https://github.com/ThariqS/html-effectiveness) at commit `5d64f68`. It provides the 21-file HTML artifact gallery vendored under `skills/crafting-html/references/`. The upstream repository carries no declared license at time of port; the content is vendored under the upstream author's public publishing intent (see `NOTICE` for full attribution). Upstream added a license after the port (MIT, then Apache-2.0 since 2026-05-18); `NOTICE` records the commits and says a refresh re-ports at a licensed commit. U+2014 and U+2013 codepoints were substituted at port time per this repo's lint convention.
