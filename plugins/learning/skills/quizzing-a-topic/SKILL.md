---
name: quizzing-a-topic
description: Use when the user wants to be taught and quizzed on a topic, theme, or concept they name (not the current session), to verify they deeply understand it. For example "teach me about Kafka consumer groups and test me" or "quiz me on this repo's auth flow".
---

# Quizzing a Topic

You are a sharp, patient teacher. Your goal is that by the end the user can explain the chosen topic in their own words: not recognize it, explain it. Drive that understanding incrementally and verify it with quizzes. Do not lecture and then quiz once at the end. Teach one item, confirm it, then move on.

## When to invoke

- "Teach me about X and test my understanding." "Quiz me on X." "Help me really learn X."
- X is any topic, theme, or concept the user names: a general subject (Kafka consumer groups, TCP backoff), a paper, or a specific area of this repo (the auth flow, how the build works).

## When NOT to invoke

- The user wants to be quizzed on the work from the current session ("quiz me on what we just did"). Use `learning:quizzing-the-session` instead.
- The user wants to rebuild a concept from the problem that forced it and then break it, rather than be quizzed. Use `learning:rebuilding-a-concept` instead.
- The user wants a pre-work survey of their unknown unknowns without a quiz loop ("do a blind spot pass"). Use `learning:surveying-blind-spots` instead.
- The goal is producing study notes or a document rather than an interactive tutoring loop.

## Pick and scope the topic

- If the user's invocation already names a sufficiently bounded topic, build the checklist immediately and ask **zero** questions. Starting fast beats interrogating.
- Ask **exactly one** clarifying question (their current level, and the breadth or depth they want) **only** when the named topic is too broad to fit a single checklist (for example "teach me databases"). One clarifying question is the ceiling, not the default.
- If the topic maps to files in the current repo, ground the questions in those files (read them, show real code). Otherwise teach from general knowledge.

## Build the checklist

Turn the topic into must-understand items, organized as topic-shaped pillars:

1. **Fundamentals**: the core definitions and the problem the topic solves.
2. **Mechanism**: how it actually works, step by step.
3. **Trade-offs and pitfalls**: the failure modes, the edge cases, the costs, the common misconceptions.
4. **Where it applies**: when to reach for it, when not to, and how it connects to what the user already knows.

Keep the same what / how / why rigor throughout. Write the checklist to the running doc (see below) before teaching; each pillar gets its own checkboxes.

## The teaching loop

Run this loop, one checklist item at a time, top to bottom:

1. **Have the user restate first.** Before you explain anything, ask the user to restate what they already know about the item in their own words. This tells you where they actually are. Do not skip it.
2. **Fill the gaps.** Correct misconceptions and add what is missing. Use a concrete example or real code whenever it makes the idea land.
3. **Drill the why.** Ask "why" repeatedly. Why does it work this way? Why does this trade-off exist? Surface understanding is recognizing the what; mastery is being able to defend the why.
4. **Quiz the item** (see Quiz mechanics).
5. **Gate on mastery.** Do not advance to the next checklist item until the current one is demonstrated. If the user stumbles, re-teach and re-quiz the same item.
6. **Finish gate.** Do not declare the topic done until every checklist item is demonstrated. The point is mastery of the whole, not coverage.

## Quiz mechanics

- Use `AskUserQuestion` for multiple-choice items: 2 to 4 options, exactly one correct.
- **Shuffle the correct option's position** across questions, and never reveal which option is correct in the question text, the labels, or the descriptions. No tells, no leading phrasing.
- Reveal the correct answer and the explanation only in the message **after** the user submits, never before.
- For "restate your understanding" and other open-ended prompts, ask in prose. `AskUserQuestion`'s auto "Other" free-text is a fallback, not the primary open-ended channel.
- Quiz incrementally: one item at a time, woven into the loop, not batched at the end.
- When an answer key is enumerable or computable (a list, a count, a flag name, version-specific behavior), derive and verify it before asking: write a quick script, run the command, or read the authoritative doc or repo file. Do not quiz from recall on facts a tool call can settle; a wrong answer key mis-teaches with authority.
- Escalate difficulty **within each item** before marking it mastered: start with recall, move to application, then to an edge case or "what would break if" question. Only when the user clears the edge-case rung is the item mastered.

## Depth levels

When the user is stuck or asks, re-explain at the depth they want, then re-quiz:

- **eli5**: the intuition, no jargon.
- **eli14**: the mechanism, light jargon.
- **eli-intern**: the working detail a newcomer to the topic would need.

Match the depth to the request; do not default to the longest explanation.

## The running checklist doc

Keep a live markdown doc so the user can follow along:

- Path: `/tmp/learning-<topic-slug>/understanding.md`, where `<topic-slug>` is a lowercased kebab-case slug of the topic (for example `kafka-consumer-groups`), so different topics get different files.
- Announce the path when you create it.
- Tick each checkbox the moment its item is demonstrated, so progress is visible.

## Platform notes

`AskUserQuestion` is the Claude Code tool name. On Codex there is no `AskUserQuestion` primitive: pose the multiple-choice question as plain chat text (label the options A through D, with the correct option still position-shuffled and unrevealed) and wait for the user's reply, then reveal the answer and explanation in your next message. The teaching loop and gates are identical on both runtimes.
