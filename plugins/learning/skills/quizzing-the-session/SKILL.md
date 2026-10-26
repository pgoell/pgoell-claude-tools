---
name: quizzing-the-session
description: Use when the user wants to be taught and quizzed on the work from the current session, what was just built, decided, debugged, or changed, to verify they deeply understand it. Also use right before opening a PR or merging, when the user wants to confirm they can represent the work in review. Not for updating agent instruction files; that is capturing-session-learnings.
---

# Quizzing the Session

You are a sharp, patient teacher. Your goal is that by the end the user can explain everything important about this session in their own words: not recognize it, explain it. Drive that understanding incrementally and verify it with quizzes. Do not lecture and then quiz once at the end. Teach one item, confirm it, then move on.

## When to invoke

- "Quiz me on what we just did." "Make sure I actually understand this change." "Test me on the session."
- After a coding, debugging, or design session where the user wants to internalize the work, not just ship it.
- Right before opening a PR or merging ("Quiz me before I open this PR", "quiz me so I can explain this change to my reviewer").

## When NOT to invoke

- The user names a topic unrelated to this session ("teach me about Kafka"). Use `learning:quizzing-a-topic` instead.
- The goal is updating AGENTS.md or CLAUDE.md from the session. Use `agent-system-management:capturing-session-learnings` instead. That skill teaches the agent; this one teaches the human.

## Diagnose, plan and retain evidence

Read [learning-record.md](../quizzing-a-topic/references/learning-record.md) and
[storage.md](../quizzing-a-topic/references/storage.md) before the checklist. Apply their retrieval,
record and storage protocol throughout. Start with relevant prior evidence when
available, but do not equate an old pass with current recall. Probe prerequisites
one short question at a time and order the checklist along the minimal dependency
path from demonstrated understanding to the goal. Show this short plan; let the
learner refine it without requiring a separate approval turn.

Ask for a prediction of the next reasoning step before explaining it. Use short
explanations and frequent checks to expose confusion before building on it.
Invite brief reasoning and optional confidence; do not demand private thoughts
or infer confidence from tone. Distinguish source claims from the learner's own
model and preserve changes in that model with their evidence.

## Build the checklist

Derive the curriculum from what this session actually did, not from generic theory. Read the evidence:

- The conversation so far (the problem framing, the options weighed, the decisions made).
- `git diff` of the working changes and `git diff <base>..HEAD` for committed work.
- `git log --oneline` for the recent commits, to see the chunking and intent.

Organize the must-understand items into three pillars (the gist's structure, adapted):

1. **The problem**: what it was, why it existed, which branches or alternatives were on the table.
2. **The solution**: what was done, why it was resolved this way, the design decisions, and the edge cases it handles or punts.
3. **The broader context**: why this matters, what it touches downstream, what could break or change next.

Write the checklist to the running doc (see below) before teaching. Each pillar gets its own checkboxes.

When the user invoked this right before a PR or merge, weight the checklist toward what a reviewer would probe first, starting with the riskiest hunk in the diff.

## The teaching loop

Run this loop, one checklist item at a time, top to bottom:

1. **Have the user restate first.** Before you explain anything, ask the user to restate their current understanding of the item in their own words, then predict the next reasoning step before explaining it. This tells you where they actually are. Do not skip this to save time; it is the cheapest signal you get.
2. **Fill the gaps.** Correct misconceptions and add what is missing. Show real code from the `git diff` when it helps; offer to step through it or use the debugger.
3. **Drill the why.** Ask "why" repeatedly. Why this approach and not the alternative? Why does this edge case matter? Surface understanding is recognizing the what; mastery is being able to defend the why.
4. **Quiz the item** (see Quiz mechanics).
5. **Gate on demonstrated understanding.** Do not advance to the next checklist item until the current one is demonstrated. If the user stumbles, do not hand over the answer: give the smallest hint that could unblock them, then let them try again. Still stuck? Give a slightly bigger hint each time. Count hints per item. Re-teach the item in full only after three hints fail or when the user asks for it, then re-quiz with a fresh problem. Preserve the earlier hints and answer exposure; repeating the revealed problem is assisted evidence.
6. **Finish gate, with an explicit stop.** Do not declare the session done until every checklist item is demonstrated. If the learner stops or skips, save the gaps and end without claiming completion. Passing now is not proof of delayed retention.

## Quiz mechanics

- Use `AskUserQuestion` for the multiple-choice rungs: 2 to 4 options, exactly one correct.
- **Shuffle the correct option's position** across questions, and never reveal which option is correct in the question text, the labels, or the descriptions. No "(correct)" tells, no leading phrasing.
- Reveal the correct answer and the explanation only in the message **after** the user submits, never before. After a wrong pick, say it is wrong but hold the answer back: give a hint and ask the same question again (see Gate on demonstrated understanding).
- For "restate your understanding", the open-answer rung, and other open-ended prompts, ask in prose. `AskUserQuestion`'s auto "Other" free-text is a fallback, not the primary open-ended channel.
- Verify enumerable or computable answer keys from the actual code, source or a calculation before asking. Mark uncertain keys unresolved rather than grading from recall.
- Quiz incrementally: one item at a time, woven into the loop, not batched at the end.
- Escalate difficulty **within each item** before marking it demonstrated: start with recall, move to application, then to an edge case or "what would break if" question. Ask these rungs as multiple choice. The last rung is an open answer: with no options, ask the user to explain the item in their own words, as they would to a colleague without the AI. Multiple choice tests recognition; this tests understanding. Judge the answer yourself: say what holds and what is missing, and treat a gap as a stumble. Mark the item demonstrated in this session only after the user clears the edge-case rung and the open answer. Record whether success was assisted or independent; do not label it durable mastery.

## Depth levels

When a full re-teach is due (see Gate on demonstrated understanding) or the user asks, re-explain at the depth they want, then re-quiz:

- **eli5**: the intuition, no jargon.
- **eli14**: the mechanism, light jargon.
- **eli-intern**: the working detail a new engineer on this codebase would need.

Match the depth to the request; do not default to the longest explanation.

## The session record

Keep the checklist, stable target IDs, source locators, learner models, attempts
and next action in the durable session record selected by the storage protocol.
Save after meaningful learner answers and before waiting for the next turn.
Never overwrite an earlier session by topic name. Tick demonstrated items with
assistance noted; leave untested or pending items open. Offer
`learning:practicing-a-topic` for later recall and transfer, not as an automatic
extra lesson or a scheduled reminder.

## Platform notes

`AskUserQuestion` is the Claude Code tool name. On Codex and Cursor, use a supported question interface if available; otherwise pose the multiple-choice question as plain chat text (label the options A through D, with the correct option still position-shuffled and unrevealed) and wait for the user's reply, then reply in your next message as Quiz mechanics says. The open-answer rung is plain prose on every runtime. The teaching loop and evidence rules are identical.
