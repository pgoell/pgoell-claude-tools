---
type: Reference
title: The agent-system-management plugin
description: The skills that audit and update agent instruction files and build or tune skills.
tags: [plugin, agent-system-management, agents-md, claude-md, skills]
status: stable
---

# agent-system-management

Skills for the host agent's instruction layer and skill layer: audit `AGENTS.md` and `CLAUDE.md` files, write a session's learnings into the right one, and create or tune skills.

**Runtimes:** Claude Code, Codex, Cursor

**Source:** vendored in `plugins/agent-system-management/`; see the [plugin README](../../../plugins/agent-system-management/README.md) for details and credits.

**Setup:** None beyond install.

## Skills

| Invocation                                             | What it does                                                                                                                                                                                  |
| ------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/agent-system-management:improving-instructions`      | Audit `AGENTS.md` and `CLAUDE.md` files across project and user scopes, score them against a quality rubric, and propose fixes.                                                               |
| `/agent-system-management:capturing-session-learnings` | At the end of a session, write what it taught into the right instruction file. Also runs on `/revise-agents-md` and `/revise-claude-md`.                                                      |
| `/agent-system-management:creating-skills`             | Create a skill, improve one through eval loops, benchmark it against a baseline, tune its description so it triggers when it should, cut it to its core, or turn a conversation into a skill. |

## Files in scope

The two instruction skills read `AGENTS.md`, `AGENTS.local.md`, `CLAUDE.md`, `CLAUDE.local.md`, the legacy `.claude.md` and `.claude.local.md`, plus the user-global `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`. They dedupe by `realpath`, so a `CLAUDE.md` symlinked to `AGENTS.md` counts once. `GEMINI.md` is out of scope.

## Evals

`plugins/agent-system-management/evals/` holds 15 `claude plugin eval` cases that test when each of the three skills fires. Cases 01 to 04 are triggers: the named skill must fire and its two siblings must not. Case 01 asks `improving-instructions` to audit a pasted `CLAUDE.md`. Case 02 asks `capturing-session-learnings` to save a lesson the user states into `CLAUDE.md`. Case 03 asks `creating-skills` to turn a described workflow into a skill, and case 04 asks it to tune a pasted skill description so the skill triggers when it should. Cases 21 to 23 are negatives: no skill of the three may fire.

Cases 31 to 34 are near-misses between sibling skills. Case 31 asks to save a lesson but uses the word "improve": `capturing-session-learnings` must fire, not `improving-instructions`. Case 32 asks for an audit of a pasted `AGENTS.md` and says nothing comes from this session: `improving-instructions` must fire, not `capturing-session-learnings`. Case 33 describes a procedure that belongs in a skill, not in a `CLAUDE.md` rule: `creating-skills` must fire. Case 34 asks to trim an overlong pasted `AGENTS.md`: `improving-instructions` must fire, not `creating-skills`, whose description names cutting, trimming and shortening a skill.

Cases 35 and 36 are near-misses outside the plugin: no skill of the three may fire, and an `llm` grader checks the reply. The run loads only this plugin, so no neighbouring skill is there to take the ask; the case checks that these skills hold back. Case 35 asks for a Claude Code hook in `settings.json` that runs a formatter after edits. Case 36 asks in one paragraph what the `description` field in a `SKILL.md` does.

Every prompt pastes what the skill must judge (the file to audit, the lesson, the workflow, the draft to cut), since the sandbox holds no files and no session. Cases 02 and 31 name a `CLAUDE.md` they do not paste; that does not matter, since the graders check only which skill fires. Every case allows only Skill, Read, Glob and Grep, so no case needs network or a shell, and none can write a file. The graders match full names such as `agent-system-management:creating-skills`.

Cases 41 and 42 test the cut itself, by the rule under "Find the behavioral core" in `creating-skills/references/cutting-skills.md`: a line stays only if it serves the list of requests that should trigger the skill or a decision a capable agent would get wrong without it; the rest goes, sorted by that page's content table and its Delete list. Each prompt pastes a `SKILL.md` draft and asks to cut it and paste the cut `SKILL.md` back in full, since the sandbox cannot write a file. `creating-skills` must fire and its two siblings must not. An `llm` grader `must-go` checks that a line which fails the rule is gone: general-knowledge advice in case 41, history that does not change what the agent does in case 42. An `llm` grader `must-stay` checks that a line which passes it is kept: a non-obvious domain constraint in case 41, a control on an irreversible action in case 42. The graders are `llm`, not regex, because the skill's report table quotes each cut line, so a text match would find the line even when the cut removed it. They judge only the pasted cut skill, and they do not fail a run that skips the "Prove nothing broke" baseline step, which the sandbox cannot run. Both cases carry the tags `core` and `deletion`, so the run below includes them.

No one has run the suite yet; a run costs money, so the user decides when. Run from `plugins/agent-system-management`:

```bash
claude plugin eval . --trust-plugin --tag core --runs 1 -j 4 --max-cost-usd 5 --no-publish
```

## Licence

The plugin is MIT. The two instruction skills derive from Anthropic's `claude-md-management` plugin and `creating-skills` from Anthropic's `skill-creator`, both Apache 2.0, with MIT-licensed writing guidance from other authors. The plugin's `NOTICE` lists every file.
