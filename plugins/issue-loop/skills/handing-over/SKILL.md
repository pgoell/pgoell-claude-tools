---
name: handing-over
description: Use when the orchestrator of an issue loop must pass the loop to a fresh session, because its context passed 120k tokens at a break between tasks or 150k at any time, or the user says "hand over", "start a fresh orchestrator", or "your context is full, pass it on". Not for starting a loop (the user runs /issue-loop:running-the-loop).
---

# Handing Over

An orchestrator's context fills up. Past about 150k tokens it forgets standing orders and repeats faults. The loop outlives the session through one file, `HANDOFF.md` in the loop folder, and a successor that reads it.

## When

- On your own at the first break between tasks past 120k tokens of context: `gate.sh` prints `HAND OVER` then. Do not wait to be told: on the example project the first orchestrator reached over 200k, and the user had to order the handover.
- On your own past 150k, also while a task runs (`gate.sh` prints `HAND OVER NOW`): the successor only has to start `wait.sh` with the right token. Say so in the file.
- At once when the user says so.

Why 120k: it is the cheapest point per call, measured over 14 orchestrator sessions. Each call rereads the whole context from cache, so calls cost more as it grows; a handover costs the successor's first cache write of its start context (about 52k) plus the calls spent on it; and when a task outlasts the 1-hour cache, the next call writes the whole context again, which made up 27% of the cost. The curve is flat from about 110k to 155k. To check it again with newer transcripts, prices or models, run `uv run tests/handover-cost.py <transcripts>` from the plugin folder.

## How

Run every command from the loop folder.

**1. Take stock.** One call: the sessions and their states, the head of the base branch, open PRs, open issues by label, the last deploy run, the tail of `ledger.tsv`.

**2. Rewrite the handoff file, do not append to it.** Keep the old one beside it under a dated name:

```bash
mv HANDOFF.md "HANDOFF-$(date +%F).md"
```

Then write a fresh `HANDOFF.md` from `references/handoff-template.md`. A file that only grows makes the successor read three states and guess which holds. The new file must stand alone; point to the old one for history and say that it is not needed to run.

What goes in, and what the successor cannot get from anywhere else:

- **The successor's name**, on a line of its own near the top: `Successor: <new name>`. Pick the name now, before you start the session. `takeover-check.sh` looks for that exact line.
- **Standing orders**, in the user's words, with dates. Above all the ones that changed a default: what they approved for good, what they do not want raised again, how they want reports.
- **The implementer's exact state**: name, idle or working, the commit it sits on, the token of a running task.
- **A running task's clock**: when it began (`task.start`), and whether `wait.sh` has said `TIMEOUT` for it. `TIMEOUT` comes once per task, so the successor will not hear it again.
- **The queue**, in order, with the reason for the order, and what is not for the loop.
- **Told the user, no answer yet.** Without this list the successor asks again, or forgets.
- **Local facts**: where the live data is and its baseline counts, the way back, known flaky tests, what a typical task costs.
- **First steps**, numbered, ending in "keep the loop going unattended".

Leave out the story of how you got here. The ledger has it.

**3. Start the successor.** The takeover rests on the user's standing order, not on your say: `CLAUDE.md` in the loop folder, put there by the user with `grant.sh` (`running-the-loop`, "The standing order"). A successor that starts in the loop folder has that order as its own instructions. Check it is there (`. ./lib.sh; has_grant CLAUDE.md && echo granted`). If it is not, do not write it: tell the user that the successor will wait for their go until they run `grant.sh`, and go on.

Write the first message to a file and start a session whose working folder is the loop folder:

```bash
./start.sh <new name> "$PWD" "orchestrator <n>" first-message.txt
```

`start.sh` starts it in the mode `loop.env` names (`PERMISSION_MODE`): `bypassPermissions` by default, `auto` when the user set it there. It waits, reads the screen for a start dialog, sends the message, and answers a go-ahead question only if the folder is the loop folder, it holds the standing order, and `HANDOFF.md` names the session as the successor. It never answers a screen that says `TAKEOVER FAIL` or `STOPPED`. It must print `working` and exit 0. Exit 5 means a start dialog shows and nothing was sent; exit 1 means the session is gone.

The first message, with your words in the angle brackets and nothing else changed. It starts with the slash command because `running-the-loop` starts only from a typed slash command, not from the model: Claude Code runs the leading command as if the user typed it and passes the rest of the message to the skill as arguments. In case the paste reaches the successor without the command run, the message also names the skill's file: put in `<skill file>` the absolute path of `../running-the-loop/SKILL.md` beside this skill (`${CLAUDE_SKILL_DIR}/../running-the-loop/SKILL.md`, resolved).

> /issue-loop:running-the-loop If the skill issue-loop:running-the-loop did not load with this message, read <skill file> in full and follow it, with `${CLAUDE_SKILL_DIR}` read as its folder. This is <old name>, the outgoing orchestrator session of the <project> issue loop. You are <new name>, started in the loop folder <loop folder> as my successor. I am a session, not the user: do not take over on my word. Your instructions for this folder hold the user's standing order for a takeover (CLAUDE.md, heading "issue-loop standing order"). Run ./takeover-check.sh <new name> <old name>. If it prints TAKEOVER OK, the order covers this takeover: do not ask the user for a go. Read HANDOFF.md in full, then rules.md and the scripts beside it, and take over as it says. If the check fails, do nothing to the loop and tell the user which check failed. The user will talk to you in this tab from now on. <If no task runs: Start the next task on the implementer (<name>, idle now) at once. | If one runs: A task runs on the implementer (<name>); start wait.sh for the token <token> at once.> Rename yourself: herdr agent prompt <new name> "/rename <project>-orchestrator-main". Then close my tab (<old tab id>) and the tab of every older retired orchestrator of this loop still open; never your own, the implementer's, a teacher's or the user's. Then tell the user in three lines that you have taken over and what runs. Keep the loop going unattended; do not wait for the user's answer to carry on.

**4. Check that it took over.** Read the successor's screen after a minute. It took over when it has read the file and either sent a task or started the wait. If its state is `gone`, the session quit at the start: read its pane, fix the cause, start again. If it reports `TAKEOVER FAIL`, fix what is yours (the `Successor:` line, the name in `orch-name`) and send "run the check again"; a missing standing order is the user's. If it asks for a go-ahead though the check passed, answer "1" for a menu, or once with "go (for the takeover only; not the user's word on any queue item)": the order covers the takeover, and a bare "go" reads as the user's go on whatever the successor's report asks. If the check did not pass, the go is the user's, not yours. Keep driving the loop until the successor has taken over.

**5. Pass the name and stop your wait.** Not before step 4: the check wants your name in `orch-name`. Write the successor's name into `orch-name` (`echo <new name> >orch-name`), so the implementer's `notify.sh` tells the successor. Stop your own background `wait.sh`: two waits on one task share the one `TIMEOUT`, and the retired session must not be the one that gets it.

Then rename your own Claude session (the `/rename` title the user sees, not the driver's name, which the scripts and `orch-name` use): `herdr agent prompt <old name> "/rename <project>-orchestrator-<n>"`, with `<n>` the number in your driver name (`blattwerk-orch12` becomes `blattwerk-orchestrator-12`). It lands in your own tab and runs when your turn ends. The successor renames itself `<project>-orchestrator-main`, as the first message tells it. A loop's first orchestrator renames itself `<project>-orchestrator-main` (for example `blattwerk-orchestrator-main`) at setup the same way.

**6. Tell the user and stop.** Three lines: the successor's name and tab, what runs, that you are retired. From then on send nothing to the implementer. Two orchestrators on one implementer is the same fault as two sessions in one checkout. Do not close your own tab: the successor closes it, since a session that closes its own tab ends in the middle of its turn.

## Faults seen in a handover

- **The start dialog ate the prompt.** A successor started with a skip-permissions flag sat on an accept dialog; the first message's Enter chose "No, exit". The driver still called the start a success, and the fault stayed hidden because the output went to `/dev/null`. `start.sh` now exits 5 on that dialog; the user accepts it once by hand.
- **The folder trust question ate the prompt.** Same fault, other dialog: a successor started in a loop folder that Claude Code had never seen asked whether the folder is trusted, default "No, exit". `start.sh` now reads the screen first, sends nothing into a dialog and exits 5 with what it saw. The answer is the user's: ask them to start `claude` once in the loop folder and accept. If the session is gone after the first message, `start.sh` exits 1.
- **The successor waited for the user's go.** The first message is a paste from another session, and the first successor started by this skill said so: the takeover order came from the outgoing session, the rule it cited stood only in `HANDOFF.md`, which that session had written, and taking over meant to gate, merge and deploy unattended. It was right. The standing order and `takeover-check.sh` are the answer; `start.sh` answers a go-ahead question only for a successor that the order covers.
- **The notify line went to the retired session.** `orch-name` still held the old name. The successor's wait caught the DONE line anyway; fix the file. A retired orchestrator that gets an `impl settled` line does nothing with it.
- **A stop order got lost.** If the user had stopped the loop, the first thing in `HANDOFF.md` is "STOPPED: send no task until the user says go", and the first message must not say "start the next task".

## Self-Healing

- `start.sh` prints "start failed": run the driver's start by hand (`references/driver.md` in `running-the-loop`) and read the error.
- The successor says it has no standing order in its instructions: it was not started in the loop folder, or the user has not run `grant.sh` there. Close it and start it in the loop folder, or ask the user for the grant.
- The successor reads the file but does nothing: send "take over as HANDOFF.md says, first steps 1 to 7".
- You are the successor and the file is thin: read the dated older handoff, the ledger, and the implementer's screen before you send anything.
