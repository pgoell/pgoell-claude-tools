---
type: Reference
title: Skill design patterns
description: How skills group into plugins, workflow protocols, the agents slot, stub plugins, shared references and producer/renderer pairs.
tags: [conventions, skills, plugins, design]
status: stable
---

# Skill design patterns

Read this before you add a skill, split or merge skills, or share files between skills. Reasons and history: [skill-design-patterns](/explanation/skill-design-patterns.md). The rule "Every skill is model-invocable" applies to every task, so it stays in [AGENTS.md](../../../AGENTS.md).

- **One skill per service, one plugin per product family.** Gmail and Calendar sit in `google-workspace`; Jira and Confluence in `atlassian`. Exception: workbench ships its peer workflow skills together but split, so each phase runs alone (`pilot`, `using-workbench`, `brainstorming`, `writing-spec`, `writing-plans`, `visualizing-options`, `test-driven-development`, `subagent-driven-development`, `systematic-debugging`, `verification-before-completion`, `crafting-html`, `crafting-design-systems`). `presentations` splits its five life-cycle skills the same way. Skills that need local Unix tools go in `terminal`.
- **Workflow skills are execution protocols.** When a user calls a workflow skill such as `workbench:pilot`, follow its sequence as a procedure (branch setup, brainstorm, spec, plan, pressure test, implementation, verification where they apply), not as loose advice.
- **Agents for long-running, context-heavy operations (forward-looking, currently unused).** The `agents/` slot is reserved for agents a skill would dispatch for context-heavy work. No plugin uses it (`research` runs subagents from prompt templates in `skills/research/`); use skills for everything else.
- **Unregistered plugin directories are a valid stub state.** A `plugins/<plugin>/` folder with both manifests but no marketplace entry is a stub (research notes, scaffolding). To bring it online, add `skills/` with at least one `SKILL.md` and register it in both marketplaces; to retract a plugin, remove it from both. Plugin-level `references/` stays valid after skills ship. Never force-add the gitignored `plugins/databricks/references/research/`.
- **Sibling-skill reference sharing for thin variants (historical pattern, still valid).** A thin variant may read a sibling's references and may also ship its own `references/`, but every path into the sibling must carry the `../<sibling>/references/` prefix (a bare `references/...` resolves against the variant's own folder). Prefer a self-contained `SKILL.md` over a redirect to the sibling's `SKILL.md`. Share only identical infrastructure. Live cases, both with their own `references/`: `writing:coach` reads `../ghostwrite/references/pyramid-audits.md`, and the workbench HTML producers read the design-system protocol in `../crafting-design-systems/references/`.
- **Producer/renderer skill pairs maintain different taxonomies at different abstraction levels.** The content producer lists argument roles, the renderer lists layout templates; the producer ships a non-binding mapping table, and its type field (`slide_type` in `deck.md`) is a hint, never a constraint. Do not merge the two lists into one enum.
