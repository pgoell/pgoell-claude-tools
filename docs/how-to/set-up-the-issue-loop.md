---
type: How-to Guide
title: Set up the issue loop
description: Prepare a repository, a loop folder and your standing order so that one Claude Code session can drive another through the GitHub issue queue.
tags: [issue-loop, claude-code, github, setup]
status: stable
---

# Set up the issue loop

`/issue-loop:running-the-loop` makes the current Claude Code session the orchestrator of an unattended loop: it briefs a second session, the implementer, one issue at a time, and checks each merged and deployed PR from outside. The skill walks you through setup itself; this page lists what you provide. Claude Code only.

## Before you start

On the host:

- Claude Code sessions in a terminal manager the orchestrator can drive. The bundled driver is for herdr; for another manager, write the five driver functions described in [driver.md](../../plugins/issue-loop/skills/running-the-loop/references/driver.md).
- A logged-in `gh`, plus `git`, `jq`, `curl`, `timeout` and GNU `date`.

In the repository:

- Open issues as the queue, each saying what "done" means.
- The labels `bug`, `regression`, `wish`, `test-debt`, and one for "not now" (`gh label create <name>`).
- CI as a required check on the newest commit of a PR (branch protection: require branches to be up to date).
- A deploy workflow the loop can check, a URL that answers only when the live app works, and a command that undoes a bad deploy.
- A test suite that runs in minutes.

The full list, with a check for each, is [setup.md](../../plugins/issue-loop/skills/running-the-loop/references/setup.md).

## Steps

1. Give the implementer a checkout of its own, which no other session uses.
2. In a Claude Code session, run `/issue-loop:running-the-loop`. It checks the repository and makes the loop folder outside every checkout, such as `~/loops/<project>`.
3. Fill in, with the orchestrator: `loop.env` (implementer session name, its checkout, base branch, deploy workflow, alive URL) and every `<FILL: ...>` mark in `standing-order.md`, and the answers to the plugin's `FILL` marks in `rules.local.md`.
4. Start `claude` once in the loop folder yourself and accept the folder trust question. A successor orchestrator starts there later.
5. Grant your standing order. In a terminal of your own, in the loop folder:

   ```bash
   ./grant.sh
   ```

   It prints the order, asks you to type `yes`, then writes `CLAUDE.md` in the loop folder and `CLAUDE.local.md` in the implementer's checkout (kept out of git). With it, a brief or a handover no longer waits for your go. No session may run this script for you; it refuses without a terminal.
6. Let the orchestrator start the implementer (`./start.sh`) and send the first brief.

Sessions start with permissions skipped (`claude --permission-mode bypassPermissions`), the default in `loop.env`. Set `PERMISSION_MODE=auto` there for a loop whose sessions should ask.

## Check it worked

- The first brief reaches the implementer, and it starts without asking for a go.
- After the task, the gate passes and a line appears in `ledger.tsv` in the loop folder.

Before you rely on the loop, read [limits.md](../../plugins/issue-loop/skills/running-the-loop/references/limits.md): tests prove logic, not taste, and no check in the loop is a person who uses the product. See [the issue-loop reference page](/reference/plugins/issue-loop.md) and the [plugin README](../../plugins/issue-loop/README.md).
