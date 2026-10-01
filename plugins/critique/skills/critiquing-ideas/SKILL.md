---
name: critiquing-ideas
description: Use when the user wants an idea, plan, decision, claim, or situation critiqued from several independent angles instead of one agreeable answer, for example "critique this", "poke holes in my plan", "pre-mortem this decision", "red-team this idea", or "quick critique". Sends one fresh subagent per thinking frame (pre-mortem, steelman for and against, outside view, and more), shows every frame's verdict word for word, and ends with one decision. Not for code review or for feedback on a prose draft.
---

# Critiquing Ideas

A critic that shares the author's context shares the author's framing, and agrees too easily. This skill strips the framing into a neutral brief, sends it to one fresh subagent per thinking frame, and reports what each frame found without softening it.

## When NOT to invoke

- Reviewing a code diff or PR: use the host's code review tooling.
- Feedback on a prose draft that argues a point: use `writing:ghostwrite` (review) or `writing:coach`.
- Mapping what the user does not know about an area before work starts: use `learning:surveying-blind-spots`.

## Modes

| Mode           | Frames                                                        | When                                |
| -------------- | ------------------------------------------------------------- | ----------------------------------- |
| Full (default) | 8 core frames, plus any conditional frame whose trigger holds | Any request without "quick"         |
| Quick          | pre-mortem, steelman-opponent, outside-view                   | The user says quick, fast, or short |

Frame texts, triggers, the brief template, and the synthesis prompt are in `references/frames.md`. Read it before step 1 and send its texts verbatim.

## Protocol

1. **Write the brief.** Fill the brief template in `references/frames.md` from the user's input. Facts only, no author, no enthusiasm. Keep every stake the input names (deadline, budget, reversibility, who is affected), and write "not stated" for any it omits. If the input is too thin to fill SUBJECT and DETAILS, ask one question, then proceed.
2. **Pick frames.** Quick mode: the three quick frames. Full mode: all eight core frames, plus each conditional frame whose trigger holds. Record every conditional frame you left out, with the reason, for the report.
3. **Dispatch the frames.** One subagent per frame, all at once, each with a fresh context. Send the frame prompt from `references/frames.md` with the brief, the user's original words, and that frame's lens text. Never add your own view, the conversation history, or hints about what the user hopes to hear.
4. **Synthesize.** When every frame has returned, send the synthesis prompt to one more fresh subagent with the brief and every frame reply pasted verbatim. You do not write the synthesis yourself: you share the author's context, and synthesis is where softening creeps back in.
5. **Report**, in this order:
   - **Brief**: the brief exactly as sent, so the user can spot anything it dropped or slanted.
   - **Verdicts**: a table with one row per frame. The verdict cell holds the frame's VERDICT line word for word, including its one-sentence reason. Do not shorten, reword, or reorder the words.
   - **Frames**: which ran; in full mode, which conditional frames were left out and why.
   - **Decision**: the synthesis reply word for word (DECISION, KILL CONDITIONS, NEXT TEST, FINDINGS, DISAGREEMENTS).
   - One line offering any frame's full reply on request. Keep the full replies available for the rest of the session.

## Platform mapping

| Step            | Claude Code                                                                              | Codex                                                                                                                                                                         |
| --------------- | ---------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Dispatch frames | `Agent` tool, `general-purpose` type, every frame in one message so they run in parallel | Its subagent tool, one per frame. With no subagent tool, run each frame inline in turn, and state in the report that the frames shared context and so lost their independence |
| Synthesis       | One more `Agent` call after all frames return                                            | One more subagent; inline only under the same fallback and caveat                                                                                                             |

## Rules

- Report exactly what came back. Do not soften, merge, or editorialize frame or synthesis output, and do not add your own verdict unless the user asks for it after the report.
- "No material finding" is a valid frame result and a clean "proceed" is a valid decision. Never re-run a frame because its answer seems too mild or too harsh.
- If the user re-runs the critique on a reworded input, say in the report which run this is (for example "run 2 on this idea"), so repeated runs until the verdict pleases are visible.
- One frame failing or returning nothing: report it as failed in the verdict table and synthesize from the rest. Do not fill the gap yourself.
