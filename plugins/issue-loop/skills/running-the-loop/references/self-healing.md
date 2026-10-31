# Self-Healing

- A loop folder made before 0.9.0, or by hand: read `references/upgrading.md`. It says how to run `scripts/upgrade.sh` on it.
- `next.sh` exits 4: the implementer still works. Wait for its DONE line.
- `start.sh` exits 5: a start dialog shows and nothing was sent. It prints the screen. A folder trust question goes to the user.
- `start.sh` or `next.sh` exits 3 and says `no models.env`: the folder predates 0.8.0. Run `scripts/upgrade.sh <folder>` as a dry run, check the values with the user, then run it again with `--apply`. `next.sh` exit 3 naming a model or a `{{...}}` placeholder: fix that line in `models.env`, or in your own `## N` rule in `rules.local.md` if the placeholder sits there.
- `next.sh` exits 3 and says the folder still has a full rules.md from before 0.9.0: run `scripts/upgrade.sh <folder>` as a dry run, then again with `--apply`.
- A stub exits 3 and says `no installed issue-loop` or `no <script> in <folder>`: `ISSUE_LOOP_VERSION` names a version that is not in the plugin cache; set it to `latest` or to one of the versions it lists.
- A stub exits 3 and says a version is from before 0.9.0: `ISSUE_LOOP_VERSION` pins a version that cannot run stubs; pin 0.9.0 or later, or `latest`.
- A stub says `task.plugin` is gone and runs the installed version: Claude Code removed the cached version the last task ran; nothing to do, the next `next.sh` writes a new `task.plugin`.
- `next.sh` exits 3: `rules.local.md` has no answer for a `FILL:` mark (the lines after that message name each one), or it uses a setting that is empty in `loop.env` (a repo with no deploy: rewrite rule 9 as a whole rule in `rules.local.md`, then leave `DEPLOY_WORKFLOW` and `ALIVE_URL` empty), or the file `orch-name` is missing while rule 19 is in the brief, or the standing order is missing in the loop folder's `CLAUDE.md` or in the implementer's `CLAUDE.local.md` (the message says which; the user runs `grant.sh`).
- `grant.sh` exits 2: it has no terminal. That is the point: the user runs it. Exit 3: a `FILL:` mark is left in `standing-order.md`.
- `takeover-check.sh` prints `TAKEOVER FAIL`: each `FAIL` line names one check. Do not repair the standing order yourself; a wrong name in `HANDOFF.md` or `orch-name` is the outgoing orchestrator's to fix.
- No `impl settled` line came: `wait.sh` still settles on the DONE line, on the screen or in `task.notified`. Check that `orch-name` holds your name, and run `./notify.sh "DONE #0"` yourself once between tasks, never during one (it overwrites `task.notified`): the line must land in your own tab.
- `gate.sh` fails "not on <base>" or "working tree dirty" in the middle of a task: that is normal, the gate is for after the task.
- `gate.sh` fails "live is X, <base> is Y" right after the DONE line: the deploy may still run. Look at `gh run list`, wait a minute, run the gate again. When it fails on every commit the loop does not deploy (lint, test or comment trims), set `LIVE_TYPES` in `loop.env` to the commit types the deploy releases.
- A driver call fails: run the driver's own command by hand (`herdr agent list`) and read `references/driver.md`.
- The implementer's state is `gone` but its tab is there: read the pane itself (`herdr pane read <pane id>`); a start dialog may have closed the session.
