# Writing

Two skills with opposite rules about who writes the sentences.

## Skills

- `/writing:ghostwrite`: Drafts a piece for you from your own facts. It interviews you or takes dictation, uses only what you, your documents, or the repository supply, marks every assumption inline, runs one round of review that reports and never rewrites on its own, and hands back for your final edit.
- `/writing:coach`: Teaches you to write through your own drafts. You write first; it raises one issue per round, explains the principle, shows a worked example on one of your sentences, and has you revise and explain the change back. It never writes the piece.

Both keep their files in `.pgoell/writing/` at the root of your project: `voice-note.md` (your confirmed habits and a log of the edits you make to drafts) and `coach-log.md` (intake, current drill, recurring faults). The eval suite for both skills lives in `evals/`.

Version 3.0.0 replaced the earlier `writing`, `pyramid`, and `tech-doc` skills, which now sit in the `deprecated` plugin.

## Inspiration

The design follows the research report `writing-plugin-redesign-2026-09-30`. Several ideas are adapted, in this repository's own words, from these sources; no upstream text is vendored:

- EveryInc's [compound-writing](https://github.com/EveryInc/compound-writing): the smallest-useful-workflow front door, the interview authorship boundary, marking model-added assumptions, and treating samples as evidence for voice rules.
- Anthropic's [doc-coauthoring skill](https://github.com/anthropics/skills/blob/main/skills/doc-coauthoring/SKILL.md): the fresh-reader test run by a subagent that sees only the document.
- Joseph M. Williams' _Style_: the sentence and cohesion principles behind the coach's drills 3 and 4.
- Barbara Minto's Pyramid Principle: the structure audits, carried over from the retired `pyramid` skill.
- The Diataxis framework: the four tech-doc quadrants, carried over from the retired `tech-doc` skill.

Original work is MIT licensed.
