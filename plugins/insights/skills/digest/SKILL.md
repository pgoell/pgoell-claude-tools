---
name: digest
description: "Use when the user wants yesterday's (or a given day's) Claude Code sessions and newspaper runs checked for problems, for example \"run the session insights\", \"what went wrong in my sessions yesterday\", \"/insights:digest --vault ~/kasten-data/vault\", or when cron runs it headless at 05:30. Reads 14 days of transcripts through a script, groups recurring errors, guard refusals and typed corrections into problems, checks memory and the destination files, verifies causes where cheap, and proposes one concrete fix per problem on an HTML page in the kasten vault with a review note, linked from today's daily note. Not for acting on a reviewed note (use insights:apply)."
---

# Digest

Find what went wrong in one day of Claude Code sessions and in the
newspaper's runs, and propose a concrete fix for each problem. A script does
the reading and counting; you do the judgement: which shapes share a cause,
whether the cause is real, where the fix goes, and the fix itself. The output
is a page, a review note, and memory in the vault.

This may run headless from cron (`claude -p`). Never stop to ask a question.
Decide, and say what you decided in the final report. Ignore the token
`insights-self-run` in the prompt: it marks this job's own transcripts so the
next run skips them.

## Arguments

`/insights:digest [--vault PATH] [--date YYYY-MM-DD] [--periodic FOLDER]`

- **vault**: `--vault`, else `$KASTEN_VAULT`, else the working directory when
  it holds the periodic folder. If none applies, stop and say so.
- **date**: the day to analyse. `--date`, else yesterday in Europe/Berlin.
- **periodic**: `--periodic`, else `$KASTEN_PERIODIC_PATH`, else `01 Periodic`.

Below, `ARGS` stands for `--vault "<vault>" --periodic "<periodic>" --date <date>`,
`IN` for `<vault>/<periodic>/06 Insights` and `D` for the date.

## Protocol

1. **Seed.** `uv run "${CLAUDE_SKILL_DIR}/scripts/seed.py" ARGS`. It creates
   `IN/feedback.md`, `IN/memory/rules.md` and the memory files when missing,
   and lists in `to_apply` review notes renamed to `## Keep` and not yet
   applied.
2. **Apply reviewed notes.** For each date in `to_apply`, follow
   `../apply/SKILL.md` with that date. This is how a review done on the phone
   takes effect the next morning.
3. **Read feedback.** `IN/feedback.md` and `IN/memory/rules.md`. Turn each
   bullet under `## Open` into a rule line at the end of `rules.md`
   (`- D: the rule (from: the feedback, short)`), or, for a `no: #id reason`
   line, into a `rejected` verdict (step 9 records it). Move the bullet to the
   top of `## Applied` as `- D: <the words> -> <what changed>`. Follow every
   rule in `rules.md` from here on.
4. **Extract.**
   `uv run "${CLAUDE_SKILL_DIR}/scripts/extract.py" --date D --private "<vault>" --out /tmp/insights-D.json`.
   It takes seconds and prints how many shapes it kept. Read the whole digest:
   `shapes` (normalized errors with 14-day `series`, `commands`, examples),
   `typed` (what the user typed on D, main threads only, vault sessions
   withheld unless they touched `02 Projects/`), `newspaper_logs`, `sessions`
   and `scope`.
5. **Judge.** Read `references/judging.md` and `IN/memory/problems.jsonl`.
   Group shapes and typed text into problems, apply the bar, set each status
   from memory, grep each destination before claiming a rule is missing, and
   verify causes where a check is cheap. Write the fix as the exact change.
6. **Write `IN/D.json`** per `references/page-contract.md`: every problem
   over the bar, the `seen` rows, `window` and `scope` copied from the digest,
   and `newspaper_note` from the newspaper logs.
7. **Note.** `uv run "${CLAUDE_SKILL_DIR}/scripts/note.py" ARGS` writes the
   review note `IN/D.md`, one line per problem under `## Proposed`. It leaves
   a note alone once it was reviewed.
8. **Render.** `uv run "${CLAUDE_SKILL_DIR}/scripts/render.py" ARGS` checks
   the JSON and writes `IN/D.html`. Fix every error it lists and run it again
   until it renders.
9. **Remember.** `uv run "${CLAUDE_SKILL_DIR}/scripts/remember.py" ARGS`.
   If step 3 produced rejections, write them as a JSON list
   (`[{"fingerprint", "id", "verdict": "rejected", "reason"}]`) to
   `/tmp/insights-verdicts-D.json` and run
   `uv run "${CLAUDE_SKILL_DIR}/scripts/remember.py" ARGS --verdicts /tmp/insights-verdicts-D.json`.
10. **Link.** `uv run "${CLAUDE_SKILL_DIR}/scripts/link_daily.py" ARGS` adds
    `Einsichten: [[<periodic>/06 Insights/D.html]]` to today's daily note
    beside the newspaper's `Zeitung:` line, once.
11. **Report** in under ten lines: the page path, problems by status and
    group, which causes were verified, the PRs and todos from step 2, feedback
    applied, skipped files, and any warning.

## Platform mapping

| Step    | Claude Code                                      | Codex                                               |
| ------- | ------------------------------------------------ | --------------------------------------------------- |
| Scripts | `uv run "${CLAUDE_SKILL_DIR}/scripts/<name>.py"` | `uv run <this skill's directory>/scripts/<name>.py` |
| Search  | `Grep`, or `rg` through Bash                     | `rg`                                                |

The extractor reads Claude Code transcripts (`~/.claude/projects`) only.

## Self-Healing

- **`uv` missing**: stop and say so. Do not hand-write the page; memory and
  the review note would drift from it.
- **The digest is empty**: no sessions on D. Write a page with no problems,
  so the daily note still gets its link, and say so.
- **render.py lists errors**: fix the JSON, never the template.
- **A transcript file over 300 MB**: the extractor skips it and lists it in
  `scope.skipped_large`; the page says how many. Do not read it by hand.

## Rules

- Never write to the vault outside `IN` and today's daily note. Applying a
  reviewed note (step 2) writes where `../apply/SKILL.md` says.
- Never put health, mood, money, relationships or client names on the page,
  even when the digest holds them.
- Never kill, delete or reset anything to verify a cause. Look only.
