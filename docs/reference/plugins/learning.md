---
type: Reference
title: The learning plugin
description: The skills that teach you, quiz you to mastery, survey your blind spots, or rebuild a concept with you.
tags: [plugin, learning, quiz, teaching]
status: stable
---

# learning

Skills that teach the human rather than do the work: two teach-and-quiz loops, a blind-spot survey before new work, and a loop that rebuilds a concept from its origin and then tries to break it.

**Runtimes:** Claude Code, Codex, Cursor

**Source:** vendored in `plugins/learning/`; see the [plugin README](../../../plugins/learning/README.md) for details and credits.

**Setup:** None beyond install.

## Skills

| Invocation                        | What it does                                                                                                                                                                                                       |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `/learning:quizzing-the-session`  | Build a problem, solution and impact checklist from the current session and recent git activity, then teach and quiz you item by item until you show you understand each one. Fits right before a PR or merge.     |
| `/learning:quizzing-a-topic`      | The same loop for any topic you name, grounded in repo files when the topic is local code.                                                                                                                         |
| `/learning:surveying-blind-spots` | Before you start in a codebase area or field you do not know, survey your unknown unknowns, gotchas and dead ends, then hand you rewritten prompts. A briefing, not a quiz.                                        |
| `/learning:rebuilding-a-concept`  | Start from the problem that forced a concept, sketch your own fix, break it with counterexamples, repair it, and only then compare with the textbook version. Works for maths and for designs such as data models. |

The quizzing skills ask multiple-choice questions through the host's question tool, with the right answer shuffled and hidden until you submit, and end each item with an open question you answer in your own words. When you get stuck, you get the smallest hint that could help, then a slightly bigger one; a full re-teach comes only after three hints fail or when you ask. They do not finish until you have shown you understand every item.

## Evals

`plugins/learning/evals/` holds 14 `claude plugin eval` cases that test when the four skills fire. Cases 01 to 04 are triggers, one per skill: the skill must fire and the other three must not. Case 01 pastes a diff and asks for a quiz before the PR (`quizzing-the-session`); 02 asks for `quizzing-a-topic`, 03 for `surveying-blind-spots` and 04 for `rebuilding-a-concept`. Cases 21 to 23 are negatives (a one-paragraph concept answer, a translation, a fix to a pasted snippet): no learning skill may fire.

Cases 31 to 34 are near-misses between sibling skills, the pairs the skill descriptions name as easy to confuse. In each, one skill must fire and the other three must not. Case 31 wants a quiz on a tool the session never touched (Celery), so `quizzing-a-topic` fires, not `quizzing-the-session`. Case 32 pastes today's change and asks to be checked on it, point by point, before merge, and never says "quiz", so `quizzing-the-session` fires, not `quizzing-a-topic`. Case 33 wants the user's unknown unknowns, not a lesson, so `surveying-blind-spots` fires, not `quizzing-a-topic`. Case 34 wants to build the design themselves and then poke holes in it, so `rebuilding-a-concept` fires, not `quizzing-a-topic`.

Cases 35 to 37 are near-misses outside the plugin: no learning skill may fire, and an `llm` grader checks the reply. Case 35 asks for a lesson line from the session to add to `CLAUDE.md`. Case 36 asks for a printable SQL joins quiz with an answer key for students. Case 37 asks for a PR description from a pasted diff.

Every case allows only Skill, Read, Glob and Grep, so no case needs network or a shell. The graders match full names such as `learning:quizzing-a-topic`, so a word in a call's args does not match.

No one has run the suite yet; a run costs money, so the user decides when. Run from `plugins/learning`:

```bash
claude plugin eval . --trust-plugin --tag core --runs 1 -j 4 --max-cost-usd 5 --no-publish
```

## Licence

Original MIT work. The quiz and survey skills adapt ideas from Thariq Shihipar; `rebuilding-a-concept` joins Toeplitz's genetic method with Lakatos's proofs and refutations. No upstream text is vendored; the README credits the sources.
