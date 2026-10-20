---
name: setting-up-the-checks
description: Use when the user wants to cap file size or folder fan-out in a repo, set up the 5000-token check or the 7-entry folder check, warn Claude Code at edit time, or update these checks in a repo that has them. Copies the check scripts and a Claude Code hook into the repo, lists today's offenders, writes a baseline, and wires the checks into lefthook pre-commit, pre-push, CI and the editor hook, or into plain git hooks when the repo has no lefthook.
---

# Setting Up the Structure Checks

Two checks keep a repo easy for agents to read:

- **File size.** `check-file-size` fails when an authored file passes 5000 tokens (bytes/4). Big files cost agents: they read them in pieces and lose track.
- **Fan-out.** `check-fan-out` fails when a folder holds more than 7 entries (files and folders). A long folder makes the reader scan it all to find one thing. The repo root and names that start with `.` do not count. A baseline file absorbs today's overages, so only growth fails.

Pre-commit checks what a commit stages, pre-push and CI check the whole repo, and a Claude Code `PostToolUse` hook runs both checks on each file the agent edits, so the agent learns at edit time. Both scripts print what to do when they fail: split along a deep module, or group by concept.

**Platforms.** The skill uses only shell and file tools, so it runs the same in Claude Code, Codex and Cursor. Step 6 (the editor hook) is for Claude Code; in a repo nobody opens in Claude Code, skip it.

**Assets.** Beside this SKILL.md: `assets/check-file-size`, `assets/check-fan-out`, `assets/structure-hook`, `assets/pre-commit`, `assets/pre-push`. The commands below write `"${CLAUDE_SKILL_DIR}/assets/..."`, which Claude Code sets. In Codex and Cursor, replace `${CLAUDE_SKILL_DIR}` by the absolute path of the folder that holds this SKILL.md; never leave it empty, or `cp` reads from `/assets`.

## When NOT to invoke

- The user wants one big file split or one folder grouped now, with no check: do that and stop.
- The user wants rules on which module may import which: use `setting-up-import-boundaries`.
- The repo is not a git repo: both checks read git's file list; say so and stop.

## Step 1: Look at the repo

```bash
cd "$(git rev-parse --show-toplevel)"
ls lefthook.yml .lefthook.yml lefthook.yaml .lefthook.yaml 2>/dev/null
command -v lefthook || mise exec -- lefthook version
ls mise.toml .mise.toml 2>/dev/null
ls .github/workflows/*.yml .github/workflows/*.yaml 2>/dev/null
git config --get core.hooksPath
ls .git/hooks/pre-commit .git/hooks/pre-push 2>/dev/null
ls scripts/check-file-size scripts/check-fan-out scripts/structure-hook 2>/dev/null
ls .file-size-excludes .fan-out-excludes .fan-out-baseline .claude/settings.json 2>/dev/null
```

Note the answers: a lefthook config file (and whether `lefthook` runs bare or only through `mise exec --`), CI files, a set `core.hooksPath`, real hooks in `.git/hooks` (not `*.sample`), and which scripts exist. If a script exists, this run is an update. The repo uses lefthook only when it has one of those config files.

## Step 2: Copy the scripts

```bash
mkdir -p scripts
for f in check-file-size check-fan-out structure-hook; do
  cp "${CLAUDE_SKILL_DIR}/assets/$f" "scripts/$f"
  chmod 755 "scripts/$f"
done
```

The repo carries its own copies because CI and fresh clones cannot see the plugin's install path. The hook calls the two checks from its own folder, so keep all three together. On a rerun this step is the update. Never touch an existing `.file-size-excludes`, `.fan-out-excludes` or `.fan-out-baseline`; they belong to the repo. If a script of that name exists but is another tool's, stop and ask before you overwrite it.

## Step 3: File size offenders

Run `scripts/check-file-size` bare. No output means no offenders. Otherwise show the user the `file-size:` lines and ask, file by file: split it along a deep module, as the message says, or exclude it in `.file-size-excludes` (only for files nobody edits by hand: generated, vendored, ported, data). [references/excludes.md](references/excludes.md) has the file format. A bare run sizes HEAD, so commit each split before you rerun; ask the user before you commit.

## Step 4: Fan-out offenders and the baseline

Run `scripts/check-fan-out --all`. For each `fan-out:` line, ask the user: group the folder now, exclude it (a folder that is a list by design, such as dated logs or one folder per plugin), or accept it in the baseline. Then write the baseline from what is left:

```bash
scripts/check-fan-out --update-baseline
scripts/check-fan-out --all    # expect no output
```

With no `.fan-out-baseline`, `--update-baseline` writes one line per folder over the limit. Once the file exists, it only lowers or drops lines, never raises or adds one: a folder that grows past its line fails until someone groups it, or a person edits the number by hand, which the diff shows. Run it after each grouping to lock in the lower count. [references/excludes.md](references/excludes.md) covers both files.

## Step 5: Wire the hooks and CI

- **lefthook** (step 1 found a config file): pre-commit jobs `scripts/check-file-size {staged_files}` and `scripts/check-fan-out {staged_files}`; pre-push jobs `scripts/check-file-size` and `scripts/check-fan-out --all`. Read [references/lefthook.md](references/lefthook.md) first. Then `lefthook install` (or `mise exec -- lefthook install`).
- **No lefthook:** versioned hooks in `.githooks/` from `assets/pre-commit` and `assets/pre-push`. Read [references/fallback-hooks.md](references/fallback-hooks.md); never overwrite an existing hook or a set `core.hooksPath`.
- **CI:** run `scripts/check-file-size` and `scripts/check-fan-out --all` after checkout, as [references/ci.md](references/ci.md) shows.

Do not wire pre-push or CI while a bare run still fails, unless the user says so.

## Step 6: The Claude Code editor hook

Add the `PostToolUse` block from [references/editor-hook.md](references/editor-hook.md) to the repo's `.claude/settings.json`, merged into what is there. It is a project hook, so it fires only in this repo. Then test it as the reference says.

## Step 7: Check it works

Make sure nothing is staged (`git diff --cached --name-only` prints nothing; otherwise ask the user). Then:

```bash
truncate -s 20004 x.txt && git add x.txt && git commit -m "test: size check"
```

Expect the commit to fail with `file-size: x.txt is ~5001 tokens (bytes/4); the limit is 5000.`, then clean up with `git rm --cached -q x.txt && rm x.txt`. If it went through, undo it with `git reset --soft HEAD~1` only when HEAD is that test commit, clean up, and see Self-Healing. Last, both bare runs (`scripts/check-file-size`, `scripts/check-fan-out --all`) print nothing.

Leave the new and changed files for the user to review and commit, unless they asked you to commit. Tell them how to skip once: `LEFTHOOK_EXCLUDE=file-size,fan-out git commit ...` with lefthook, `--no-verify` with plain hooks. CI still runs the checks.

## Self-Healing

- **No commit yet.** `check-file-size` sizes the index, not HEAD, until the first commit exists. That is expected.
- **`fatal: not a git repository`.** `cd` into the repo; the scripts work from any subdirectory.
- **`mktemp` fails.** Set `TMPDIR` to a writable folder.
- **Hooks do not fire.** With lefthook, run `lefthook install` and check `.git/hooks/pre-commit` is lefthook's. Without it, check `git config --get core.hooksPath` and that the hooks are executable.
- **`Permission denied` on a script.** `chmod 755 scripts/<name>` and `git update-index --chmod=+x scripts/<name>`.
- **The editor hook says nothing.** See the checks in [references/editor-hook.md](references/editor-hook.md).
