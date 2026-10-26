---
type: Explanation
title: Skill design patterns
description: How skills are grouped into plugins, when a skill should use subagents, why workflow skills run as protocols, and the patterns for stubs, shared references and the unused agents slot.
tags: [skills, plugins, patterns, contributors]
status: stable
---

# Skill design patterns

These rules shape how skills split into plugins and how they share files. [Skill design patterns](/reference/conventions/skill-design-patterns.md) states them (AGENTS.md keeps "Every skill is model-invocable"); this page keeps the reasons and the history.

## One skill per service, one plugin per product family

Gmail and Calendar both sit under `google-workspace`; Jira and Confluence both sit under `atlassian`. A user installs a product family once and gets one skill per service in it.

The `presentations` plugin follows the product-family rule. Its six skills (`designing-presentations`, `building-pptx-decks`, `creating-presentations`, `editing-presentations`, `exporting-presentations-to-pptx`, `extracting-presets`) are life-cycle phases of one product, a presentation, split so each phase triggers on its own.

Terminal skills that depend on local Unix tools belong in the `terminal` plugin, so Windows users can skip them unless they use WSL.

## Model invocation and short descriptions

Every model-invoked skill's description loads into every request. A skill audit on 2026-10-19 (against Matt Pocock's talk "Building Great Agent Skills: The Missing Manual") counted 46 live descriptions at 15,143 characters, none of them user-only, and 13 over 500 characters. Seven skills only ever start from the user or from cron, so their descriptions paid that cost for nothing: `insights:activity`, `insights:apply`, `insights:digest`, `news:edition`, `news:tune`, `issue-loop:running-the-loop` and `workbench:pilot` (issues #158 and #159). They then set `disable-model-invocation: true` and carried one plain sentence for the human. The advice for it lived in `creating-skills` (`references/writing-great-skills.md`).

The flag also stops the model from loading such a skill through the Skill tool. So no other skill may tell the model to start one: `insights:digest` reads `../apply/SKILL.md` by path, and an issue-loop handover sends a first message that starts with `/issue-loop:running-the-loop`, which Claude Code expands as a typed command. Cron is unaffected: the wrappers send the slash command as the `-p` prompt, a user turn. The trigger evals that asserted the model fired `running-the-loop` on its own were dropped with the flag.

`learning:*` and `news:feedback` stay model-invoked: people reach them with plain requests ("quiz me on this", "less Polizeibericht").

The same day the user had the flag dropped again from all seven skills, with the Codex `agents/openai.yaml` files beside them. A successor orchestrator could not load `running-the-loop`, so a handover failed when the leading slash command did not run. Every skill in this repo is model-invocable now; the seven carry model-facing "Use when" descriptions under 500 characters, the trigger evals for `running-the-loop` are back, and a handover's first message tells a successor that missed the command to load the skill with the Skill tool. The trims to the other descriptions stay.

## Workflow skills are execution protocols

When a user calls a workflow skill such as `research:research` or `issue-loop:running-the-loop`, the agent follows its steps as a procedure, in order. The body is not loose advice to pick from. A skipped step is the failure these skills exist to prevent.

## Subagents only for parallel work, independent review, or context that would not fit

Each handoff to a subagent loses detail: the subagent sees a brief, not the plan behind it, and the main session sees a summary, not the work. Newer models carry long, many-step tasks in one context, and skills and tool search load reference text only when needed, so the context limits that once justified a split come up less often. Anthropic's write-up, [When to fold subagents into your main agent loop](https://claude.com/resources/articles/building-agents-when-to-fold-subagents-into-your-main-agent-loop) (2026-10), found one agent with skills often beat a set of subagents on quality, cost and speed.

A subagent still earns its place in three cases. Parts that run side by side need their own fresh contexts (`news` gatherers, `research` researchers). A check must not share the author's framing, or it agrees too easily (`critique` frames, `presentations` judges, the bridge reviewer, `issue-loop` review). And a main context that would measurably degrade can hand off bulky reading.

Steps that run in order and feed each other are the first to fold. In 2026-10 `runtime-bridge` moved its scout and apply phases into the main session, and `issue-loop` let the implementer's main session code, after its own log showed it edited in 17 of 22 tasks under a rule that said subagents code. The write-up warns that a fold can quietly break a process that worked, so fold one at a time and compare runs before and after. `research:running-research` keeps its synthesis and writer subagents until such a comparison is done: its review loops have no fixed limit, and the orchestrator's context would grow each round.

## Agents for long-running, context-heavy operations (forward-looking, currently unused)

When a skill's run would eat a lot of context (dozens of web pages, say), the intended layout is an agent in the plugin's `agents/` folder that the skill dispatches through the host's subagent tool, so the work runs in its own context. No plugin uses an `agents/` folder yet. The `research` plugin runs its subagents from prompt templates inside `skills/running-research/` instead. Treat `agents/` as a reserved slot, not a convention in use, and use skills for everything else.

## Unregistered plugin directories are a valid stub state

A folder under `plugins/<plugin>/` may have `.claude-plugin/plugin.json` and `.codex-plugin/plugin.json` but no entry in `.claude-plugin/marketplace.json` or `.agents/plugins/marketplace.json`. Use this shape for research notes, reference material, or future skill scaffolding that belongs in `plugins/` but cannot be installed yet. To bring a stub online, add a `skills/` folder with at least one `SKILL.md` and register it in both marketplaces. Going back (an installable plugin to a stub) means removing it from both marketplaces.

No plugin holds this shape now. `databricks` held it from PR #53 until 0.3.0. Its `references/research/` folder (12 MB of Genie Code reverse-engineering notes, gitignored since 2026-05 to keep them off the public repo, so it exists only in local clones) survived the move to installable. It shows a second point: a plugin-level `references/` is a valid home for non-skill research even after the plugin ships skills, apart from per-skill `references/`. Never force-add that folder.

## Sibling-skill reference sharing for thin variants (historical pattern, still valid)

A skill that is a thin variant of another in the same plugin may share the original's `references/` instead of copying them, by pointing every path at `../<sibling-skill>/references/<file>.md`.

The first case was `workbench:copilot`, the human-in-the-loop variant of `workbench:autopilot` (steps 2 brainstorm and 3 spec stayed human-driven; steps 1 and 4 to 9 stayed autonomous). It shipped only `SKILL.md` and read autopilot's six shared docs (`profile-schema`, `example-project-profile`, `invariants`, `required-skills`, `claude-code-adapter`, `codex-adapter`) and the same `.workbench/autopilot.md` profile. Both retired into `workbench:pilot` at workbench 1.0.0, and pilot itself into the archive in 2026-10 (see [The deprecated archive](/explanation/the-deprecated-archive.md)), so this case no longer exists live.

One constraint makes it work: every shared path in the variant's `SKILL.md` carries the `../<sibling>/references/` prefix, because a bare `references/...` resolves against the variant's own folder. The variant may still ship its own `references/` for what it does not share; copilot shipped none, but the live case below does. Prefer a self-contained orchestration `SKILL.md` that runs on one read over a thin redirect to the sibling's `SKILL.md`: a redirect hides the content behind a cross-reference and breaks when the sibling renumbers its steps. Share only when the docs are truly the same infrastructure used the same way; copy into the variant only what must differ.

The live case: `writing:coach` reads one file from its sibling, `../ghostwrite/references/pyramid-audits.md`, because both skills use the same audits (ghostwrite reports them on outlines, coach teaches from them) and a second copy would drift. The coach keeps its own `references/` for everything else.

A second case, the design-system protocol that the workbench HTML producers read from `../crafting-design-systems/references/`, retired with workbench in 2026-10.
