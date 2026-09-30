---
name: ghostwrite
description: Use when the user wants a piece of writing drafted for them, such as a blog post, essay, talk script, client memo, briefing, email, decision doc, README, how-to guide, design doc, or pull request description. Interviews the owner or takes dictation, uses only facts from the owner, documents the owner supplies, or the repository, and hands back a plain draft for the owner's final edit. For feedback that teaches the owner to write the piece themselves, see the coach skill. For slide decks, see the presentations plugin.
---

# Ghostwrite Skill

Draft a finished piece whose every claim, fact, and story comes from the owner or from a source the owner points at. The model writes the sentences; the owner supplies the substance and has the last word.

---

## The rule this skill exists for

**No fact comes from the model's own head.** Every claim, number, anecdote, quote, step, command, and rationale traces to one of three sources: the owner (interview or dictation), a document the owner supplies, or the repository (code, existing docs, and commands you actually ran). When a sentence needs something none of those gave you, do not invent it. Ask, or mark the gap inline (see Step 6).

Why: AI prose cannot be scrubbed into a person's voice after the fact, and invented specifics are the fastest way to make a piece both wrong and obviously not the owner's. Specifics from the owner are the only reliable source of voice this skill has.

## Platform mapping

Use the host's equivalent tools without changing the workflow:

| Capability          | Claude Code                         | Codex                                                            |
| ------------------- | ----------------------------------- | ---------------------------------------------------------------- |
| Ask the owner       | AskUserQuestion, or a plain message | Ask a short direct question in the reply                         |
| Subagent (optional) | Agent tool                          | `spawn_agent` when available and permitted; otherwise run inline |
| File reads          | Read, Glob, Grep                    | shell reads (`sed`, `rg`) or file read tools                     |
| File writes         | Write, Edit                         | `apply_patch` or file edit tools                                 |
| Shell               | Bash                                | shell command tool                                               |

All dialogue with the owner runs in the main thread. Subagents cannot ask the user questions, so never hand the interview, the outline sign-off, or a check-in to a subagent. Subagents only do work that needs no dialogue: the optional critics and the fresh-reader test in Step 7.

## Files this skill keeps

Keep owner files in `.pgoell/writing/` at the root of the current project (the git root, or the working directory when there is no repository), matching the `.pgoell/` convention the presentations plugin uses. If the project has none but `~/.pgoell/writing/` exists, read from and write to that instead.

- `.pgoell/writing/voice-note.md`: the owner's confirmed voice note plus the edit log. Format in `references/voice-note.md`.
- `.pgoell/writing/samples/`: two to five pieces the owner wrote themselves, if they have them.

Write the draft to a file the owner names. Default: `<slug>.md` in the working directory. Short pieces (an email, a PR description) can stay in the chat unless the owner asks for a file.

## Step 1: Pick the smallest workflow

Route by genre and length. The steps below are a map, not a gate: skip what the piece does not need.

| Genre                                           | Facts come from                                                       | Route                                                                                                            |
| ----------------------------------------------- | --------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| Blog post, essay, talk script                   | The owner, by interview or dictation                                  | Full: Steps 2 to 8. Owner does the final rewrite.                                                                |
| Client memo, briefing, decision doc             | The owner plus documents the owner supplies                           | Full, with pyramid audits at Step 5.                                                                             |
| Email                                           | The owner                                                             | Light: ask what the reader should do, put that first, draft, hand back.                                          |
| README, how-to, tutorial, reference, design doc | The repository and commands you run; rationale from owner or docs     | Medium: read the repo, run the commands, confirm the quadrant, draft, hand back. Load `references/tech-docs.md`. |
| Pull request description                        | The diff, the commits, and commands you ran; the "why" from the owner | Light: read the diff, ask one question (why was this change made?), draft.                                       |

A talk script is a spoken essay: treat it like one, and send slides to the presentations plugin. Say which route you picked in one line, and let the owner change it.

## Step 2: Gather the substance

Load `references/interview.md` for the question bank and the rules.

- **Owner-sourced genres.** Interview one question at a time, in the main thread, and wait for each answer. Offer dictation as the alternative: the owner talks through the piece in one go and you capture it. Do not suggest content, do not upgrade a tentative remark into a firm claim, and do not invent the connecting tissue between two things the owner said.
- **Supplied documents.** Read them in full. Quote numbers exactly as they appear and note where each came from.
- **Repository-sourced genres.** Read the code, the existing docs, and the config. Run the commands the doc will tell the reader to run (install, build, test, `--help`) and record what they print. If a command cannot run here, say so and mark the step as unverified. Never write a command, flag, or output from memory.

If the owner says "just write it" and gives you notes, work from the notes alone. Do not fill gaps from general knowledge; mark them.

## Step 3: The throughline

Ask the owner for the one sentence the reader should remember. The owner writes it; keep it verbatim. If it runs long or hedges both ways, ask once more with the reason ("a reader who remembers one thing, remembers what?"), then accept their answer. For tech docs the throughline is the reader's goal (what they can do after reading); for a reference doc it is the schema being complete instead.

## Step 4: Voice evidence

Skip this step for PR text and reference docs. For every other genre, load `references/voice-note.md`.

- Read `.pgoell/writing/voice-note.md` if it exists. If not, offer to start one: ask for two to five pieces the owner wrote themselves, read them, and propose at most five recurring habits and anti-patterns. Only entries the owner confirms go into the note.
- Treat samples as evidence for the note's rules, not as a corpus to imitate. Do not borrow another writer's samples as the owner's voice.
- The default register is plain: short words, active verbs, concrete nouns, no signature moves, no persona, no invented anecdotes, no rhetorical flourishes the owner did not use.

## Step 5: Outline, then owner sign-off

Write a short outline: the throughline, then one line per section saying what the section claims and which source backs it. Show it to the owner and wait for sign-off before drafting.

- **Work documents** (memo, briefing, decision doc, email longer than a few paragraphs): run the four audits in `references/pyramid-audits.md` on the outline and report the findings next to it. Answer first is the default; if the reader is hostile or uninformed, offer the owner the escape hatch described there. Do not fix the outline yourself; the owner decides.
- **Tech docs:** state the Diataxis quadrant (tutorial, how-to, reference, explanation) and confirm it. For a reference doc, fill the matching schema from `references/tech-docs.md` and mark missing fields `<unknown>`.

## Step 6: Draft section by section

Draft one section at a time. After each section (or each two or three short ones), show it and ask whether it says what the owner meant. Carry their corrections forward.

- Mark every bridge you had to build inline, where the reader of the draft will see it: `[assumption: <what you assumed and why>]`. Mark missing facts as `[owner: <what is needed>]`. Never smooth over a gap to make the prose read better. Small qualifiers count as facts too: "without any warning", "for a while", "always", "most teams" need a source or a marker.
- Follow the voice note. Where the note says nothing, stay plain.
- House punctuation: no em-dashes or en-dashes, no middle-dot separators, no hyphen standing in for a dash. Use commas, periods, colons, semicolons, or parentheses.
- Tech docs: every command and output in the draft is one you ran or read in the repository. Label anything you could not run as unverified.

## Step 7: One review, reported and not applied

Load `references/review.md`. Run one light tell check on the draft yourself and list what it finds. Then offer, and run only if the owner wants them:

- the argument critics (Asshole reader, Steel-man, Clarity), for pieces that argue a point;
- a fresh-reader test, for any piece whose reader lacks the owner's context.

Run each optional reviewer in its own subagent where the host supports it. Give each one only the draft and its reviewer prompt: no interview notes, no outline, no other reviewer's notes. Collect the reports and show them to the owner as they are.

**Never rewrite the draft because a reviewer flagged something.** Report, then ask the owner which points to act on. Apply only the changes the owner picks, and apply them where the owner says.

## Step 8: Hand back and learn

- Hand back the draft with a short list of the open `[assumption: ...]` and `[owner: ...]` markers.
- For first-person pieces (blog, essay, talk, anything with "I"), tell the owner plainly that the draft is a starting point and that the final pass should be theirs. The measure of success is whether their rewrite took less time, not whether the draft already sounds like them.
- When the owner edits the draft, or tells you what they changed, compare their version with yours and log the recurring edits in the voice note's edit log (format in `references/voice-note.md`). Propose a new voice-note rule only when the same edit shows up in two or more pieces, and add it only when the owner confirms.
- Optional drift check: count contractions and first-person pronouns per 100 words in the draft and in the owner's samples, and report the gap.

## Self-healing

- **The owner will not answer questions.** Draft from what you have, with every gap marked. Do not fill gaps from general knowledge.
- **A repository command fails.** Report the error, do not guess the output, and mark the step unverified. Ask the owner whether to fix the environment or ship with the marker.
- **The owner asks you to "make it sound like me" with no samples and no note.** Explain that the draft will be plain, ask for samples or a dictated paragraph, and proceed plain if they have none.
- **The owner asks to learn instead** ("show me how to fix this myself"). Switch to the coach skill.
- **The request is a slide deck.** Hand it to the presentations plugin.

## Behavioral guidelines

- Ask one question at a time. Batching questions gets short answers and lost detail.
- Say which step you are on in one line; do not narrate the workflow.
- Prefer a marked gap to a smooth sentence. A marked gap costs the owner ten seconds; an invented fact can cost them their credibility.
- Keep reviewer output short and specific. Do not paste scores or verdict tables at the owner.
