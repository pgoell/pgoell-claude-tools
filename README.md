# pgoell-claude-tools

Plugin marketplace for Claude Code and Codex.

Bundles 17 plugins across Atlassian, Google Workspace, Databricks, agent-system management, design workflows, research, writing, presentations, diagrams, terminal control, learning, prose output styles, code minimalism, and more.

## Skills at a glance

| Skill                             | Plugin                    | What it does                                                                                                                |
| --------------------------------- | ------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `jira`                            | `atlassian`               | Search Jira issues, create and update tickets, transition workflows, comment, manage sprints, run bulk operations           |
| `confluence`                      | `atlassian`               | Search Confluence pages, read documentation, create and update pages, browse spaces                                         |
| `gmail`                           | `google-workspace`        | Triage inbox, search and read messages, send mail, manage drafts, labels, and filters via the `gws` CLI                     |
| `calendar`                        | `google-workspace`        | View agenda, manage events, check availability, manage calendars via the `gws` CLI                                          |
| `research`                        | `research`                | Research complex topics and produce sourced reports                                                                         |
| `writing`                         | `writing`                 | Draft, review, and finish long form prose                                                                                   |
| `pyramid`                         | `writing`                 | Structure analytical documents with the Pyramid Principle                                                                   |
| `tech-doc`                        | `writing`                 | Draft, review, and finish technical documentation                                                                           |
| `claude-codex-bridge`             | `runtime-bridge`          | Align Claude Code and Codex project files                                                                                   |
| `improving-instructions`          | `agent-system-management` | Audit and improve agent instruction files                                                                                   |
| `capturing-session-learnings`     | `agent-system-management` | Capture session learnings into the right instruction file                                                                   |
| `creating-skills`                 | `agent-system-management` | Create, eval, benchmark, bulletproof, and tune skills across the full lifecycle                                             |
| `brainstorming`                   | `workbench`               | Sequential Q&A to clarify design intent                                                                                     |
| `writing-spec`                    | `workbench`               | Synthesize a design discussion into a spec doc                                                                              |
| `writing-plans`                   | `workbench`               | Turn approved specs into concrete implementation plans                                                                      |
| `visualizing-options`             | `workbench`               | Browser-based visual companion for layout choices                                                                           |
| `using-workbench`                 | `workbench`               | Load Workbench skill rules and routing                                                                                      |
| `pilot`                           | `workbench`               | Ship a feature end to end with configurable human gates; replaces autopilot and copilot                                     |
| `verification-before-completion`  | `workbench`               | Require fresh verification evidence before completion claims                                                                |
| `test-driven-development`         | `workbench`               | Enforce test-first RED-GREEN-REFACTOR implementation discipline                                                             |
| `subagent-driven-development`     | `workbench`               | Execute implementation plans with fresh agents and review gates, including parallel dispatch                                |
| `systematic-debugging`            | `workbench`               | Root-cause investigation before proposing bug fixes                                                                         |
| `crafting-html`                   | `workbench`               | Reference gallery of 21 HTML artifact patterns                                                                              |
| `crafting-design-systems`         | `workbench`               | Design systems (CSS variables, components, images) that theme HTML producers                                                |
| `tmux`                            | `terminal`                | Control interactive terminal programs through isolated tmux sessions                                                        |
| `frontend-design`                 | `frontend-design`         | Distinctive, production-grade frontend interfaces that avoid generic AI aesthetics                                          |
| `emil-design-eng`                 | `frontend-design`         | Emil Kowalski's design engineering philosophy: animation timing, component polish, UI craft                                 |
| `playground`                      | `playground`              | Interactive single-file HTML playgrounds with controls, live preview, and copy-out prompt                                   |
| `databricks-core`                 | `databricks`              | Databricks CLI, authentication, profile management, and data exploration                                                    |
| `databricks-docs`                 | `databricks`              | Live `docs.databricks.com` lookups for product-surface questions                                                            |
| `quizzing-the-session`            | `learning`                | Get taught and quizzed on the current session's work until you demonstrably understand the problem, solution, and impact    |
| `quizzing-a-topic`                | `learning`                | Get taught and quizzed on any topic or theme you name until you demonstrably understand it                                  |
| `surveying-blind-spots`           | `learning`                | Pre-work blind-spot pass over an unfamiliar codebase area or field, surfacing unknown unknowns, gotchas, and better prompts |
| `designing-presentations`         | `presentations`           | Design slide-deck content from audience brief through critiqued storyboard, producing a `deck.md`                           |
| `creating-presentations`          | `presentations`           | Build multi-slide HTML decks from brand presets, with a presenter view and an opt-in review-to-done loop                    |
| `exporting-presentations-to-pptx` | `presentations`           | Convert a finished HTML deck into a native, editable PowerPoint (.pptx) via python-pptx                                     |
| `extracting-presets`              | `presentations`           | Turn brand material (PPTX templates, PDF guidelines, decks) into reusable presentation presets                              |
| `creating-diagrams`               | `diagrams`                | Draw architecture, workflow, sequence, data-flow, and lifecycle diagrams as themeable standalone HTML with inline SVG       |
| `ponytail`                        | `ponytail`                | Force the laziest solution that works: YAGNI, stdlib first, one line over fifty                                             |
| `ponytail-review`                 | `ponytail`                | Review a diff for over-engineering only: what to delete and what replaces it                                                |
| `ponytail-audit`                  | `ponytail`                | Whole-repo over-engineering audit, ranked by what to delete, simplify, or replace                                           |
| `ponytail-debt`                   | `ponytail`                | Harvest `ponytail:` shortcut comments into a tracked debt ledger                                                            |
| `ponytail-gain`                   | `ponytail`                | Scoreboard of ponytail's measured benchmark impact                                                                          |
| `ponytail-help`                   | `ponytail`                | Quick-reference card for ponytail modes, skills, and commands                                                               |

The `deprecated` plugin additionally archives eight superseded skills: `crafting-presentations`, `perfecting-presentations`, `exporting-decks-to-pptx`, `presentations` point at their replacement in the `presentations` plugin; `autopilot`, `copilot`, `dispatching-parallel-agents`, `terse-mode` point at their replacement in the `workbench` plugin (`terse-mode` retires without replacement).

The `prose-styles` plugin ships no skills. It provides four Claude Code output styles instead, which govern how the agent writes prose for a whole session rather than for one task. See its section below.

Skills are invoked from the host agent (Claude Code or Codex) using the fully qualified form `/<plugin>:<skill>`, for example `/atlassian:jira` or `/workbench:pilot`.

## Installation

### Claude Code

```
/plugin marketplace add pgoell/pgoell-claude-tools
/plugin install atlassian@pgoell-claude-tools
/plugin install google-workspace@pgoell-claude-tools
/plugin install research@pgoell-claude-tools
/plugin install writing@pgoell-claude-tools
/plugin install runtime-bridge@pgoell-claude-tools
/plugin install agent-system-management@pgoell-claude-tools
/plugin install workbench@pgoell-claude-tools
/plugin install terminal@pgoell-claude-tools
/plugin install frontend-design@pgoell-claude-tools
/plugin install playground@pgoell-claude-tools
/plugin install databricks@pgoell-claude-tools
/plugin install learning@pgoell-claude-tools
/plugin install presentations@pgoell-claude-tools
/plugin install diagrams@pgoell-claude-tools
/plugin install prose-styles@pgoell-claude-tools
/plugin install ponytail@pgoell-claude-tools
```

The `deprecated` plugin (`/plugin install deprecated@pgoell-claude-tools`) is an archive of superseded skills; only install it if an old workflow still calls the old skill names.

### Codex

Add the marketplace from your shell, then install plugins from inside Codex:

```
codex plugin marketplace add pgoell/pgoell-claude-tools
codex
/plugins
```

In the `/plugins` picker, install any combination of `atlassian`, `google-workspace`, `research`, `writing`, `runtime-bridge`, `agent-system-management`, `workbench`, `terminal`, `frontend-design`, `playground`, `databricks`, `learning`, `presentations`, `diagrams`, and `ponytail` (plus `deprecated` if an old workflow needs the archived skill names). `prose-styles` is absent from the Codex picker on purpose, because Codex has no output-style mechanism.

To pick up updates: `codex plugin marketplace upgrade pgoell-claude-tools` and re-install the affected plugins.

## Plugins

### atlassian

Jira and Confluence skills for Atlassian Cloud.

**Skills:**

- `/atlassian:jira`: Search issues, update tickets, transition status, add comments, and manage sprints.
- `/atlassian:confluence`: Search pages, read documentation, update pages, and browse spaces.

**Setup:**

The plugin supports two authentication paths.

**Atlassian CLI (recommended).**

```bash
brew install atlassian/tap/acli
acli auth login
```

**API token fallback.**

Generate a token at https://id.atlassian.com/manage/api-tokens, then export:

```bash
export ATLASSIAN_DOMAIN="your-domain"    # e.g. mycompany (for mycompany.atlassian.net)
export ATLASSIAN_EMAIL="you@company.com"
export ATLASSIAN_API_TOKEN="your-token"
```

### google-workspace

Gmail and Calendar skills for Google Workspace, powered by the `gws` CLI.

**Skills:**

- `/google-workspace:gmail`: Search, read, send, and manage Gmail messages, drafts, labels, and filters.
- `/google-workspace:calendar`: View agendas, manage events, check availability, and manage calendars.

**Setup:**

Install and authenticate the `gws` CLI:

```bash
npm i -g @anthropic-ai/gws
gws auth login -s gmail,calendar
```

Full setup instructions: https://github.com/googleworkspace/cli

### research

Research complex topics and produce sourced reports.

**Skills:**

- `/research:research`: Plan focused investigations, gather sources, synthesize findings, review conclusions, and write reports. Reports default to HTML at `reports/<topic-slug>-<YYYY-MM-DD>/report.html`; override per invocation with "give me a markdown research report".

### writing

Writing skills for prose, analytical structure, and technical documentation.

**Skills:**

- `/writing:writing`: Draft, review, and finish long form prose.
- `/writing:pyramid`: Structure memos, recommendations, briefings, and decision documents with the Pyramid Principle.
- `/writing:tech-doc`: Draft, review, and finish tutorials, how-to guides, references, and explanations.

Slide-deck content design moved to `/presentations:designing-presentations`; for a written prose talk, use `/writing:writing` with the talk format.

### runtime-bridge

Aligns Claude Code and Codex project configuration.

**Skills:**

- `/runtime-bridge:claude-codex-bridge`: Align project files, settings, hooks, agents, and plugin availability across the two runtimes.

### agent-system-management

Manage the host agent's instruction layer and skill layer: audit `AGENTS.md` / `CLAUDE.md`, capture session learnings, and scaffold or iterate on Claude Code / Codex skills.

**Skills:**

- `/agent-system-management:improving-instructions`: Audit and improve `AGENTS.md` and `CLAUDE.md` files.
- `/agent-system-management:capturing-session-learnings`: Capture session learnings into the right instruction file.
- `/agent-system-management:creating-skills`: Create a new skill, iterate on an existing one with eval loops and benchmarks, bulletproof discipline skills, optimize triggering, or extract a skill from a conversation.

### workbench

Workbench skills for design dialogue, skill routing, and profile-driven feature shipping.

**Skills:**

- `/workbench:brainstorming`: Sequential question-and-answer loop to clarify design intent, scaled to the medium and large triage lanes. Hands off to `writing-spec` in the large lane, or to `writing-plans`' Design preamble mode in the medium lane.
- `/workbench:writing-spec`: Synthesize a design discussion into a spec doc, run a fresh-eyes self-review subagent, gate on user approval, then hand off to `workbench:writing-plans`.
- `/workbench:writing-plans`: Turn approved specs into concrete, slice-ordered implementation plans at program-design altitude.
- `/workbench:visualizing-options`: Browser-based visual companion for mockups, layout comparisons, wireframes, and architecture diagrams.
- `/workbench:using-workbench`: Load Workbench skill rules and routing; triages every task into the quick, medium, or large lane.
- `/workbench:pilot`: Ship a feature end to end with configurable human gates, from design through PR. Replaces `autopilot` and `copilot`: `Gates: none` runs fully autonomous (the old autopilot behavior), `Gates: design` pauses for a human-driven brainstorm and spec approval (the old copilot behavior), and the default `Gates: design, slices` also pauses to review each slice's diff before the next one starts. Profile schema documented in `plugins/workbench/skills/pilot/references/profile-schema.md`.
- `/workbench:verification-before-completion`: Require fresh verification evidence before completion claims.
- `/workbench:test-driven-development`: Enforce test-first RED-GREEN-REFACTOR implementation discipline.
- `/workbench:subagent-driven-development`: Execute implementation plans with fresh agents and review gates, including parallel dispatch across independent tasks.
- `/workbench:systematic-debugging`: Enforce root-cause investigation before proposing bug fixes; bundles techniques for backward stack tracing, defense in depth, and condition-based waiting.
- `/workbench:crafting-html`: Reference gallery of 21 HTML artifact patterns vendored from `ThariqS/html-effectiveness`. Activates for standalone HTML artifacts not covered by specs, plans, brainstorm summaries, debug reports, or research reports.
- `/workbench:crafting-design-systems`: Create reusable design systems (CSS variables, components, images) at project (`.workbench/design-systems/<name>/`) or user (`~/.claude/workbench/design-systems/<name>/`) scope. HTML producers inline the active design system over their template defaults.

Multi-slide presentation skills (deck building, review loop, PPTX export) moved to the `presentations` plugin.

`writing-spec`, `writing-plans`, `brainstorming`, and `systematic-debugging` can emit either markdown or HTML; defaults are markdown for specs and plans, HTML for brainstorm summaries and debug reports. Override per invocation or via `.workbench/config.md` (schema in `plugins/workbench/skills/pilot/references/config-schema.md`).

**Migration note:** 1.0.0 merged autopilot and copilot into pilot; rename `.workbench/autopilot.md` to `.workbench/pilot.md`, then add `Gates: none` to keep autopilot's fully autonomous behavior or `Gates: design` to keep copilot's behavior. Omitting the row gets the new default, `Gates: design, slices`, which adds a per-slice review pause.

### terminal

Terminal skills for interactive command-line programs.

**Skills:**

- `/terminal:tmux`: Drive interactive CLIs, REPLs, debuggers, and experimental nested agent sessions through isolated tmux sessions.

**Setup:**

Install `tmux` on Linux, macOS, or WSL. Native Windows terminals are not supported.

### frontend-design

Distinctive, production-grade frontend interfaces with deep UI craft and animation discipline. Ports two complementary skills: Anthropic's `frontend-design` (Apache 2.0) for creative direction, and Emil Kowalski's [`emil-design-eng`](https://github.com/emilkowalski/skill) for design engineering and animation discipline (the upstream repo declares no license; included under the upstream author's public publishing intent). See `plugins/frontend-design/NOTICE` for full attribution.

**Skills:**

- `/frontend-design:frontend-design`: Build web components, pages, and applications with a clear aesthetic point of view (typography, color, motion, composition).
- `/frontend-design:emil-design-eng`: Review UI craft, choose easing curves and durations, build interaction-rich components, and audit motion.

### playground

Interactive single-file HTML playgrounds: control panel, live preview, and copy-out prompt. Ports Anthropic's `playground` plugin (Apache 2.0; see `plugins/playground/NOTICE` for attribution).

**Skills:**

- `/playground:playground`: Build self-contained HTML playgrounds for design, data, concept maps, document critique, diff review, or code architecture.

### databricks

Two Databricks skills. `databricks-core` is a verbatim port from [databricks/databricks-agent-skills](https://github.com/databricks/databricks-agent-skills) at commit `bf6d932`, governed by the upstream Databricks License (use restricted to Databricks Services; see `plugins/databricks/LICENSE-upstream` and `plugins/databricks/NOTICE`). `databricks-docs` is original authorship: it points the host agent at `docs.databricks.com` via WebFetch using a curated URL index. The plugin also preserves `references/research/` with 12 MB of Genie Code reverse-engineering notes; see `plugins/databricks/README.md` for details.

**Skills:**

- `/databricks:databricks-core`: CLI, authentication, profile management, data exploration, and bundles.
- `/databricks:databricks-docs`: Live `docs.databricks.com` lookups for product-surface questions (Apps, DABs, Jobs, Lakebase, Model Serving, Pipelines, Unity Catalog, SQL Warehouses, MLflow, serverless, secrets, workflows).

**Setup:**

`databricks-core` operates against your existing `databricks` CLI profiles; configure them with `databricks auth login` or by editing `~/.databrickscfg`. `databricks-docs` is read-only against `docs.databricks.com` and needs no auth.

### learning

Skills that teach the human: Socratic teach-and-quiz loops plus a pre-work blind-spot survey. An original adaptation of Thariq Shihipar's "Learn Quiz" gist and his AI Engineer talk techniques (see `plugins/learning/README.md` for attribution).

**Skills:**

- `/learning:quizzing-the-session`: Build a problem/solution/impact checklist from the current session and recent git activity, then teach and quiz you item by item to mastery. Also fits right before a PR or merge, to confirm you can represent the work in review.
- `/learning:quizzing-a-topic`: The same teaching engine pointed at any topic or theme you name, grounded in repo files when the topic is local code.
- `/learning:surveying-blind-spots`: A pre-work blind-spot pass over a codebase area or field you do not know. Surfaces unknown unknowns, gotchas, and dead ends, then hands you rewritten prompts. A briefing, not a quiz.

### presentations

The full presentation lifecycle in one plugin: content design, HTML deck building with an integrated perfecting loop, native PowerPoint export, and brand preset extraction.

**Skills:**

- `/presentations:designing-presentations`: Design slide-deck content end to end (audience brief, message architecture, storyboard, per-slide drafts, critique panel). Produces a markdown `deck.md`; also runs in audit mode against an existing `deck.md`.
- `/presentations:creating-presentations`: Build multi-slide HTML decks styled from a brand preset, presented through a bundled deck-stage engine with a two-window presenter view (`BroadcastChannel` sync, live-editable speaker notes). Includes an opt-in review-to-done convergence loop with deterministic hard gates, fresh judge panels, and adversarial verification.
- `/presentations:exporting-presentations-to-pptx`: Convert a finished HTML deck into a native, editable PowerPoint file via a freshly written python-pptx generator, with a containerized LibreOffice render-verify loop and an optional per-slide adversarial verification panel.
- `/presentations:extracting-presets`: Turn brand material (PPTX templates and slide masters, PDF guidelines, icon libraries, example decks) into reusable presets: layered CSS variables, guidance files, assets, and self-contained example slides.

Styling flows through presets (contract in `plugins/presentations/presets/README.md`). The plugin bundles a neutral `default` preset; project-local presets and a preset choice live under `.pgoell/presentations/` (`config.md` plus `presets/<name>/`) at the repo root of the project you are working in. Runtime dependencies (checked lazily, per branch): a Chromium-based browser, `uv`, and a container engine for preset extraction render checks.

### diagrams

Diagrams as one self-contained HTML file: inline SVG, light and dark modes, and SVG, PNG, and clipboard export, with no dependencies or network requests. Combines ideas from [Cocoon-AI/architecture-diagram-generator](https://github.com/Cocoon-AI/architecture-diagram-generator) and [tt-a1i/archify](https://github.com/tt-a1i/archify), both MIT (see `plugins/diagrams/NOTICE`).

**Skills:**

- `/diagrams:creating-diagrams`: Draw an architecture, workflow, sequence, data-flow, or lifecycle diagram from a description, pasted Mermaid, or a repository scan. Plans the layout on a grid, renders both modes in headless Chromium, and reviews the screenshots against a fixed checklist.

Colors come only from theme variables (contract in `plugins/diagrams/themes/README.md`). The plugin bundles a `classic` theme; the skill can derive a brand theme from a `presentations` preset or straight from a PPTX template and saves it under `.pgoell/diagrams/` in the project you are working in.

**Setup:** optional. A Chromium-based browser (Chrome, Chromium, or Edge) enables the visual review step; without one, the skill reports the review as skipped.

### prose-styles

Four Claude Code output styles that govern how the agent writes prose. An output style goes into the system prompt for the whole session, so it shapes every reply, commit message, PR body, and doc until you switch it. Unlike a skill, you do not invoke it per task. All four keep Claude Code's coding instructions intact and change only the writing.

| Style                  | What it does                                                                                                                                                              |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `prose-styles:orwell`  | Orwell's six rules from "Politics and the English Language" (1946). Short word over long, no stock phrase, active voice, cut every word that can go.                      |
| `prose-styles:concise` | Maximum density. Fragments legal, articles droppable, no preamble, no closing summary. Grammar yields to brevity, facts never do.                                         |
| `prose-styles:ste`     | Simplified Technical English, condensed from ASD-STE100. One meaning per word, one instruction per step, condition before instruction. Built for procedures and runbooks. |
| `prose-styles:house`   | All three combined. Concision sets the shape, Orwell governs word choice, STE contributes vocabulary and ambiguity discipline only.                                       |

Every style governs prose only. Code, identifiers, API names, CLI flags, config keys, and quoted output are exempt in all four.

`house` resolves the conflict between STE and concision in concision's favor: STE demands full sentences, articles, and "never omit a word to shorten", and all three are dropped. What survives from STE is its precision layer, one word per concept and no ambiguous pronouns. Use `ste` on its own when the reader must not misread, such as migration steps or an incident runbook.

**Setup:** select a style after install with `/output-style prose-styles:house`, or pick it from the Output style list in `/config`. The choice persists for the project. Revert with `/output-style default`. Claude Code only; Codex has no output-style mechanism, so the plugin is not in the Codex marketplace.

### ponytail

Lazy senior dev mode: a reflex ladder that questions whether code needs to exist at all, reaches for the standard library and native platform features before dependencies, and prefers one line over fifty. Three intensity levels (`lite`, `full`, `ultra`).

This is the only plugin in the marketplace that is **not vendored here**. Its entry points at [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) (MIT) and tracks upstream `main`, so refreshing the marketplace picks up upstream changes directly. Versions and release cadence are the upstream author's, not this repo's.

**Skills:**

- `/ponytail:ponytail`: The core mode. Applies the reflex ladder to any coding task and marks deliberate shortcuts with `ponytail:` comments naming their ceiling and upgrade path.
- `/ponytail:ponytail-review`: Review a diff for over-engineering only. One line per finding: location, what to cut, what replaces it. Complements correctness-focused review rather than replacing it.
- `/ponytail:ponytail-audit`: The same lens over a whole repo instead of a diff, as a ranked list of what to delete, simplify, or replace with stdlib equivalents. Reports, does not apply fixes.
- `/ponytail:ponytail-debt`: Harvest every `ponytail:` comment into a debt ledger so deferrals get tracked instead of rotting.
- `/ponytail:ponytail-gain`: Scoreboard of ponytail's measured impact from its benchmark medians.
- `/ponytail:ponytail-help`: Quick-reference card for the modes, skills, and commands.

**Setup:** none beyond install, but note that ponytail ships hooks that run on `SessionStart`, `SubagentStart`, and `UserPromptSubmit`. They require `node` on `PATH`, write a mode flag to `$CLAUDE_CONFIG_DIR/.ponytail-active`, and inject the ruleset into every session automatically. Ponytail is therefore always-on once installed, not invoke-on-demand. Set the mode to `off` if you want it dormant.

### deprecated

Archive of superseded skills, kept installable so old workflows keep resolving. Each skill is frozen, carries a deprecation banner, and names its replacement: `crafting-presentations`, `perfecting-presentations`, and `exporting-decks-to-pptx` (formerly `workbench`) plus `presentations` (formerly `writing`) point at the `presentations` plugin; `autopilot`, `copilot`, and `dispatching-parallel-agents` (formerly `workbench`) point at their replacements in the `workbench` plugin (`pilot` and `subagent-driven-development`), and `terse-mode` (formerly `workbench`) retires without replacement. Do not install alongside `presentations` or `workbench` unless you need the old skill names.

---

See `AGENTS.md` for repository structure, plugin layout, and contribution conventions.
