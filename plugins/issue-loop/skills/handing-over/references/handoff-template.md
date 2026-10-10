# Handoff: you are the orchestrator of the issue loop for <project>

Written <date and time> by the outgoing orchestrator<, on the user's order: "their words">. The user talks to you in your tab. You drive the implementer session; you do not code, and you do not write to its checkout (<path>). You may read it and use gh.

Run the loop by the skill `issue-loop:running-the-loop`. This file holds what the skill cannot know.

## Standing orders

<The user's orders, in their words where it matters, each with its date. For example:>

- <What the loop is for and the bar: "their words">
- <Order of the queue, if they changed the default>
- <Labels that never run>
- <What they approved for good, for example who merges PRs on the machine's own files>
- <What they do not want raised again>
- <How they want reports: length, language, device they read on>
- Sessions run in auto mode, never with skipped permissions.

## Sessions

- `<implementer name>`: the implementer. <State: idle on a clean base branch at commit X | working on task Y since Z>.
- `<old orchestrator name>`: retired once you confirm.
- You: check your own name with the driver's list command.

## How to drive

Scripts in this folder: next.sh, wait.sh, gate.sh, start.sh (see the skill). Local notes:

- <What differs here from the skill: a changed time limit, an extra check, a driver quirk>
- <Rules added to rules.md since the start, with the fault behind each>

## After every task, here

- <The live data check for this project: where the data is, how to open it read-only, the baseline counts>
- <Where the deploy keeps its snapshots>

## The machine as it stands

- <Deploy: what a merge sets off, in one line. The way back, and where it is written down>
- <Hooks and fences in the repo>
- <Test lanes, known flaky tests>
- <Typical task: minutes, cost, issues filed>

## Queue

1. <What runs next, with issue numbers and the reason for the order>
2. <...>

Not for the loop: <issues that need the user, a real device, or a decision; say which>.

## Told the user, no answer yet

- <Each open point, so you neither forget it nor ask it again>

## Where things are

- <Loop folder, ledger, reports, the live URL>

## First steps

1. Read rules.md and the scripts in this folder.
2. List the sessions and the open issues. Confirm the implementer's state.
3. <If a task runs: start wait.sh for token X. If not: send queue item 1 with next.sh, then start wait.sh.>
4. Tell the user in three lines that you have taken over and what runs.
5. Keep the loop going unattended. Hand over on your own at about 150k tokens of context.
