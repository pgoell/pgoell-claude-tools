# Writing

Two skills with opposite rules about who writes the sentences.

## Skills

- `/writing:ghostwrite`: Drafts a piece for you from your own facts. It interviews you or takes dictation, uses only what you, your documents, or the repository supply, marks every assumption inline, runs one round of review that reports and never rewrites on its own, and hands back for your final edit. It also rewrites or reviews a draft that already exists: a rewrite keeps every fact, hedge, and attribution and marks what only you can supply; a review reports and changes nothing.
- `/writing:coach`: Teaches you to write through your own drafts. You write first; it raises one issue per round, explains the principle, shows a worked example on one of your sentences, and has you revise and explain the change back. It never writes the piece.

The voice note is global, at `~/.pgoell/writing/voice-note.md` (your confirmed habits, the standards your pieces must meet, and a log of the edits you make to drafts), with optional samples in `~/.pgoell/writing/samples/`. Notes on readers you write for again and again live per project, at `.pgoell/writing/readers.md`. The coach log is per project, at `.pgoell/writing/coach-log.md` (intake, current drill, recurring faults). The eval suite for both skills lives in `evals/`.

## Evals

Run from `plugins/writing`:

```bash
claude plugin eval . --trust-plugin --scaffold --allow-tools Bash Write Edit --tag core --runs 1 -j 4 --judge-model sonnet --max-cost-usd 20 --no-publish
```

`--tag core` runs every case except `11-ghostwrite-no-invention`, which carries the `known-limit` tag. That case asks for a blog draft with no questions allowed, and ghostwrite still adds a few unmarked bridging sentences. The research behind this plugin expects that limit for first-person pieces, which is why the owner does the final rewrite. Run it alone with `--tag known-limit` to track whether a rule change moves it.

## Comparing writing skills

`judge/` holds a blind comparison of writing skills: eleven cases (`cases.json`) and a protocol (`JUDGE.md`), both from Addy Osmani's Clarity, seven cases of this repository's own (`cases-own.json`), and `compare.py`, which runs them. Each case runs in a fresh `claude -p` session under every condition; a second model then sees the answers without their names, applies the hard gates (an invented fact, a broken mode, damaged structure, an obeyed instruction from the source text), and scores what passes. Each case is judged three times, each time in a new shuffle, and an answer fails a gate only when two of the three judgings fail it.

Run from the repository root. A condition is a name, or `name=<skill invocation>@<plugin folder>`:

```bash
uv run python3 plugins/writing/judge/compare.py run --out /tmp/cmp \
  --condition baseline \
  --condition ghostwrite=/writing:ghostwrite@plugins/writing \
  --condition other=/other-plugin:other-skill@/path/to/other-plugin
uv run python3 plugins/writing/judge/compare.py judge --out /tmp/cmp
uv run python3 plugins/writing/judge/compare.py report --out /tmp/cmp
```

`run` writes with Sonnet and `judge` scores with Opus unless `--model` says otherwise; a model should not judge its own output. `run --cases plugins/writing/judge/cases-own.json` picks the own set, and `judge --judgings N` changes how often each case is judged.

The own cases cover what Clarity's set leaves out: a memo from notes, a voice note, a reader note, pull request text from a diff, a README from a manifest, a dictated post, and a review of an email with a buried ask. Keep them as a holdout: do not tune a skill against them, or their numbers stop meaning anything. A step that fails part-way keeps what it finished, so run it again. The report lands in `<out>/report.md`. A skill that ships as a bare `SKILL.md` needs a plugin folder around it first: `<folder>/.claude-plugin/plugin.json` and `<folder>/skills/<name>/SKILL.md`.

Read the numbers with care. Seven of Clarity's eleven cases are rewrites, no case tests the coach, two runs per condition is a small sample, and one model judge is not a human reader.

Last run, 2026-11-12, Sonnet writing and Opus judging, two outputs per case and condition, three judgings per case, eight outputs in front of the judge. The run predates the Self-healing line on a refused file write.

Clarity's cases (22 outputs per condition):

| Condition        | Hard-gate failures | Split gate votes | Mean rank (of 8) | Mean score |
| ---------------- | ------------------ | ---------------- | ---------------- | ---------- |
| No skill         | 7                  | 7                | 6.59             | 3.49       |
| ghostwrite 3.1.8 | 0                  | 0                | 4.83             | 3.81       |
| Clarity 0.2.1    | 1                  | 1                | 3.64             | 4.23       |
| ghostwrite 3.2.0 | 0                  | 1                | 2.94             | 4.39       |

Own cases (14 outputs per condition):

| Condition        | Hard-gate failures | Split gate votes | Mean rank (of 8) | Mean score |
| ---------------- | ------------------ | ---------------- | ---------------- | ---------- |
| No skill         | 5                  | 2                | 6.21             | 3.75       |
| ghostwrite 3.1.8 | 0                  | 0                | 4.69             | 3.77       |
| Clarity 0.2.1    | 1                  | 0                | 3.98             | 4.20       |
| ghostwrite 3.2.0 | 0                  | 0                | 3.12             | 4.17       |

ghostwrite was tuned on Clarity's cases over several rounds, so its numbers there flatter it; the own cases were written after the tuning and not used for it. On single judgings of the same outputs a condition's mean score moved by up to 0.13, so treat a smaller gap as a tie. `run` allows the tools Read, Skill, Glob and Grep only, so a skill that insists on writing a file loses marks when it replies with a path.

`tests/run.sh` drives `compare.py` through all three steps with a fake `claude` binary and no network. Last result: 12 passed, 0 failed.

Version 3.0.0 replaced the earlier `writing`, `pyramid`, and `tech-doc` skills, which now sit in the `deprecated` plugin.

## Inspiration

The design follows the research report `writing-plugin-redesign-2026-09-30`. Several ideas are adapted, in this repository's own words, from these sources; no upstream text is vendored:

- EveryInc's [compound-writing](https://github.com/EveryInc/compound-writing): the smallest-useful-workflow front door, the interview authorship boundary, marking model-added assumptions, and treating samples as evidence for voice rules. Added in 3.1.0: the tell check that compares the draft with its sources before looking at words, the voice check, the split of voice, standards, and reader notes, and sorting each confirmed lesson into one of them.
- Addy Osmani's [Clarity](https://github.com/addyosmani/clarity) (MIT). Added in 3.2.0: the rewrite and review routes for a draft that already exists, the order of work for a rewrite, the two tests for a sentence that only sounds good, the table of what each medium owes its reader, the review calls (keep, revise, ask the owner, cut), the long untidied take that opens an essay interview, the three-question limit when a draft exists, source text treated as data, and the note on where the material came from. The comparison in `judge/` uses Clarity's cases and protocol verbatim; see `NOTICE`.
- Anthropic's [doc-coauthoring skill](https://github.com/anthropics/skills/tree/8a1541c4a3ffa5a20a5a91de0dcf3f0bab1d1ef4/skills/doc-coauthoring): the fresh-reader test run by a subagent that sees only the document.
- Joseph M. Williams' _Style_: the sentence and cohesion principles behind the coach's drills 3 and 4.
- Barbara Minto's Pyramid Principle: the structure audits, carried over from the retired `pyramid` skill.
- The Diataxis framework: the four tech-doc quadrants, carried over from the retired `tech-doc` skill.

Original work is MIT licensed. The two files vendored from Clarity keep their MIT license and copyright, as `NOTICE` records.
