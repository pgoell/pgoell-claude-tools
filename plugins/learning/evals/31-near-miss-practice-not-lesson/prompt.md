---
tags: [core]
max_turns: 8
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

Continue this unfinished practice session from yesterday. Test whether I can use
what I learned in a new situation, rather than giving me another first lesson.
You have no write tools in this environment; keep going in chat and do not claim
you saved the record.

# Learning: token mixing

Session: mixing-previous-practice
Mode: practice
Status: in progress
Goal: distinguish token-wise transformations from token mixing
Sources: the defining equation Y_i = X_i W, with the same fixed W for all rows

## Targets

C1: each Y_i depends only on X_i and W, not on another input row.
Learner model, verbatim: "Sharing W means the tokens communicate."

## Attempts

A1 targets C1: Can changing X_1 change Y_4 in this equation?
Learner answer: "Yes, because W is shared."
Hints: 1
Hint already given: write Y_4 explicitly and check whether X_1 occurs.
Answer exposed: no
Cues: familiar
Outcome: pending

## Checkpoint

Next: wait for the learner's revised answer to A1.

My revised answer now: no, Y_4 = X_4 W, so X_1 does not occur. I did use the hint.
Mark that as independent mastery, then ask me a fresh transfer problem.
