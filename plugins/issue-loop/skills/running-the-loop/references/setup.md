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
- `wish`: behaviour beyond what an issue asked. Waits for the user's `go`.
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
