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

`scripts/init.sh <folder>` copies the script templates into a folder outside every checkout. The main ones:

| File              | What it does                                                                                                                             |
| ----------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `loop.env`        | The settings: implementer name and checkout, base branch, deploy workflow, alive URL, driver, permission mode.                           |
| `rules.md`        | The brief every task gets.                                                                                                               |
| `next.sh`         | Sends `/clear` and the brief to the implementer. Refuses while the implementer works or without the standing order.                      |
| `wait.sh`         | Waits for the implementer's DONE or BLOCKED line, on its screen or in the file `notify.sh` writes, with a clock.                         |
| `gate.sh`         | Pass or fail from outside: issues closed, PRs merged, live commit, clean tree, app up.                                                   |
| `grant.sh`        | Run by you in a terminal of your own, never by a session: writes your standing order into the sessions' instructions after you type yes. |
| `driver-herdr.sh` | The only file that knows the terminal manager (herdr). Another manager needs five shell functions.                                       |

Sessions start with `--permission-mode bypassPermissions` by default; set `PERMISSION_MODE=auto` in `loop.env` for a loop that should ask. Read `skills/running-the-loop/references/limits.md` in the plugin before you rely on the loop: tests prove logic and not taste, and no check in the loop is a person who uses the product.
