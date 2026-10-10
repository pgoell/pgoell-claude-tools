# Issue Loop

Run an unattended build loop: one Claude Code session, the orchestrator, drives a second one, the implementer, through a repo's GitHub issues. One task is one PR, merged and deployed, then checked from outside before the next task goes out.

The plugin is the written-down form of a loop that ran for two days on one example project, the web app Blattomat: about 40 tasks, each 45 to 100 minutes, with the user away for most of it.

## Skills

- `/issue-loop:running-the-loop`: Makes this session the orchestrator. Checks what the repo needs, sets up a loop folder, then turns the loop: write the task line, send the brief, wait for the exact DONE line with a clock, run the gate, read "Not fixed", "Slips" and "Issues opened", pick what runs next, write a ledger line, report in a few lines, send the next task.
- `/issue-loop:handing-over`: Passes the loop to a fresh orchestrator at about 150k tokens of context: rewrites the handoff file, starts the successor in auto mode, sends the exact first message, checks it took over.

## What is in the loop folder

`scripts/init.sh <folder>` copies these templates into a folder outside every checkout:

| File              | What it is                                                                                             |
| ----------------- | ------------------------------------------------------------------------------------------------------ |
| `loop.env`        | The settings: implementer name, its checkout, base branch, deploy workflow, alive URL, driver          |
| `rules.md`        | The brief every task gets: 18 rules, with `<FILL: ...>` marks for your test commands and your bar      |
| `next.sh`         | Sends `/clear` and the brief, answers the go-ahead question, prints the implementer's state            |
| `wait.sh`         | Waits for `DONE <token>` or `BLOCKED <token>`; prints `settled`, `TIMEOUT`, `ASKING` or `GONE`         |
| `gate.sh`         | Pass or fail from outside: issues closed, PRs merged with no open box, live commit, clean tree, app up |
| `start.sh`        | Starts a session in auto mode and sends its first message                                              |
| `driver-herdr.sh` | The only file that knows herdr. Five functions: send, wait, read, start, status                        |
| `ledger.tsv`      | One line per task                                                                                      |
| `HANDOFF.md`      | The orchestrator's memory, from the handoff template                                                   |

## Setup

- Claude Code sessions in a terminal manager the orchestrator can drive. The bundled driver is for herdr; another manager needs five shell functions (`skills/running-the-loop/references/driver.md`).
- `gh` (logged in), `git`, `jq`, `curl`, `timeout` and GNU `date`.
- In the repo: issues as the queue; labels `bug`, `regression`, `wish`, `test-debt` and one for "not now"; CI as a required check on the newest commit of a PR; a deploy that can be checked from outside; a way back. `skills/running-the-loop/references/setup.md` has the list with a check for each point.
- A checkout for the implementer that no other session works in.

Sessions run in auto mode (`claude --permission-mode auto`). The loop never starts a session with skipped permissions.

## Limits

Read `skills/running-the-loop/references/limits.md` before you rely on the loop. In short: tests prove logic and not taste; a task tends to park a known fault as a follow-up unless a rule blocks it; each task files 2 to 6 new issues, so the queue of wishes never empties; a task costs about 25 to 30 dollars at list prices; and no check in the loop is a person who uses the product.

## Tests

`tests/run.sh` runs the script templates against a stub driver and fake `gh`, `git` and `curl`: no session, no network, about a second. It covers `init.sh`, the brief that `next.sh` builds, both forms of the go-ahead question (and that a permission menu is left alone), every exit of `wait.sh`, each failure of `gate.sh`, and `start.sh`.

Last run, 2026-10-10: 55 of 55 checks pass. `driver-herdr.sh` itself has no test: its calls were taken from the loop's run and checked against the help text of herdr 0.7.5. `drv_status` and `drv_read` were tried read-only on a live herdr; `drv_send`, `drv_wait` and `drv_start` were not, and the pane id that `drv_start` reads was not tried on a live tab.

`evals/` holds five trigger fixtures (three that should fire a skill, two that should not). They have not been run yet.

## Inspiration

Original work, MIT. The loop, its rules and its scripts grew on the example project; an outside review of that run supplied the numbers in `limits.md`.
