---
name: setting-up-the-check
description: Use when the user wants to add a file-size limit to a repo, cap file size for agents, set up the 5000-token check, or update the check in a repo that already has it. Copies the check script into the repo, lists the files already over the limit, and wires it into lefthook pre-commit on staged files, pre-push and CI on all tracked files, or into plain git hooks when the repo has no lefthook.
---

# Setting Up the File-Size Check

The check fails when an authored file passes 5000 tokens (bytes/4). Big files cost agents: they read them in pieces and lose track. This skill puts the check into any git repo: pre-commit sizes the staged files, pre-push and CI size every tracked file at HEAD.

**Platforms.** The skill uses only shell and file tools, so it runs the same in Claude Code, Codex and Cursor.

**Assets.** The script and hook templates sit beside this SKILL.md: `assets/check-file-size`, `assets/pre-commit`, `assets/pre-push`. The commands below write `"${CLAUDE_SKILL_DIR}/assets/..."`, which Claude Code sets. In Codex and Cursor, replace `${CLAUDE_SKILL_DIR}` by the absolute path of the folder that holds this SKILL.md; never leave it empty, or `cp` reads from `/assets`.

## When NOT to invoke

- The user wants one big file split now, with no check: split it along a deep module and stop.
- The repo is not a git repo: the check reads git's index; say so and stop.

## Step 1: Look at the repo

Work from the repo top and find what is there:

```bash
cd "$(git rev-parse --show-toplevel)"
ls lefthook.yml .lefthook.yml lefthook.yaml .lefthook.yaml 2>/dev/null
command -v lefthook || mise exec -- lefthook version
ls mise.toml .mise.toml 2>/dev/null
ls .github/workflows/*.yml .github/workflows/*.yaml 2>/dev/null
git config --get core.hooksPath
ls .git/hooks/pre-commit .git/hooks/pre-push 2>/dev/null
ls scripts/check-file-size .file-size-excludes 2>/dev/null
```

Note the answers: a lefthook config file (and whether `lefthook` runs bare or only through `mise exec --`), CI files, a set `core.hooksPath`, real hooks in `.git/hooks` (not `*.sample`). If `scripts/check-file-size` already exists, this run is an update.

The repo uses lefthook only when it has one of those config files. `lefthook` on PATH without a config does not count: go to step 5, or ask the user whether to start a `lefthook.yml` instead.

## Step 2: Copy the script

```bash
mkdir -p scripts
cp "${CLAUDE_SKILL_DIR}/assets/check-file-size" scripts/check-file-size
chmod 755 scripts/check-file-size
```

The repo carries its own copy because CI and fresh clones cannot see the plugin's install path. On a rerun this step is the update: recopy the script, then go on to step 3. Never touch an existing `.file-size-excludes`; it belongs to the repo. If `scripts/check-file-size` exists but does not print `file-size:` lines (another tool's script), stop and ask before you overwrite it.

## Step 3: List the files already over the limit

Run the script bare, from the repo top, before you wire anything:

```bash
scripts/check-file-size
```

No output means no offenders. Otherwise it prints one `file-size: <path> is ~N tokens (bytes/4); the limit is 5000.` line per file, then advice. Show the user the list and ask, file by file:

- **Split it** along a deep module, as the script's message says (a small interface over much hidden work; never by line count, never into pass-through wrappers).
- **Exclude it** with a glob in `.file-size-excludes`. Only for files no person or agent edits by hand: generated, vendored, ported, data.

The script already skips lockfiles, images, fonts, PDFs and license texts. `.file-size-excludes` at the repo root adds to those defaults:

- one git glob per line, anchored at the repo root;
- `*` stays inside one folder, `**/` crosses folders;
- a line that starts with `#` is a comment; blank lines are ignored;
- the rest of a line is taken as is: no leading `/` (write `dir/**`, not `/dir/**`) and no trailing `# comment`;
- no file means the defaults only. The script finds the file from any subdirectory and reads the working-tree copy.

```text
# generated
**/generated-*.ts
# vendored
third_party/**
# data
data/words.txt
```

Create or edit it with your file tools. A bare run sizes the files at HEAD but reads `.file-size-excludes` from the working tree: a new exclude line counts at once, a split counts only once committed. So commit each split (and the excludes file) before you rerun `scripts/check-file-size`, and repeat until it prints nothing. Ask the user before you commit.

Pre-commit sizes only the files a commit stages, so wire it (step 4 or 5) even while offenders remain. Do not wire pre-push or CI while the bare run still fails, unless the user says so: every push and every CI run would fail.

## Step 4: Wire lefthook, if the repo uses it

Only when step 1 found a lefthook config file; otherwise go to step 5. Add a pre-commit job `file-size` with `run: scripts/check-file-size {staged_files}` and a pre-push job `file-size` with `run: scripts/check-file-size`. Merge into the existing config; keep every job it has. Read [references/lefthook.md](references/lefthook.md) first: it covers both config shapes, the `parallel` and `stage_fixed` trap, and when to append to an existing `lint` task instead. Then install the hooks with the same prefix lefthook needed in step 1:

```bash
lefthook install    # or: mise exec -- lefthook install
```

## Step 5: Plain git hooks, if the repo has no lefthook

Use the versioned hook folder `.githooks/` and the templates `assets/pre-commit` and `assets/pre-push`. Never overwrite an existing hook or a set `core.hooksPath`. Read [references/fallback-hooks.md](references/fallback-hooks.md): it says which of three cases you are in and the exact lines for each. When you set `core.hooksPath` yourself, tell the user that each clone must run `git config core.hooksPath .githooks` once, and write that line down where the next person will find it (the reference says where).

## Step 6: CI

Run `scripts/check-file-size` in CI after the checkout step: in an existing lint job, or a new small job. [references/ci.md](references/ci.md) has the GitHub Actions YAML and the one command for other CI systems. If the repo has no CI, skip this step and give the user that one command to add later.

## Step 7: Check it works

First make sure nothing else is staged; this commit must carry only the test file:

```bash
git diff --cached --name-only
```

If that prints anything, stop and ask the user. Otherwise make a file one byte past the limit and try to commit it:

```bash
truncate -s 20004 x.txt
git add x.txt
git commit -m "test: file-size check"
```

Expect the commit to fail with `file-size: x.txt is ~5001 tokens (bytes/4); the limit is 5000.` Then clean up:

```bash
git rm --cached -q x.txt
rm x.txt
```

If the commit went through, the hook did not fire. Undo it with `git reset --soft HEAD~1` only when HEAD is that test commit, run the cleanup above, and see Self-Healing.

Last, run the bare check and expect no output:

```bash
scripts/check-file-size
```

Leave the new and changed files (`scripts/check-file-size`, the hook config, the workflow, `.file-size-excludes`) for the user to review and commit, unless they asked you to commit.

## Step 8: Skip the check once

Tell the user how to skip it for one commit or push:

- lefthook: `LEFTHOOK_EXCLUDE=file-size git commit ...`, `LEFTHOOK_EXCLUDE=file-size git push`;
- plain git hooks: `git commit --no-verify`, `git push --no-verify`.

CI still runs the check.

## Self-Healing

- **No commit yet.** A bare run sizes the index, not HEAD, until the first commit exists. That is expected.
- **`fatal: not a git repository`.** `git ls-files` runs outside a repo. `cd` into the repo; the script itself works from any subdirectory.
- **`mktemp` fails.** The script needs a writable temp folder. Set `TMPDIR` to one, for example `TMPDIR="$PWD/.tmp"` after `mkdir -p .tmp`.
- **Hooks do not fire.** With lefthook, run `lefthook install` (or `mise exec -- lefthook install`) and check `.git/hooks/pre-commit` is lefthook's. Without it, check `git config --get core.hooksPath` prints the folder that holds the hooks (with Husky, `.husky/_` runs the hooks in `.husky/`) and that they are executable (`chmod 755`).
- **`Permission denied` on the script.** Run `chmod 755 scripts/check-file-size` and commit the mode: `git update-index --chmod=+x scripts/check-file-size`.
