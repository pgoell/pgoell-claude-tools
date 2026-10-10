---
name: activity
description: "Use when the user wants to know what their agents did on a day and what now waits for them, for example \"what did my agents do yesterday\", \"what needs me this morning\", \"build the activity page\", \"/insights:activity --vault ~/kasten-data/vault\", or when cron runs it headless at 05:45. A script counts one day per repository (pull requests, issues, failed CI, commits, issue-loop ledger lines, Claude Code sessions, tokens and cost, cron job results, vault notes); the model picks what needs the user and writes a summary of at most two sentences per repo from PR titles and ledger lines. Writes one self-contained HTML page per day in the kasten vault and links it from today's daily note with up to five lines. Not for what went wrong in sessions (use insights:digest)."
---

# Activity

Answer two questions about one day: what did the agents do, and what waits
for the user now. A script counts everything, per repository. You do two
things only: pick what needs the user, and write a short summary per repo
that shipped. You see titles and ledger lines, never a diff, so claim nothing
a title does not say.

This may run headless from cron (`claude -p`). Never stop to ask a question.
Decide, and say what you decided in the final report. Ignore the token
`insights-self-run` in the prompt: it marks this job's own transcripts so the
next run leaves them out.

## Arguments

`/insights:activity [--vault PATH] [--date YYYY-MM-DD] [--periodic FOLDER]`

- **vault**: `--vault`, else `$KASTEN_VAULT`, else the working directory when
  it holds the periodic folder. If none applies, stop and say so.
- **date**: the day to count. `--date`, else yesterday in Europe/Berlin.
- **periodic**: `--periodic`, else `$KASTEN_PERIODIC_PATH`, else `01 Periodic`.

Below, `ARGS` stands for `--vault "<vault>" --periodic "<periodic>" --date <date>`,
`AC` for `<vault>/<periodic>/07 Activity` and `D` for the date.

## Protocol

1. **Collect.**
   `uv run "${CLAUDE_SKILL_DIR}/scripts/collect.py" ARGS --private "<vault>"`.
   It takes about half a minute, writes `AC/D.json`, and prints one line with
   the counts and the state of each source. Other flags, only when the user
   names them: `--code DIR` (where the checkouts live, default `~/Code`) and
   `--ledger FILE` (an issue-loop `ledger.tsv`, repeatable; default every one
   up to two folders under the code root).
2. **Read** `AC/D.json` whole and `references/page-contract.md`.
3. **Pick what needs the user.** At most 8 items; `render.py` refuses more.
   Make them in this order, which is also their order on the page:
   1. **The user must act.**
      - `ledger` lines whose notes say so: "waits for <the user>", "TOUCHES
        THE MACHINE".
      - `failed_ci`: one item per row.
      - `cron` rows whose state is not `ok`: one item for all of them. A
        row dated after D with `running or died` may be another job still
        at work: leave it out.
   2. **A risk stays open.** `ledger` lines where `not_fixed` is not `-`, or
      whose notes name something "unproven", "unreviewed" or "never seen
      red".
   3. **Open PRs.** `open_prs` that are not stale: one item per repo. A
      series (several PRs of one repo with one theme) is one item with a link
      per PR. `open_prs` with `insights: true` get one item of their own,
      "insights fixes wait on N PRs".
   4. **Stale PRs.** `open_prs` with `stale: true`: one item for all of them.

   Rules for ledger lines:
   - A line is an item only when the user must act or a risk stays open.
     Friction is no item: time lost to a hook or a flake, a slow task, a
     review that caught a bug before the merge, a cost.
   - One item per PR or PR group. When several lines name the same PRs, merge
     their notes into one item and place it by its strongest note. A PR never
     appears in two items.
   - A ledger PR that is also in `open_prs` joins that ledger item; do not
     list it again under open PRs.

   Over 8 items: keep the first ones and fold the rest of a group into one
   item that keeps every link, such as "3 more loop warnings in blattwerk"
   with a link per PR. Never drop a link to meet the cap.

   A source under `sources` that is not `ok` is no item; the page says it.
   Nothing else belongs here. If nothing holds, `needs` is empty.
4. **Summarize what shipped.** For each repo with `prs_merged` over 0, write
   at most two sentences from its `merged` titles and its `ledger` lines.
   Start with the count.
5. **Write** `/tmp/activity-notes-D.json` with `needs` and `shipped` per the
   contract.
6. **Render.**
   `uv run "${CLAUDE_SKILL_DIR}/scripts/render.py" ARGS --notes /tmp/activity-notes-D.json`
   saves your notes into `AC/D.json`, checks them and writes `AC/D.html`. Fix
   every error it lists in the notes file and run it again until it renders.
7. **Link.** `uv run "${CLAUDE_SKILL_DIR}/scripts/link_daily.py" ARGS` puts
   `Aktivität: [[<periodic>/07 Activity/D.html]]` into today's daily note
   beside the `Einsichten:` and `Zeitung:` lines, with the first five linked `needs`
   headlines under it. Never edit the daily note by hand.
8. **Report** in under ten lines: the page path, how many items need the
   user, PRs merged, total cost, and every source that was unavailable.

## How to write

Every item is a headline, one why line, and links. Nothing more.

- Answer first: the headline says what waits ("8 kasten mobile PRs wait for
  review"), not that something happened.
- Numbers, not adjectives: "open for 92 days", never "very old".
- Short words, active voice. No em-dash, no en-dash, no interpunct, no
  hyphen used as punctuation. `render.py` refuses these and any text over its
  limit (headline 80 characters, why 160, summary 300 and two sentences).
- A link goes on the page only when its URL stands in `AC/D.json`.
- Name a session only for an open PR under "Needs you", through `resume`.
  Never list sessions.

## Platform mapping

| Step    | Claude Code                                      | Codex                                               |
| ------- | ------------------------------------------------ | --------------------------------------------------- |
| Scripts | `uv run "${CLAUDE_SKILL_DIR}/scripts/<name>.py"` | `uv run <this skill's directory>/scripts/<name>.py` |

The scripts import shared helpers from `../digest/scripts`, so the two skills
must stay in one plugin. Sessions come from Claude Code transcripts
(`~/.claude/projects`) only.

## Tools

The protocol needs three tools and no other: `Read`, `Write`, and Bash for
`uv run`. `collect.py` calls `git`, `gh` and `bunx` itself. Never call them
yourself, and never look at a repository to add to what the script counted.

## Self-Healing

- **`uv` missing**: stop and say so. Do not hand-write the page.
- **A source is `unavailable`**: go on. `gh` not logged in empties the PR,
  issue and CI counts; a failing `bunx ccusage@20.0.28` empties tokens and cost; a
  vault that is no git repository empties the note count. The page names each
  gap. Never fill one by hand or from memory.
- **render.py lists errors**: fix the notes file, never the template or
  `AC/D.json`.
- **The day is empty**: render with empty `needs` and `shipped`, so the daily
  note still gets its link.

## Rules

- Never write to the vault outside `AC` and today's daily note, and into the
  daily note only through `link_daily.py`.
- Sessions in the vault are counted and nothing else: no title, no text.
- Never put health, mood, money, relationships or client names on the page.
- Look only. Never merge, close, rerun or comment on anything.
