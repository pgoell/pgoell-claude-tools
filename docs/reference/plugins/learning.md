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

The quizzing skills ask multiple-choice questions through the host's question tool, with the right answer shuffled and hidden until you submit. They do not finish until you have shown you understand every item.

## Licence

Original MIT work. The quiz and survey skills adapt ideas from Thariq Shihipar; `rebuilding-a-concept` joins Toeplitz's genetic method with Lakatos's proofs and refutations. No upstream text is vendored; the README credits the sources.
