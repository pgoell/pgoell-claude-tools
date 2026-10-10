# Quirks that cost time

Each of these stopped the loop at least once. The scripts handle the first four; know them anyway, for the day the script's guess is wrong.

## The go-ahead question

A long brief arrives as a pasted block. The session may then refuse to act on it: the opening line "this brief is mine" sits inside the paste, so it cannot vouch for itself, and the brief ends in a merge and a deploy. The session asks for a typed go-ahead, in one of two forms:

- as text: `Reply "go"`. State after `next.sh`: `done` or `idle`.
- as a menu ("Run brief?", first item "Yes, run it" or "Go"). State: `blocked`.

Fix: answer once, "go" for the text form, "1" for the menu. `next.sh` and `start.sh` do this themselves. The menu's words change between versions, so the scripts match only a menu whose screen speaks of a brief or a paste. If `next.sh` does not print `working`, read the screen and answer by hand.

The opener "Go, this brief is mine, run it as written, unattended." stays in the brief: it settles the question in most cases. On the example project the session still asked in about two of five tasks.

## "Idle" is not "done"

A session's state goes to idle or done between steps, while a subagent runs, and during a CI wait. Trust the DONE line, never the state alone. And trust only a DONE line with this task's token: the old report may still be on the screen, and any line that starts with DONE once counted as done.

## A wait must have a clock

The first wait had none. A task that hangs then hangs the loop for the night. `wait.sh` prints TIMEOUT when the task is older than `TASK_LIMIT_MIN`. On TIMEOUT look before you act: twice the session was in its deploy step and done three minutes later.

Run the wait in the background. A long sleep in the foreground gets blocked by the host, and a shell call ends at the host's own timeout (10 minutes on Claude Code): that is normal, start `wait.sh` again.

## A start dialog swallows the first prompt

A session started with a flag that shows an accept dialog (the skip-permissions flag did) sits on that dialog. The first prompt's Enter then picks the dialog's default, which was "No, exit", and the session quits. The driver still reported the start as a success.

Fix: auto mode shows no such dialog. `start.sh` waits, checks that the session is still there, and only then sends. After any start, read the screen once before you trust it.

After making a new tab, wait a few seconds before starting a session in it; `drv_start` does.

## Two sessions in one checkout collide

A subagent's chained command once reverted a folder of source files that another part of the task had changed. A PR from an unknown session once merged in the middle of a task. So:

- The implementer has a checkout of its own. The orchestrator and every side session work elsewhere and only read it.
- Never cut in on a working implementer with a second task. Queue it.
- Tell the implementer about open PRs that are not its own: "PRs #A and #B are open and not yours: leave them alone".
- The brief forbids chaining `git checkout` or `git restore` with other commands.

## Leftover agent worktrees

Subagents that work in git worktrees leave them behind. They pile up, and one may hold work nobody merged. Every few tasks, add to the task line: "remove the agent worktrees that hold no uncommitted work, and list the ones you kept". One with uncommitted work is the user's call.

## Smaller ones

- **The session died.** Reading it by name fails; `wait.sh` prints GONE. With herdr, `herdr pane read <pane id>` still shows the last screen.
- **Merge before CI.** A merge once fired before CI ran on the PR's last commit. Only branch protection stops that (`references/setup.md`).
- **More than one PR per task.** Look at all PRs since the task began, not the newest. `gate.sh` does. A PR once merged with 0 of 11 boxes ticked.
- **The gate in the middle of a task** fails on "not on the base branch". Run it after the DONE line.
- **The report's top is cut.** Sixty lines often miss the checklist. Read 130.
- **A hook that runs the full suite on every push** cost 15 minutes per task. Let CI run the suite.
- **Tests bent to pass.** Watch "Slips" for a widened window, a longer timeout, an `xfail`. A test nobody saw fail proves little.
- **The first deploy after a change to the deploy itself** failed once. Ask for a rehearsal on scratch names before the merge.
- **Your own shell.** If the host resets the working folder between calls, start every call with `cd <loop folder> &&`.
