# Running the checks in CI

CI runs both checks on the whole repo: `check-file-size` bare sizes every tracked file at the checked-out commit, `check-fan-out --all` counts every folder. A shallow checkout is enough.

## GitHub Actions, existing lint job

A lint job is a job that already runs format or lint checks on every pull request. If a workflow under `.github/workflows/` has one, add two steps after its `actions/checkout` step:

```yaml
- run: scripts/check-file-size
- run: scripts/check-fan-out --all
```

## GitHub Actions, new workflow

If no job like that exists, create `.github/workflows/structure.yml`. Find the default branch, trying these in order:

1. `git symbolic-ref --short refs/remotes/origin/HEAD` prints `origin/<branch>`; use the part after the slash. It fails in a repo that was not cloned.
2. `git config init.defaultBranch`.
3. `git branch --show-current`.

If all three fail, or the answer looks like a feature branch, ask the user.

```yaml
name: structure

on:
  pull_request:
  push:
    branches: [main]

jobs:
  structure:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: scripts/check-file-size
      - run: scripts/check-fan-out --all
```

Replace `main` with the default branch. If the repo makes checks required through branch protection, tell the user the new check is named `structure`; adding it there is their call.

## Other CI systems

Run these two commands from the repo top after the checkout, in any job that has bash, git and awk:

```bash
scripts/check-file-size
scripts/check-fan-out --all
```

Each exits 0 when all fits and 1 when something does not, and prints the offenders to stderr.

## No CI

If the repo has no CI at all, skip this step. Tell the user the two commands above, to add when they set up CI.
