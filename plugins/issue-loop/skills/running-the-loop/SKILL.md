---
name: running-the-loop
description: Use when the user wants an unattended build loop over a repo's GitHub issues, with this session as the orchestrator that drives one implementer session task after task, for example "run the issue loop on this repo", "work through the open issues unattended", "drive the implementer session through the queue", or "set up the issue loop here". Covers setup, the task brief, the wait, the gate after each task, queue order, what goes to the human, and the limits of such a loop. Not for building one feature in this session, and not for passing the loop to a new session (use handing-over).
---

# Running the Loop

You are the orchestrator of an issue loop. One other Claude Code session, the implementer, builds. You pick the task, send the brief, wait, check the result from outside, tell the user, and send the next task. The loop runs until the queue is empty or the user says stop.

This skill drives Claude Code sessions (`/clear`, `--permission-mode auto`, subagents). The scripts speak to them through a driver; the bundled driver is for herdr.

## When NOT to invoke

- One feature or one bug, built here in this session: just build it.
- You are an orchestrator whose context is filling up: use `issue-loop:handing-over`.
- The repo has no CI, no deploy and no issues: there is nothing for the loop to hold on to. Say what is missing (see `references/setup.md`).

## The shape

Four rules hold the loop together. Do not bend them.

1. **The orchestrator never codes and never writes to the implementer's checkout.** You read it, and you use `gh`. Two writers in one checkout collide.
2. **Every task starts clean.** The implementer gets `/clear` and the full brief each time: the task line plus the rules. Nothing carries over in its memory, so everything it needs is in the brief or in the repo.
3. **Subagents implement and review.** The implementer's main session plans, briefs, integrates and merges. You read no diffs.
4. **One task is one PR, merged, deployed, then checked from outside.** The implementer's word is not the check: the gate script is.

## Setup, once per repo

Read `references/setup.md` and check each point against the repo before the first task. In short, the repo needs: issues as the queue; the labels `bug`, `regression`, `wish`, `test-debt` and one label for "not now"; CI as a required check on the newest commit of a PR; a deploy the loop can check from outside; a way back.

Then make the loop folder, outside every checkout:

```bash
"${CLAUDE_SKILL_DIR}/scripts/init.sh" ~/loops/<project>
```

It copies `loop.env`, `rules.md`, `next.sh`, `wait.sh`, `gate.sh`, `start.sh`, `lib.sh`, `driver-herdr.sh`, `ledger.tsv` and a blank `HANDOFF.md`. Then:

1. Edit `loop.env`: the implementer's session name, its checkout, the base branch, the deploy workflow, a URL that proves the app is alive.
2. Fill every `<FILL: ...>` in `rules.md` with the user, or delete the rule. `next.sh` refuses to send a brief with a marker left. `references/brief-rules.md` gives the reason behind each rule, so the user can drop one that does not fit.
3. Write the user's standing orders into `HANDOFF.md` as they give them. That file is your memory.
4. Ask the user to start `claude` once in the loop folder and accept the folder trust question. A successor orchestrator starts in that folder, and a session in a folder Claude Code has never seen sits on that question. Trusting a folder is the user's choice: never answer it for them.
5. Start the implementer if none runs: write a one-line hello to a file and run `./start.sh <name> <checkout> "<tab label>" <file>`. The implementer should have a checkout of its own that no other session works in.

If the host has no herdr, read `references/driver.md` and write the five driver functions for what the host has, before anything else.

## One turn of the loop

Run every script from the loop folder (`cd <loop folder> && ...` in each call).

**1. Write the task line.** Name the issues. Say which must hold first. Say "one PR". Add what the last task taught you. End with the exact last line. A task line that works:

> Three issues in ONE PR: #41, #38, #39. Read each with gh issue view N --comments. #41 is a regression: do it first, it must hold, and name the PR that brought it in. For #38 and #39 add a test that fails before your fix and passes after. Where the parts touch different files, run subagents side by side. Last line of your report exactly: DONE #41 #38 #39

**2. Send it.** `./next.sh "<task line>"`. It refuses while the implementer works, because `/clear` would destroy the running task (`--force` sends anyway; use it only to stop a task on purpose). It prints the implementer's state, which must be `working`. If it prints `done`, `idle` or `blocked`, read the screen (`references/quirks.md`, "The go-ahead question").

**3. Wait in the background.** `./wait.sh "#41"` with the first issue of the DONE line as the token. Run it as a background shell call with the longest timeout the host allows. It prints one word:

| Word      | Meaning                            | Do                                                                                                                                               |
| --------- | ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `settled` | the DONE or BLOCKED line is there  | go to step 4                                                                                                                                     |
| `TIMEOUT` | the task is older than 100 minutes | read the screen first. In merge or deploy: let it finish. Else send "finish by rule 10 now" once. At 130 minutes stop the task and tell the user |
| `ASKING`  | the session waits on a question    | read the screen. See "Permission mode" below                                                                                                     |
| `GONE`    | no session has that name           | the session died. Tell the user; start a new one with `start.sh` once the checkout is clean                                                      |

If the shell call itself times out with no word, start `wait.sh` again. Never wait with a bare sleep, and never trust the state "idle" or "done" alone: a session pauses between steps. The DONE line is the signal.

**4. Gate and read.** `./gate.sh 41 38 39`, and read the last 60 to 130 lines of the implementer's report (`. ./lib.sh; drv_read "$IMPL" 130`). `GATE PASS` means: issues closed, every PR since the task began merged with no open box, the live commit is the head of the base branch, the checkout is clean, the app answers. Read these parts of the report above all:

- **Not fixed**: review findings the task left in.
- **Slips**: rules the task broke (a `sed -i`, a test bent to pass, an unreviewed commit).
- **Issues opened**: this is where shipped faults hide. For each, ask: is it a gap in what was asked, a privacy or data fault, or something that hides the product's main function? If yes, it runs NEXT.
- **Heads up** lines at the bottom of the session's screen.

**5. Check what the gate cannot.** If the task touched stored data (`TOUCHES LIVE DATA`), open the live data read-only and compare integrity and row counts with your baseline in `HANDOFF.md`. If it touched the machine (`TOUCHES THE MACHINE`, or a `TELL HUMAN` line from the gate), check the changed part on the real thing and tell the user what changed and the way back.

**6. Tidy the queue.** Label what the task opened if it did not. Move a "wish" that is really a fault to `bug`.

**7. Ledger.** Append one tab-separated line to `ledger.tsv`: date, issues, PRs, minutes, closed, opened (regression/bug/wish/test-debt), not fixed, notes.

**8. Send the next task, then report.** Do not wait for the user's answer. The report is a few short lines:

> Shipped and live: PR #52, 51 min, gate passes. Closes #41, #38, #39.
> Review caught one fault before merge (a key that deleted a block).
> Weak spot, said by the session itself: the #38 tests were never seen failing.
> New: #53 (bug), #54 (wish).
> Running now: #53 with #47 and #48. Next: the search feature.

Say bad news as plainly as good news: over the time box, an unreviewed commit, a fault that shipped.

## What runs next

1. A gap or fault the last task shipped, and regressions. They go first and "must hold".
2. What the last task left of its own issues.
3. Open bugs, in batches of about five related ones per PR. Group by file area so subagents can run side by side.
4. Then one feature. Then the bugs that feature filed, before the next feature.
5. Wishes wait until the user marks them (a `go` label works). The "not now" label never runs.

A feature task opens more issues than it closes; a bug batch about breaks even. So bugs first, or the queue only grows.

When you learn something, change the brief: a fault you saw twice becomes a clause in the next task line, and a fault that will come again becomes a rule in `rules.md`. Tell the user when you add a rule.

## What you decide and what goes to the human

Decide alone, and tell after: the order of the queue, the batch, labels, new rules in the brief, the time box of a task, whether a low-risk gap may stand, starting a side session for research or review.

To the human, always:

- **Taste**: how it looks, how it reads, a product choice the implementer made alone. Report it as "yours to overrule".
- **Money**: anything that costs beyond the sessions themselves.
- **Real devices**: what only a real phone, tablet or laptop can show.
- **Anything that loosens a gate**: branch protection, required checks, the fence hook, the permission mode, who may merge. You do not change your own limits.
- A session's permission question you cannot answer from a standing order.
- Deleting work you did not make (a worktree with uncommitted changes).

Do not add a gate the user did not ask for. A PR that waits for the user's merge stops the loop; if the user wants that gate, they will say so. If the user's answer is unclear, say how you read it and carry on.

## Permission mode

Sessions run in auto mode: `claude --permission-mode auto`. Never start one with `--dangerously-skip-permissions`. `start.sh` reads the mode from `loop.env`.

In auto mode a session may stop on a question. There are two kinds, and they get different answers:

- **The go-ahead question** about a pasted brief ("your message was only a pasted block", `Reply "go"`, or a menu whose first item runs the brief). The brief is the user's standing order. `next.sh` and `start.sh` answer it once with "go" or "1". If it shows up later, answer it the same way.
- **A tool permission question**, or a hook that refused a command. This is not yours to approve. Read the screen, tell the user what the session wants and why, and wait for the user's answer. If the session can do the task another way, tell it to, or tell it to end with BLOCKED.

## Stop

When the user says stop: say how you read it ("I stop after the running task"), let the task finish, run the routine, write "STOPPED on the user's order" with the state and the queue at the top of `HANDOFF.md`, and report totals. Send nothing until the user says go.

At about 150k tokens of context, hand over: `issue-loop:handing-over`.

## Tool names

| Need                      | Claude Code                                    |
| ------------------------- | ---------------------------------------------- |
| background wait           | Bash with `run_in_background: true`            |
| side by side source reads | Agent tool, default model                      |
| a second opinion          | advisor tool where present, else a fresh agent |

The loop was built and run with Claude Code sessions only. Under Codex the orchestrator's part may work, but nobody has tried it, and the brief's `/clear` and permission mode are Claude Code's.

## References

- `references/setup.md`: what the repo needs, point by point, and how to check each.
- `references/driver.md`: the five driver functions, what is herdr-specific, how to swap the driver.
- `references/brief-rules.md`: each rule of the brief with the fault that earned it.
- `references/quirks.md`: the faults that cost time, and the fix for each. Read it before the first task.
- `references/limits.md`: what the loop proves and what not, numbers from the first run, and the stand-ins for a real user.

## Self-Healing

- `next.sh` exits 4: the implementer still works. Wait for its DONE line.
- `start.sh` exits 5: a start dialog shows and nothing was sent. It prints the screen. A folder trust question goes to the user.
- `next.sh` exits 3: `rules.md` has a `FILL:` marker left, or it uses a setting that is empty in `loop.env` (a repo with no deploy: rewrite rule 9, then leave `DEPLOY_WORKFLOW` and `ALIVE_URL` empty).
- `gate.sh` fails "not on <base>" or "working tree dirty" in the middle of a task: that is normal, the gate is for after the task.
- `gate.sh` fails "live is X, <base> is Y" right after the DONE line: the deploy may still run. Look at `gh run list`, wait a minute, run the gate again.
- A driver call fails: run the driver's own command by hand (`herdr agent list`) and read `references/driver.md`.
- The implementer's state is `gone` but its tab is there: read the pane itself (`herdr pane read <pane id>`); a start dialog may have closed the session.
