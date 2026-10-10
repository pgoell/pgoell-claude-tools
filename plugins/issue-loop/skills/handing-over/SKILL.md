---
name: handing-over
description: Use when the orchestrator of an issue loop must pass the loop to a fresh session, because its context nears 150k tokens or the user says "hand over", "start a fresh orchestrator", or "your context is full, pass it on". Rewrites the handoff file, starts the successor in auto mode, sends the exact first message, and checks the successor took over. Not for starting a loop (use running-the-loop).
---

# Handing Over

An orchestrator's context fills up. Past about 150k tokens it forgets standing orders and repeats faults. The loop outlives the session through one file, `HANDOFF.md` in the loop folder, and a successor that reads it.

## When

- On your own at about 150k tokens of context. Do not wait to be told: on the example project the first orchestrator reached over 200k, and the user had to order the handover.
- At once when the user says so.
- Best between tasks. If a task runs, hand over anyway: the successor only has to start `wait.sh` with the right token. Say so in the file.

## How

Run every command from the loop folder.

**1. Take stock.** One call: the sessions and their states, the head of the base branch, open PRs, open issues by label, the last deploy run, the tail of `ledger.tsv`.

**2. Rewrite the handoff file, do not append to it.** Keep the old one beside it under a dated name:

```bash
mv HANDOFF.md "HANDOFF-$(date +%F).md"
```

Then write a fresh `HANDOFF.md` from `references/handoff-template.md`. A file that only grows makes the successor read three states and guess which holds. The new file must stand alone; point to the old one for history and say that it is not needed to run.

What goes in, and what the successor cannot get from anywhere else:

- **Standing orders**, in the user's words, with dates. Above all the ones that changed a default: what they approved for good, what they do not want raised again, how they want reports.
- **The implementer's exact state**: name, idle or working, the commit it sits on, the token of a running task.
- **The queue**, in order, with the reason for the order, and what is not for the loop.
- **Told the user, no answer yet.** Without this list the successor asks again, or forgets.
- **Local facts**: where the live data is and its baseline counts, the way back, known flaky tests, what a typical task costs.
- **First steps**, numbered, ending in "keep the loop going unattended".

Leave out the story of how you got here. The ledger has it.

**3. Start the successor.** Write the first message to a file and start a session whose working folder is the loop folder:

```bash
./start.sh <new name> "$PWD" "orchestrator <n>" first-message.txt
```

`start.sh` starts it in auto mode (`--permission-mode auto`), waits, checks the session is there, sends the message, and answers the go-ahead question. It must print `working`.

The first message, with your words in the angle brackets and nothing else changed:

> Go, this is from the outgoing orchestrator session of the <project> issue loop, on the user's order: you are the new orchestrator. Read <loop folder>/HANDOFF.md in full, then rules.md and the scripts beside it, and take over as it says, using the skill issue-loop:running-the-loop. The user will talk to you in this tab from now on. <If no task runs: Start the next task on the implementer (<name>, idle now) at once. | If one runs: A task runs on the implementer (<name>); start wait.sh for the token <token> at once.> Then tell the user in three lines that you have taken over and what runs. Keep the loop going unattended; do not wait for the user's answer to carry on.

**4. Check that it took over.** Read the successor's screen after a minute. It took over when it has read the file and either sent a task or started the wait. If its state is `gone`, the session quit at the start: read its pane, fix the cause, start again. If it asks for a go-ahead, answer "go" or "1" once.

**5. Tell the user and stop.** Three lines: the successor's name and tab, what runs, that you are retired. From then on send nothing to the implementer. Two orchestrators on one implementer is the same fault as two sessions in one checkout.

## Faults seen in a handover

- **The start dialog ate the prompt.** A successor started with a skip-permissions flag sat on an accept dialog; the first message's Enter chose "No, exit". The driver still called the start a success, and the fault stayed hidden because the output went to `/dev/null`. Auto mode has no such dialog, and it is the rule anyway.
- **The successor asked the go-ahead question.** The first message is a paste too. `start.sh` answers it.
- **A stop order got lost.** If the user had stopped the loop, the first thing in `HANDOFF.md` is "STOPPED: send no task until the user says go", and the first message must not say "start the next task".

## Self-Healing

- `start.sh` prints "start failed": run the driver's start by hand (`references/driver.md` in `running-the-loop`) and read the error.
- The successor reads the file but does nothing: send "take over as HANDOFF.md says, first steps 1 to 5".
- You are the successor and the file is thin: read the dated older handoff, the ledger, and the implementer's screen before you send anything.
