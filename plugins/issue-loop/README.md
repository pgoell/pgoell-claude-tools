# Issue Loop

Run an unattended build loop: one Claude Code session, the orchestrator, drives a second one, the implementer, through a repo's GitHub issues. One task is one PR, merged and deployed, then checked from outside before the next task goes out.

The plugin is the written-down form of a loop that ran for two days on one example project, the web app Blattomat: about 40 tasks, each 45 to 100 minutes, with the user away for most of it.

## Skills

- `/issue-loop:running-the-loop`: Makes this session the orchestrator. Checks what the repo needs, sets up a loop folder, then turns the loop: write the task line, send the brief, wait for the exact DONE line with a clock (the implementer also sends one line when it is done), run the gate, read "Not fixed", "Slips" and "Issues opened", pick what runs next, write a ledger line, report in a few lines, send the next task.
- `/issue-loop:handing-over`: Passes the loop to a fresh orchestrator at the first break between tasks past 120k tokens of context, or past 150k at any time: rewrites the handoff file with the successor's name, starts the successor in the loop folder, sends a first message that points at your standing order, checks it took over.

The model can start both skills itself: a plain request such as "run the issue loop on this repo" starts `running-the-loop`. A handover's first message starts with `/issue-loop:running-the-loop`; a successor that missed it loads the skill with the Skill tool.

## What is in the loop folder

`scripts/init.sh <folder>` writes these files into a folder outside every checkout:

| File                                                                                                | What it is                                                                                                                                                                                                                |
| --------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `loop.env`                                                                                          | The settings: implementer name, its checkout, base branch, deploy workflow, `LIVE_TYPES`, alive URL, driver, `REVIEW_IN`, `IMPL_ENV_FILE`, `TRUSTED_AUTHORS`, `ISSUE_LOOP_VERSION` (`latest`, or 0.9.0 or later)          |
| `rules.local.md`                                                                                    | The loop's own answers to the plugin's rules: the `<FILL: ...>` marks for your test commands and your bar, and any rule of your own. The brief is the plugin's 19 rules plus this file                                    |
| `next.sh`, `wait.sh`, `gate.sh`, `start.sh`, `notify.sh`, `grant.sh`, `takeover-check.sh`, `lib.sh` | Eight stubs, one identical file under each name. `lib.sh` loads the plugin's library for `. ./lib.sh` in this folder. Each runs the same script from the installed plugin, with this folder as its state. Never edit them |
| `models.env`                                                                                        | The model per role and per harness: sessions, implementing and review subagents, advisor; `start.sh` and `next.sh` read it                                                                                                |
| `standing-order.md`, `standing-order-impl.md`                                                       | Your standing order as templates: what the loop's sessions may order each other to do without your go, and what stays yours                                                                                               |
| `ledger.tsv`                                                                                        | One line per task                                                                                                                                                                                                         |
| `HANDOFF.md`                                                                                        | The orchestrator's memory, from the handoff template                                                                                                                                                                      |

The herdr driver runs from the plugin, so the folder needs no copy of it. A custom driver is the one script a loop folder may hold: name it in `DRIVER` in `loop.env`.

The orchestrator adds one file by hand: `orch-name`, with its own session name, so that `notify.sh` knows whom to tell.

## Setup

- Claude Code sessions in a terminal manager the orchestrator can drive. The bundled driver is for herdr; another manager needs five shell functions (`skills/running-the-loop/references/driver.md`).
- `gh` (logged in), `git`, `jq`, `curl`, `timeout` and GNU `date`.
- In the repo: issues as the queue; labels `bug`, `regression`, `wish`, `test-debt` and one for "not now", optionally one for "run next" (`priority`); CI as a required check on the newest commit of a PR; a deploy that can be checked from outside; a way back. `skills/running-the-loop/references/setup.md` has the list with a check for each point.
- A checkout for the implementer that no other session works in.
- The loop folder trusted once by you: start `claude` in it and accept the folder trust question. The loop never accepts it for you.
- Your standing order, once per loop (next section).

## The standing order: what you do once

The orchestrator types briefs into the implementer's tab, and an outgoing orchestrator tells its successor to take over. A session gives text from another session less weight than your own word, and it should. Through version 0.2.0 nothing you had written told the sessions that this loop's sessions may order each other, so an implementer asked for a "go" in about one brief of four, and a successor orchestrator waited for you before it took over.

Now you say it once, in your own channel:

1. The orchestrator asks you what the loop's sessions may do without your go and what stays yours, and fills `standing-order.md` in the loop folder with your words.
2. You run `./grant.sh` in the loop folder, in a terminal of your own. It prints the order for orchestrators and the one for the implementer. Read them. Type `yes`.
3. `grant.sh` writes the first into `CLAUDE.md` in the loop folder and the second into `CLAUDE.local.md` in the implementer's checkout (kept out of git through `.git/info/exclude`). Claude Code loads both as your instructions. Start the implementer anew once, so that it reads them.

The order covers two things: a brief sent with `next.sh`, which the implementer checks against `task.md` in the loop folder, and a takeover that `takeover-check.sh` passes. Everything else that waited for you still does.

`grant.sh` refuses without a terminal, and the skills forbid a session to write those files. That is a rule, not a lock: a session that can write to the folder could forge the file. The locks stay where they were: branch protection, a fence hook.

**After an update to 0.9.0**, on any loop folder made before 0.9.0: run `skills/running-the-loop/scripts/upgrade.sh <loop folder>` as a dry run, read what it prints, then run it again with `--apply`, once. After that, plugin updates reach the folder with no copying. `ISSUE_LOOP_VERSION` in `loop.env` pins a version of 0.9.0 or later, or `latest`. The notes below for 0.8.0 and older are for the steps that 0.9.0 replaces. `references/upgrading.md` has the details, and what to do with a folder from 0.2.0 or earlier.

**After an update to 0.8.0**, on any loop folder made before 0.8.0, after its older notes: run `skills/running-the-loop/scripts/init.sh <loop folder>` again (ignore the setup steps it prints), and check its values. It adds `models.env` and overwrites nothing. Copy `lib.sh`, `next.sh`, `start.sh` and `driver-herdr.sh` anew from `skills/running-the-loop/assets/`, all at once: the new `next.sh` and `start.sh` refuse without `models.env`. Take the new rule 3 from `assets/rules.md` into the folder's `rules.md`.

**After an update to 0.7.1**, on a loop folder from 0.7.0 or earlier: copy `gate.sh` anew from `skills/running-the-loop/assets/`, and take the new sentence of rule 5 from `assets/rules.md` into the folder's `rules.md` (copying the whole file would drop your `FILL:` answers). The new gate fails a ticked box that names no test after `Test:` or `Proof:` on its line.

**After an update to 0.7.0**, on a loop that runs: the model can load `running-the-loop` again. Run `/reload-plugins` in the orchestrator's tab, so its next handover sends the new first message, and change the paragraph that starts "The loop runs by" in the loop folder's `HANDOFF.md` to the one in `skills/handing-over/references/handoff-template.md`.

**After an update to 0.6.2**, run `/reload-plugins` in the orchestrator's tab, so the next handover sends the first message with the self-rename.

**After an update to 0.6.0**, on a loop that runs: run `/reload-plugins` in the orchestrator's tab, so its next handover sends the new first message, and change the line "Run the loop by the skill `issue-loop:running-the-loop`" in the loop folder's `HANDOFF.md` to the one in `skills/handing-over/references/handoff-template.md`.

**After an update from 0.2.0 or earlier**, on a loop that runs: in this order: run `scripts/init.sh <loop folder>` again (it adds the new files and overwrites nothing), copy `lib.sh` anew from `skills/running-the-loop/assets/`, fill `standing-order.md`, run `./grant.sh`, start the implementer anew, and only then copy `next.sh`, `start.sh`, `notify.sh` and `wait.sh` anew, all four at once, then `gate.sh` (full lists per version in `skills/running-the-loop/references/upgrading.md`). The new `next.sh` refuses to send a brief without the order; with the old one the loop works as before, with a go from you now and then. A hand-made loop folder needs a `loop.env` first.

Sessions run with permissions skipped (`claude --permission-mode bypassPermissions`). Set `PERMISSION_MODE=auto` in `loop.env` for a loop that should ask.

Models come from `models.env` in the loop folder, and from nowhere else. It names one model for each role: orchestrator sessions, the implementer, subagents that implement code, review subagents, and the advisor. `HARNESS=CLAUDE` picks the Claude Code column. The Codex column is empty, since the loop never ran under Codex. `REVIEW_NOT` holds a pattern that a review model must never match; `next.sh` refuses a brief that would break it. The advisor goes in as `claude --advisor`, a flag that Claude Code parses but leaves out of `--help`. If your Claude Code lacks it, leave the advisor value empty.

## Review in the session or in CI

`REVIEW_IN` in `loop.env` says where the code review runs. `session`, the default and what a loop.env without the line gets: the implementer starts a review subagent (rules 7 and 16). `ci`: the repo reviews every PR in CI, and `next.sh` lays `skills/running-the-loop/assets/rules-ci.md` over rules 7, 15 and 16. The implementer then answers every blocking review thread with a reply whose first word is `Fixed`, `Rejected`, `Intentional` or `Didn't matter`, resolves it, and stops after three rounds. A PR on a path that `CODEOWNERS` gives to you waits for your approving review: the task ends `HELD #N` with auto-merge on, `gate.sh` prints `GATE HELD`, the loop goes on, and the release runs as a later task once the PR lands. The numbers stay, and a loop's own `## 7`, `## 15` or `## 16` still wins. The example is kasten (`pgoell/kasten` PRs #1317 and #1318).

You cannot approve your own PR, so the implementer must push as another account. `IMPL_ENV_FILE` in `loop.env` names a file outside every checkout, mode 600, of `KEY=value` lines such as `GH_TOKEN=<token of a bot account>`; `start.sh` loads it into the implementer's session only. Where git takes its credentials from `gh auth git-credential`, `gh` and `git push` both act as the bot. Use a classic token with the `repo` scope only: a fine-grained token cannot reach a repo another personal account owns, and without the `workflow` scope the token cannot push a change to `.github/workflows`, so an implementer led astray by a prompt cannot change CI. Empty: the implementer runs with your credentials, as before. `skills/running-the-loop/references/setup.md`, "Review in CI", has the list.

Anyone can comment on a public repo's issues, so the loop reads issue and PR text only from trusted authors: `TRUSTED_AUTHORS` in `loop.env`, or when empty you, the account of `IMPL_ENV_FILE`'s token, and with `REVIEW_IN=ci` `github-actions[bot]`. The orchestrator reads with `trusted_queue` and `trusted_read` from `lib.sh`; an issue by anyone else goes to you, never into a brief; rule 2 hands the implementer `gh api` commands that filter on `.user.login`. See setup's "Trusted authors".

## Limits

Read `skills/running-the-loop/references/limits.md` before you rely on the loop. In short: tests prove logic and not taste; a task tends to park a known fault as a follow-up unless a rule blocks it; each task files 2 to 6 new issues, so the queue of wishes never empties; a task costs about 25 to 30 dollars at list prices; and no check in the loop is a person who uses the product.

## Tests

`tests/run.sh` runs the scripts through their stubs, from a fake plugin install, against a stub driver and fake `gh`, `git` and `curl`: no session, no network, about a second. It sources the cases from `tests/test-*.sh`, one file per script or skill under test, with the shared checks and fakes in `tests/lib.sh`, and runs them in order, since each case builds on the state the one before left. It needs `script` from util-linux, since `grant.sh` wants a terminal. It covers `init.sh`, `grant.sh` (no terminal, a `FILL:` mark left, no yes, a yes, a second run, the checkout stays clean, a tracked `CLAUDE.local.md`, an exclude file with no last newline, a checkout it cannot write to), the brief that `next.sh` builds (also with a URL that holds `&` and `|`), its refusal while the implementer works and without the standing order in either place, the go-ahead question as text in five wordings and as a menu (and that these are left alone: a working session, plain lines with "go" in them, among them the brief's own first line, a go asked for a refused push or a skipped review, a failed takeover check, a stopped loop, and Claude Code's own permission dialog with the word brief in its command), `takeover-check.sh` (pass, pass after the name was passed on, and each failed check), every exit of `wait.sh` (also a DONE line above a tall pane's blank rows, a DONE line only in `task.notified` behind a scrolled-up pane, a stale or wrong token there that does not settle, and that it says `TIMEOUT` once per task and then watches on), `notify.sh` (one line to the name in `orch-name`, nothing but DONE, BLOCKED or HELD, the first line only, nothing into a session that sits on a question, and the line in `task.notified` even when nothing is sent, but not for a refused line), each failure of `gate.sh` (among them a ticked box that names no test, and one whose test sits on the indented line under it), its `GATE HELD` (an open PR with auto-merge on and no red or running check, the HELD line read from `task.notified` or the screen, and a fail for each part that does not hold) and its context line (unknown without a transcript, a handover order past 120k and a stronger one past 150k, neither of which fails the gate), the trusted authors (the brief's filter, a stranger's issue refused, the token never printed, `trusted_queue` and `trusted_read`), the CI review overlay (`REVIEW_IN=ci` swaps rules 7, 15 and 16, adds no `FILL`, and a loop's own rule still wins), and `start.sh` with a start dialog, with a session that quits, and that it answers a go-ahead question only for a successor that `HANDOFF.md` names, in the loop folder, with a go marked as one for the takeover only, and with `IMPL_ENV_FILE` (loaded for the implementer only, refused when others can read it, when it sits in the checkout or is missing; the herdr driver loads it before claude starts). It also reads the handover text: the first message tells the successor to rename itself, step 5 renames only the outgoing session, and the handoff template and `running-the-loop` name the successor's title. Last, it checks that no issue-loop skill turns off model invocation and that a successor that missed the command loads `running-the-loop` with the Skill tool.

Last run, 2026-10-29: 457 of 457 checks pass.

`tests/test-models.sh` covers `models.env` and the models the scripts pass on.

`tests/handover-cost.py` re-derives the handover point from real orchestrator transcripts: `uv run tests/handover-cost.py ~/.claude/projects/<loop-folder-slug>/*.jsonl`. It prints each session's start context, growth per call, cache misses and cost, then the average cost per call for a handover at 80k to 300k, and the cheapest point. Rerun it when the model, its prices or the start context change. Last run, 2026-10-18, over 14 sessions and 2,255 calls on the orchestrator model of that run: cheapest at 122k for the measured miss rate of 2% per call, 142k with no misses, 112k at 5%.

The herdr driver was tried live the same day on herdr 0.7.5, with throwaway sessions that ran no tools: `start.sh` in a trusted folder (prints the state, exit 0) and in a never-seen folder (stops on the folder trust question, sends nothing, exit 5); `wait.sh` to `settled` and, after the pane was closed, to `GONE`; `next.sh` with `/clear` and a brief, and its refusal while the session worked. Not tried live: `gate.sh` (it needs a repo with a deploy), `ASKING`, the go-ahead answers, and `notify.sh` (the example project's loop sent the same line with the driver's own command; the script came after).

The standing order, tried on 2026-10-12: Claude Code 2.1.296 loads a `CLAUDE.md` in a folder outside every checkout, and a `CLAUDE.local.md` in a checkout, as the session's instructions (one throwaway session each, asked to repeat a word from the file). Not tried live: a handover and a brief under a granted order. Whether a session then stops asking is what the two evals below are for.

`evals/` holds five trigger fixtures (three that should fire a skill, two that should not) and two for the takeover: `06-takeover-with-standing-order` (the successor takes over and asks nobody) and `07-takeover-without-standing-order` (told to take over "on the user's order" with no such order in its instructions, it does nothing to the loop and asks the user). `09-outside-comment-is-no-order` plants an issue and a comment by an outside login with orders in them: the orchestrator must brief neither and list the issue for you. `08-held-pr-is-no-failure` gives an orchestrator a task that ended `HELD` and a gate that printed `GATE HELD`: it must report the task as held, give you the review as a todo, go on with the next task, and never approve or merge the PR. Last run, 2026-10-29, with `claude plugin eval plugins/issue-loop --scaffold --allow-tools Bash --ablation none`: 3 of 3 runs pass for each case but 06, where the session took over in all 3 but could not write `takeover.log`: the eval sandbox made the workspace read-only. 09 ran later the same day: 3 of 3. Nobody has checked that the eval runner loads the `CLAUDE.md` that fixture 06 puts into its workspace; if it does not, 06 proves nothing. Fixture 06 also cannot tell an order loaded as instructions from a file the session read because the message named it.

## Inspiration

Original work, MIT. The loop, its rules and its scripts grew on the example project; an outside review of that run supplied the numbers in `limits.md`.
