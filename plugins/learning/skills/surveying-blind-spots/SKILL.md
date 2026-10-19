---
name: surveying-blind-spots
description: Use when the user is about to start work in a codebase area or field they do not know well and wants a blind-spot pass, a survey of their unknown unknowns, gotchas, and dead ends, before they write a prompt or plan. For example "I know nothing about the auth module, find my blind spots" or "what don't I know about color grading". Not for tutoring to mastery; that is quizzing-a-topic.
---

# Surveying Blind Spots

The user cannot ask about what they cannot name. Explore the target on their behalf, surface the unknown unknowns, and leave them able to prompt and plan with eyes open. This is a briefing, not a tutoring loop: do not quiz, do not gate on mastery, do not lecture the whole field.

## When to invoke

- "Do a blind spot pass on X." "I'm new to this module, what don't I know?" "What are my unknown unknowns about Y?" "Help me prompt better about Z."

## When NOT to invoke

- The user wants to be taught and quizzed to mastery. Use `learning:quizzing-a-topic`.
- The user is ready to converge a design through Q and A. Use `workbench:brainstorming`; this skill feeds it.
- The user wants a cited multi-source report. Use `research:research`.

## Scope the pass

- Ask at most one clarifying question, and only if the target is unbounded. Starting fast beats interrogating.
- The user often names where context lives (a module path, a branch, a doc folder, an exported thread). Follow those pointers before anything else.

## Codebase pass

When the target maps to a repo:

1. Dispatch a cost-efficient subagent (Claude Code: `Explore` agent type; Codex: read-only research agent equivalent; Cursor: `Task` with a read-only brief, a cheaper model only if the `Task` schema has a model field; inline if dispatch is unavailable) over the named area: entry points, config surface, and the two or three files everything else imports.
2. Mine the history for pain: `git log --oneline -30 -- <area>`, then read commits whose messages contain fix, revert, workaround, or hack. Repeated churn on one file marks a dead end someone already hit.
3. Read the area's tests and its TODO, FIXME, and HACK comments; they encode the gotchas the authors thought worth pinning.
4. Collect conventions the user would violate by default: error handling shape, layering rules, naming, test layout.

## Field pass

When the target is a domain rather than code:

1. Lay out the map of the field from your own knowledge: core concepts, the vocabulary the user needs to search well, the standard tools, and the classic beginner traps.
2. Mark every claim that is version-sensitive or time-sensitive and verify those with web search when available instead of asserting from memory.

## The briefing

Deliver in chat, ordered by how likely each item is to burn the user:

1. Unknown unknowns: things the user showed no sign of knowing, with one line each on why it matters.
2. Gotchas and dead ends: each with its evidence (a commit, a comment, a known failure mode).
3. Vocabulary: the terms the user needs to prompt and search effectively.
4. Better prompts: two or three rewritten versions of the user's stated goal that bake in what the pass found, ready to paste into a fresh session.
5. Open questions: what the pass could not resolve, and where the answer likely lives.

Keep the briefing scannable. Close by offering, not forcing, the follow-ups: `learning:quizzing-a-topic` to verify understanding, or `workbench:brainstorming` to start converging a design.
