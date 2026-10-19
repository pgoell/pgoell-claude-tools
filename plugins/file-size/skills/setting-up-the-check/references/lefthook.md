# Wiring the check into lefthook

Read the repo's lefthook config (`lefthook.yml`, `.lefthook.yml`, `lefthook.yaml` or `.lefthook.yaml`) in full before you edit it. Edit it with your file tools; keep every job and setting it has. If a `file-size` job already exists, leave it as it is (an update needs only the new script from step 2).

## The jobs

Newer configs list jobs under `jobs:`. Add one entry to each hook, after any formatter job:

```yaml
pre-commit:
  jobs:
    # ...existing jobs stay...
    - name: file-size
      run: scripts/check-file-size {staged_files}

pre-push:
  jobs:
    # ...existing jobs stay...
    - name: file-size
      run: scripts/check-file-size
```

Older configs use a `commands:` map. Match that shape:

```yaml
pre-commit:
  commands:
    file-size:
      run: scripts/check-file-size {staged_files}

pre-push:
  commands:
    file-size:
      run: scripts/check-file-size
```

If the config has no `pre-commit:` or `pre-push:` key, add it. lefthook runs jobs from the repo top, so the relative path works.

## Formatters that re-stage files

If a pre-commit job runs a formatter with `stage_fixed: true` and the hook has `parallel: true`, the file-size job may size the copy from before the formatter ran. Tell the user, and make pre-commit sequential: drop `parallel: true` and put the file-size job after the formatter. Leave a comment so nobody turns it back on:

```yaml
pre-commit:
  # Not parallel: file-size must size what format re-staged.
  jobs:
    - name: format
      run: <the formatter> {staged_files}
      stage_fixed: true
    - name: file-size
      run: scripts/check-file-size {staged_files}
```

## A lint task that pre-push and CI already run

If the repo has a lint task (a `mise` task, a `Makefile` target, an npm script) and both the pre-push hook and CI run it, you may append the bare run there instead of adding the pre-push job and the CI step. Then one place runs it on every tracked file. For a mise file task, add a last line `scripts/check-file-size`; for a `mise.toml` task, add it to the `run` list. Say which way you chose.

## Install

Run `lefthook install` (or `mise exec -- lefthook install` when lefthook comes only through mise). Check that `.git/hooks/pre-commit` and `.git/hooks/pre-push` now exist and name lefthook.
