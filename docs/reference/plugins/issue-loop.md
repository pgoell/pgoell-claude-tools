---
type: Reference
title: The issue-loop plugin
description: The two issue-loop skills, the scripts in a loop folder, and why the plugin ships to Claude Code only.
tags: [plugin, issue-loop, github, automation]
status: stable
---

# issue-loop

An unattended build loop over a repo's GitHub issues. One Claude Code session, the orchestrator, drives a second one, the implementer, task after task: `/clear`, a full brief, a wait for an exact DONE line, a gate checked from outside, a ledger line, a short report, the next task. The orchestrator never codes; one task is one PR, merged and deployed.

**Runtimes:** Claude Code

Not in Codex or Cursor: its skills drive Claude Code sessions themselves (`/clear`, permission modes, Claude Code's own dialogs), and the loop was never run anywhere else. See [Runtimes](/reference/runtimes.md).

**Source:** vendored in `plugins/issue-loop/`; see the [plugin README](../../../plugins/issue-loop/README.md) for details and credits.

**Setup:** [Set up the issue loop](/how-to/set-up-the-issue-loop.md)

## Skills

Both skills start from their slash command or from a plain request ("run the issue loop on this repo"). A handover's first message starts with `/issue-loop:running-the-loop`; a successor that missed it loads the skill with the Skill tool.

| Invocation                     | What it does                                                                                                                                                                                                                                                   |
| ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/issue-loop:running-the-loop` | Makes this session the orchestrator: checks what the repo needs, sets up a loop folder from templates, and turns the loop. Covers the standing order, the brief, the wait, the gate, queue order, what goes to the human, and the limits of such a loop.       |
| `/issue-loop:handing-over`     | Passes the loop to a fresh orchestrator at the first break between tasks past 120k tokens of context, or past 150k at any time: rewrites the handoff file, starts the successor in the loop folder, points it at your standing order, and checks it took over. |

## The loop folder

`scripts/init.sh <folder>` writes the data templates and eight stubs into a folder outside every checkout. A stub runs the same script from the installed plugin, so an update reaches the folder with no copying. The main ones:

| File              | What it does                                                                                                                                                             |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `loop.env`        | The settings: implementer name and checkout, base branch, deploy workflow, alive URL, driver, permission mode, where the review runs, the implementer's own credentials. |
| `models.env`      | The model per role and per harness: sessions, implementing and review subagents, advisor. `start.sh` and `next.sh` read it.                                              |
| `rules.local.md`  | The loop's own answers to the plugin's rules: the `FILL` marks, and any rule of its own. The brief is the plugin's rules plus this file.                                 |
| `next.sh`         | Sends `/clear` and the brief to the implementer. Refuses while the implementer works or without the standing order.                                                      |
| `wait.sh`         | Waits for the implementer's DONE, BLOCKED or HELD line, on its screen or in the file `notify.sh` writes, with a clock.                                                   |
| `gate.sh`         | Pass, held or fail from outside: issues closed, PRs merged (or one held for the owner's review), every ticked box names a test, live commit, clean tree, app up.         |
| `grant.sh`        | Run by you in a terminal of your own, never by a session: writes your standing order into the sessions' instructions after you type yes.                                 |
| `lib.sh`          | A stub that loads the plugin's library, so `. ./lib.sh` works in the folder.                                                                                             |
| `driver-herdr.sh` | Not copied: the herdr driver runs from the plugin. A custom driver is the one script a folder may hold, named by `DRIVER` in `loop.env`.                                 |

`REVIEW_IN` in `loop.env` says where the code review runs: `session` (the default) has the implementer start a review subagent; `ci` swaps rules 7, 15 and 16 of the brief for the ones in `assets/rules-ci.md`, where the implementer answers CI's review threads and a PR on a code-owned path ends `HELD`, waiting for your approving review while the loop goes on. `IMPL_ENV_FILE` names a file of `KEY=value` lines, such as a bot account's `GH_TOKEN`, that `start.sh` loads into the implementer's session only, so it can push as an account whose PRs you can approve. `TRUSTED_AUTHORS` lists the GitHub logins whose issue and PR text the loop reads, since anyone can comment on a public repo's issues; empty, it is the repo's owner, the account of the token in `IMPL_ENV_FILE`, and with `REVIEW_IN=ci` `github-actions[bot]`. The queue sets an issue by anyone else aside for you, `next.sh` refuses to brief one, and rule 2 of the brief reads through a filter on `.user.login`. The plugin README has the details; kasten is the example.

Sessions start with `--permission-mode bypassPermissions` by default; set `PERMISSION_MODE=auto` in `loop.env` for a loop that should ask. `models.env` in the loop folder names the model for each role (orchestrator, implementer, coding and review subagents, advisor) in Claude Code; its Codex column is empty. Read `skills/running-the-loop/references/limits.md` in the plugin before you rely on the loop: tests prove logic and not taste, and no check in the loop is a person who uses the product.
