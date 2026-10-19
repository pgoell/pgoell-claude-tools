# Running the check in CI

The CI run is bare: it sizes every tracked file at the checked-out commit. A shallow checkout is enough.

## GitHub Actions, existing lint job

A lint job is a job that already runs format or lint checks on every pull request. If a workflow under `.github/workflows/` has one, add one step after its `actions/checkout` step:

```yaml
- run: scripts/check-file-size
```

## GitHub Actions, new workflow

If no job like that exists, create `.github/workflows/file-size.yml`. Find the default branch, trying these in order:

1. `git symbolic-ref --short refs/remotes/origin/HEAD` prints `origin/<branch>`; use the part after the slash. It fails in a repo that was not cloned.
2. `git config init.defaultBranch`.
3. `git branch --show-current`.

If all three fail, or the answer looks like a feature branch, ask the user.

```yaml
name: file-size

on:
  pull_request:
  push:
    branches: [main]

jobs:
  file-size:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: scripts/check-file-size
```

Replace `main` with the default branch. If the repo makes checks required through branch protection, tell the user the new check is named `file-size`; adding it there is their call.

## Other CI systems

Run this one command from the repo top after the checkout, in any job that has bash and git:

```bash
scripts/check-file-size
```

It exits 0 when every file fits and 1 when one does not, and prints the offenders to stderr.

## No CI

If the repo has no CI at all, skip this step. Tell the user the one command above, to add when they set up CI.
