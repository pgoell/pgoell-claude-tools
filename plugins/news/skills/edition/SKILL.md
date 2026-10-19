---
name: edition
description: "Build a day's newspaper as one HTML page in the kasten vault and link it from the daily note. Started by /news:edition or by cron."
disable-model-invocation: true
---

# Edition

Build one daily newspaper edition as a self-contained HTML page in a kasten
vault, linked from that day's daily note. Scripts do the mechanics (seeding,
validation, rendering, memory, the daily-note link). You do the judgement:
which feedback means what, which stories matter, what is new, and the writing.

This may run headless from cron (`claude -p`). Never stop to ask a question
during an edition. Decide, and say what you decided in the final report.

## Arguments

`/news:edition [--vault PATH] [--date YYYY-MM-DD] [--periodic FOLDER]`

- **vault**: `--vault`, else `$KASTEN_VAULT`, else the working directory when
  it holds the periodic folder. If none applies, stop and say so.
- **date**: `--date`, else today in Europe/Berlin.
- **periodic**: `--periodic`, else `$KASTEN_PERIODIC_PATH`, else `01 Periodic`.

Below, `ARGS` stands for `--vault "<vault>" --periodic "<periodic>" --date <date>`
and `NP` for `<vault>/<periodic>/05 Newspaper`. Editions sit flat in `NP`:
`YYYY-MM-DD.html` and the `YYYY-MM-DD.json` it was rendered from, so a link to
an earlier story is just `2026-10-06.html#2026-10-06-bnd-01`.

## Protocol

1. **Seed.** `uv run "${CLAUDE_SKILL_DIR}/scripts/seed.py" ARGS`. It copies the
   default config, feedback note and changelog into `NP` when missing (never
   overwriting) and prints JSON with `number`, `previous` and the feedback
   note path. Keep that output for step 7.
2. **Read.** `NP/config/topics.yaml`, `NP/config/design.yaml`, `NP/feedback.md`,
   and what ran in the last 30 days:
   `uv run "${CLAUDE_SKILL_DIR}/scripts/recent.py" ARGS --days 30`.
3. **Apply feedback.** For every bullet under `## Open` in `feedback.md`,
   follow `references/feedback-rules.md`: change the config, move the item to
   `## Applied`, add a changelog line, or leave a question. Re-read the config
   afterwards; this edition already follows the new config.
4. **Gather.** Read `references/gathering.md`. Start one gatherer per section
   with the section brief from that file, all at once. Each gatherer returns
   candidates as JSON. The weather comes later from `weather.py`.
5. **Select and dedupe.** Per section, keep up to `max_stories`:
   - Drop a candidate that an earlier edition already ran (same URL, or the
     same event by entities and key facts in `recent.py` output) unless it
     carries genuinely new information.
   - A candidate with new information becomes a **follow-up**: `followups`
     lists the earlier coverage (`{date, href: "<date>.html#<id>", headline}`,
     newest first, at most three, taken from memory), and `update_note` says
     only what is new. The summary leads with the new; at most one sentence of
     background. Never restate old news.
   - Honour `exclude`, `avoid` and `interests`.
   - Pick the **lead**: the day's most important story from a section in
     `edition.lead_from`. Take it out of its section and set its `section`.
   - Then cut to `edition.max_stories` across all sections, dropping the
     lowest importance first and keeping at least two stories per section.
   - Leftover good candidates, cut stories and depth-1 sections become
     **briefs**, up to `edition.briefs`.
6. **Write.** Each story in its source language: German stays German, English
   stays English. Set `importance` honestly (3 for the two or three stories of
   the day, most stories 2, small items 1) and size the summary by it:
   3 is 90 to 150 words with context, 2 is 50 to 90, 1 is 25 to 45. A section's
   depth caps that: depth 2 writes no importance 3, depth 1 gives briefs only.
   The page is read over breakfast, so a long day means fewer stories, not
   longer ones. When `edition.style` is `smart-brevity`, write every summary,
   the lead's included, as three paragraphs: a one-sentence lede, then
   `Warum das wichtig ist:` (`Why it matters:` in English) with one or two
   sentences, then `Die Details:` (`The details:`) with the rest. The word
   ranges stay the same. "Why it matters" analyses one level above the lede:
   a consequence, a second-order effect, who wins or loses, or what the story
   means for the reader's `interests` and sections. It never adds a fact,
   number or quote; those go in the details. When no real "so what" exists,
   leave the paragraph out instead of restating the lede. Follow
   `edition.why_it_matters` in topics.yaml when it is set. Any other style
   value, or none, means plain paragraphs. Facts come from the fetched article
   only and no paragraph invents one; reasoning from those facts belongs in
   "why it matters" alone, every other paragraph carries no opinion. No filler. Give every story `entities` and two to four
   `key_facts`, which memory uses to spot repeats tomorrow. Story ids are
   `<date>-<slug>-NN`, where slug is the section id or a short subject slug
   (`anthropic`, `bnd`), lowercase ASCII, NN counting from 01 per slug.
7. **Assemble** `NP/<date>.json` per `references/edition-contract.md`: `title`
   and `tagline` from design.yaml, `date_display` in German ("Mittwoch, 7.
   Oktober 2026"), `number` and `previous` from step 1, sections in config
   order (skip a section with no stories; keep 4 to 20) with `local: true` on
   a section whose topics.yaml entry has it, `weather: null` unless you have
   something better than a forecast, and `feedback_hint` as
   `Feedback: <periodic>/05 Newspaper/feedback.md`. Keep a candidate's
   `bracket` on its story. Then
   `uv run "${CLAUDE_SKILL_DIR}/scripts/weather.py" ARGS` fills a null
   `weather` from Open-Meteo for topics.yaml's `weather` place (one request,
   no key); a warning means the box stays empty, which is fine. Then
   `uv run "${CLAUDE_SKILL_DIR}/scripts/tables.py" ARGS` fills `tables` on
   every section whose topics.yaml entry lists `tables:`, from sportschau.de;
   a warning means that league's table is left out.
8. **Validate.** `uv run "${CLAUDE_SKILL_DIR}/scripts/validate.py" "NP/<date>.json" --memory "NP/memory/stories.jsonl"`.
   Fix every error and run it again until it reports 0 errors. A repeated URL
   means drop the story or make it a real follow-up. Length warnings do not
   block, but trim any summary more than a third over its range.
9. **Render.** `uv run "${CLAUDE_SKILL_DIR}/scripts/render.py" ARGS`. It writes
   `NP/<date>.html` with design.yaml's design and overrides, and fills the
   footer's recent changes from the changelog, and the Berlin-time
   `published_display` of each story. A warning that the design is
   not installed means it fell back to `plain`; mention it in the report.
10. **Remember.** `uv run "${CLAUDE_SKILL_DIR}/scripts/remember.py" ARGS`.
    A rerun for the same date replaces that date's memory, never duplicates it.
11. **Link.** `uv run "${CLAUDE_SKILL_DIR}/scripts/link_daily.py" ARGS`. It adds
    `Zeitung: [[<periodic>/05 Newspaper/<date>.html]]` to the daily note above
    its first `##` heading, once, creating the note in kasten's format if it is
    missing.
12. **Report** in under ten lines: the page path, stories per section, the
    lead, follow-ups, feedback applied, questions left in the feedback note,
    sections that came up empty, and any fallback or warning.

## Platform mapping

| Step    | Claude Code                                                               | Codex                                                   |
| ------- | ------------------------------------------------------------------------- | ------------------------------------------------------- |
| Gather  | `Agent` tool, `general-purpose` type, one per section, all in one message | Its subagent tool, one per section; else inline in turn |
| Web     | `WebSearch` to find, `curl` or `WebFetch` to read                         | Its web search tool, then `curl`                        |
| Scripts | `uv run "${CLAUDE_SKILL_DIR}/scripts/<name>.py"`                          | `uv run <this skill's directory>/scripts/<name>.py`     |

## Self-Healing

- **`uv` missing**: the scripts need `uv` (Python 3.11 or later). Without it,
  stop and say so; do not hand-write the HTML, because memory and validation
  would drift.
- **A source returns 401, 403, 429 or times out**: move on to the next source
  or to secondary coverage. Do not retry more than once. Append each failed
  domain to `NP/memory/source-failures.md` as `- <date> <domain> <code>`. If the
  file holds the domain from the previous edition, add it to `blocked_sources`
  and log it in the changelog.
- **A section comes up empty**: leave it out of this edition and say so. Never
  pad it with old stories.
- **validate.py fails on a follow-up href**: the earlier story id is not in
  memory. Take ids from `recent.py`, never from guesswork.
- **YAML no longer parses after a feedback edit**: fix it before gathering;
  the check command is at the end of `references/feedback-rules.md`.

## Rules

- Never invent a story, a quote, a date or an image. Every story has a URL you
  fetched in this run.
- Never write to the vault outside `NP` and the one daily note.
- Config in the vault is the reader's. Change it only through feedback items.
