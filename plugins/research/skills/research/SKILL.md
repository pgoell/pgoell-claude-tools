---
name: research
description: Research complex topics with sources, synthesis, review, and a final report. Starts every research job by clarifying the ask one question at a time (topic, scope, audience, purpose, deliverable, deadline), then writes brief.md, gets the user's approval and hands over to research:running-research. Not for simple factual questions.
---

# Research Skill

Clarify a research ask into an approved brief. This skill asks, writes `brief.md` and hands over. It does not plan, search or write the report; `research:running-research` does that once the user calls it.

---

## Auth Approach

No authentication required. Writes one file to the local filesystem.

## Tool Preference

1. **Conversation**: ask the user, one question per message.
2. **File write tools**: write and update `brief.md`.
3. **Shell**: create the output folder and generate the date.

## Platform Adaptation

Use the host platform's equivalent tools without changing the workflow:

| Capability  | Claude Code                    | Codex                                       |
| ----------- | ------------------------------ | ------------------------------------------- |
| Ask a user  | AskUserQuestion, or plain text | `request_user_input` if present, else text  |
| File writes | Write, Edit                    | `apply_patch` or equivalent file edit tools |
| Shell       | Bash                           | shell command tool                          |

Cursor: ask in plain text and write with its file edit tools.

## Workflow

### Step 1: Read what the ask already answers

The brief has these fields:

- **Topic**: what to research.
- **Scope**: time span, place, and what is in and what is out.
- **Audience**: who reads the result.
- **Purpose**: the decision or use the research serves.
- **Deliverable**: form (full report, short summary, comparison table), length, and language. Format follows from it: `html` unless the user asks for markdown.
- **Deadline**: when the user needs it, or none.

Fill each field the request already answers, in the user's own words. Do not ask about those.

### Step 2: Ask one question at a time

For each empty field, ask one question, then wait for the answer before you ask the next. Never bundle several fields into one message. Offer choices where they fit (for example: "Who reads this: you alone, co-owners, or a client?"). Ask the highest-leverage fields first: purpose and deliverable shape the whole job.

When an answer opens a new gap (the purpose names a decision, but not by when), ask about that too. Stop when every field holds a real answer. "No deadline" is a real answer; an empty field is not.

Do not guess a field and do not fill one with a default the user never chose. The one exception is the output path: default `reports/{topic-slug}-{YYYY-MM-DD}/` (the date from `date +%F`), unless the user names another.

### Step 3: Write brief.md

Create the folder with `mkdir -p {OUTPUT_PATH}` and write `{OUTPUT_PATH}/brief.md`:

```markdown
# Research Brief

Status: draft

Topic: <topic>
Scope: <time, place, in and out>
Audience: <audience>
Purpose: <decision or use>
Deliverable: <form, length, language>
Format: <html | markdown>
Deadline: <date, or none>
Output path: <OUTPUT_PATH>
```

If the folder is not writable, suggest another path and ask the user.

### Step 4: Show the brief and wait

Show the user the full brief and ask them to approve it or change it. Wait for the answer. Apply each change to `brief.md` and show it again. Repeat until the user approves. An approval that carries a change ("approved, but add X") counts as approval: apply the change and show the changed line, without another round.

When the user approves, change the line `Status: draft` to `Status: approved`. `research:running-research` refuses a brief without that line.

### Step 5: Hand over

Your terminal step is to recommend the next skill: tell the user to run `/research:running-research`, and give the path to `brief.md`. Do NOT invoke it yourself.

This skill does not plan, search the web, dispatch researchers, or write `plan.md`, research notes or the report. Those belong to `research:running-research`, which reads the approved brief in its first step. Stop once you have recommended it.

## Self-Healing

- The user answers a question with "you decide": offer two or three concrete choices and ask them to pick one.
- The user wants to skip the questions: say which fields are still empty and why each one changes the result, then ask for the most important one.
- Output folder not writable: suggest another path, ask the user.
- An old `brief.md` already sits at the path: show it and ask whether to reuse it, change it, or pick a new path.

## Behavioral Guidelines

- Trigger on research intent, not simple factual questions.
- When in doubt, ask: "Would you like me to run a thorough research investigation, or just answer from what I know?"
- One question per message, always.
- Never write any file other than `brief.md`.
