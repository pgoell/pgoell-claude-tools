# Self-Healing

- A loop folder made by version 0.7.0 or earlier, or by hand: read `references/upgrading.md`. It says which files to copy anew from the skill's `assets/`.
- `next.sh` exits 4: the implementer still works. Wait for its DONE line.
- `start.sh` exits 5: a start dialog shows and nothing was sent. It prints the screen. A folder trust question goes to the user.
- `start.sh` or `next.sh` exits 3 and says `no models.env`: the folder predates 0.8.0. Run the skill's `scripts/init.sh` on it (adds `models.env`, overwrites nothing), check the values with the user, run again. `next.sh` exit 3 naming a model or a `{{...}}` placeholder: fix that line in `models.env` or take the new rule 3 from `assets/rules.md`.
- `next.sh` exits 3: `rules.md` has a `FILL:` marker left, or it uses a setting that is empty in `loop.env` (a repo with no deploy: rewrite rule 9, then leave `DEPLOY_WORKFLOW` and `ALIVE_URL` empty), or the file `orch-name` is missing while rule 19 is in the brief, or the standing order is missing in the loop folder's `CLAUDE.md` or in the implementer's `CLAUDE.local.md` (the message says which; the user runs `grant.sh`).
- `grant.sh` exits 2: it has no terminal. That is the point: the user runs it. Exit 3: a `FILL:` mark is left in `standing-order.md`.
- `takeover-check.sh` prints `TAKEOVER FAIL`: each `FAIL` line names one check. Do not repair the standing order yourself; a wrong name in `HANDOFF.md` or `orch-name` is the outgoing orchestrator's to fix.
- No `impl settled` line came: `wait.sh` still settles on the DONE line, on the screen or in `task.notified`. Check that `orch-name` holds your name, and run `./notify.sh "DONE #0"` yourself once between tasks, never during one (it overwrites `task.notified`): the line must land in your own tab.
- `gate.sh` fails "not on <base>" or "working tree dirty" in the middle of a task: that is normal, the gate is for after the task.
- `gate.sh` fails "live is X, <base> is Y" right after the DONE line: the deploy may still run. Look at `gh run list`, wait a minute, run the gate again.
- A driver call fails: run the driver's own command by hand (`herdr agent list`) and read `references/driver.md`.
- The implementer's state is `gone` but its tab is there: read the pane itself (`herdr pane read <pane id>`); a start dialog may have closed the session.
