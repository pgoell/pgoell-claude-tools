# Setup: what the repo needs before the loop can run

Check each point. Tell the user what is missing and offer to make it the first tasks of the loop: the loop can build most of its own machine, and did so on the example project.

## Must have

| Need                                                | Why                                                                                                              | Check                                                                          |
| --------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Issues as the queue                                 | The loop has no other memory of what to build. Each issue says what "done" means                                 | `gh issue list --state open --limit 300`                                       |
| Labels                                              | Without labels the queue cannot be put in order. `bug`, `regression`, `wish`, `test-debt`, and one for "not now" | `gh label list`; make them with `gh label create <name>`                       |
| CI as the merge gate                                | The implementer merges with `--auto`. Only a required check stops a red PR                                       | `gh api repos/{owner}/{repo}/branches/<base>/protection` shows required checks |
| Checks on the newest commit                         | A merge once fired before CI ran on the last commit of a PR. The gate script cannot see that                     | branch protection: require branches to be up to date, required checks set      |
| A deploy the loop can check                         | "Merged" is not "live". The gate compares the last good deploy run with the head of the base branch              | `gh run list --workflow <name> -L 3`, and a URL for `ALIVE_URL`                |
| A way back                                          | With nobody watching, a bad deploy must be undone by a command, not by thought                                   | the README says how; the old build is kept                                     |
| A test suite that runs in minutes                   | Tests are the loop's only proof. A slow suite ate half of an early task                                          | time the full suite; make it run in parallel first if it takes over 2 minutes  |
| An implementer checkout of its own                  | Two sessions in one checkout revert each other's files                                                           | no other session has that folder as its working folder                         |
| `gh` logged in, `jq`, GNU `date`, `timeout`, `curl` | the scripts use them                                                                                             | `gh auth status`, `jq --version`                                               |

## The alive URL

Do not point `ALIVE_URL` at the front page. On the example project the front page answered 200 as plain HTML while the app behind it was dead. Pick a route that must read the database, or one that returns the commit that runs.

## Labels and what they mean in the loop

- `regression`: a PR of the last days brought it in. Runs first.
- `bug`: the base branch already had it. Runs in batches.
- `wish`: behaviour beyond what an issue asked. Runs after the bugs; "not now" holds one back.
- `test-debt`: a flaky or missing test. Worth a batch now and then.
- the "not now" label (`later` on the example project): needs the user's decision. Never runs.

## Worth building early, as the loop's own first tasks

These are the stand-ins for a person who watches. `references/limits.md` says what each one catches.

1. A snapshot of the live data before every deploy, taken by the deploy itself.
2. A canary: the new build runs on a copy of the data and passes a smoke test before it goes live. An automatic way back if the live check fails.
3. A fence: a `PreToolUse` hook in the repo that refuses the commands with no way back (admin merges, `--no-verify`, force pushes, container commands on the live stack, writes into the live data folder).
4. The rule that a PR on the machine's own files gets a second review.

## What stays with the user

Branch protection itself (bind admins too, name the required checks). The loop's token can often change it, and for that reason the loop must not: the orchestrator does not change its own limits.

## Setup, once per repo

Then make the loop folder, outside every checkout:

```bash
"${CLAUDE_SKILL_DIR}/scripts/init.sh" ~/loops/<project>
```

It writes `loop.env`, `models.env`, `rules.local.md`, `ledger.tsv`, `standing-order.md`, `standing-order-impl.md` and a blank `HANDOFF.md`, and eight stubs: `next.sh`, `wait.sh`, `gate.sh`, `start.sh`, `notify.sh`, `grant.sh`, `takeover-check.sh` and `lib.sh`. A stub runs the same script from the installed plugin, so the folder never holds a copy to go stale. Then:

1. Edit `loop.env`: the implementer's session name, its checkout, the base branch, the deploy workflow, a URL that proves the app is alive. Leave `ISSUE_LOOP_VERSION=latest`, or set an exact version to pin one. Check `models.env` with the user: the model per role in the Claude Code column.
2. Answer the plugin's rules in `rules.local.md` with the user. A `## N.K` section answers the K-th `<FILL: ...>` of rule N. A `## N` section is a whole rule of the loop's own, and an empty `## N` drops rule N. `next.sh` lists each `FILL` without an answer and refuses to send a brief with one. `references/brief-rules.md` gives the reason behind each rule, so the user can drop one that does not fit.
3. Write the user's standing orders into `HANDOFF.md` as they give them. That file is your memory.
4. Write your own session name into the file `orch-name` in the loop folder: the name this session was started under. If you cannot tell which name in the driver's list is yours (with herdr, `herdr agent list`), ask the user. Rule 19 of the brief has the implementer tell that session when it is done. `next.sh` refuses to send a brief while the file is missing. Then name the Claude session for the user: `herdr agent prompt <your name> "/rename <project>-orchestrator-main"` (it runs when your turn ends). The driver's name stays as it is; the scripts use it. At a handover the names and the old tabs change as `handing-over` says.
5. Ask the user to start `claude` once in the loop folder and accept the folder trust question. A successor orchestrator starts in that folder, and a session in a folder Claude Code has never seen sits on that question. Trusting a folder is the user's choice: never answer it for them.
6. Get the user's standing order (next section). `next.sh` refuses to send a brief without it.
7. Start the implementer if none runs: write a one-line hello to a file and run `./start.sh <name> <checkout> "<tab label>" <file>`. The implementer should have a checkout of its own that no other session works in. One that ran before the standing order was granted must be started anew, since a session reads its instructions when it starts.

If the host has no herdr, read `references/driver.md` and write the five driver functions for what the host has, before anything else.

## Granting the standing order

So the user gives the order once, in their own channel, where every later session finds it as its instructions:

1. Ask the user in plain words: "May the orchestrator send the implementer its briefs, and may an orchestrator hand the loop to a successor, without your go each time? What stays yours?" Take their answer as it comes.
2. Fill the `<FILL: ...>` marks in `standing-order.md`: the project, the user's own words with the date, the orchestrators' names or their pattern, and what stays the user's. Do not put words in their mouth: where they said nothing, write the default and say that it is the default. Read `standing-order-impl.md` with them; it has no marks.
3. The user runs `./grant.sh` in a terminal of their own. It prints both texts, asks for a typed yes, and then writes `CLAUDE.md` in the loop folder (for orchestrators) and `CLAUDE.local.md` in the implementer's checkout (kept out of git through `.git/info/exclude`, so the gate's clean-tree check holds). Claude Code loads both as the user's instructions for a session that starts there.
