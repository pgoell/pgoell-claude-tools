# Running the check in CI

The CI run is bare: it sizes every tracked file at the checked-out commit. A shallow checkout is enough.

## GitHub Actions, existing lint job

If a workflow under `.github/workflows/` already has a lint job, add one step after its `actions/checkout` step:

```yaml
- run: scripts/check-file-size
```

## GitHub Actions, new workflow

Otherwise create `.github/workflows/file-size.yml`. Find the default branch with `git symbolic-ref --short refs/remotes/origin/HEAD` (it prints `origin/<branch>`; use the part after the slash). If that fails, ask the user.

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
