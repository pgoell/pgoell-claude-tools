# Structure

Keeps a repo easy for agents to read. Two checks, an editor hook and import rules:

- no authored file passes 5000 tokens, counted as bytes/4;
- no folder holds more than 7 entries, with a baseline for today's overages;
- a Claude Code hook runs both checks on each edited file, so the agent learns at edit time;
- per-repo import rules keep modules behind their interfaces.

Each failure says how to fix it along a deep module (John Ousterhout, "A Philosophy of Software Design"): a small interface over much hidden work. Never by line count, never into a `utils/` bucket.

This plugin was called `file-size` up to 0.1.0.

## Skills

- `/structure:setting-up-the-checks`: Sets up both checks in a repo. Copies `check-file-size`, `check-fan-out` and `structure-hook` to `scripts/` (CI and fresh clones cannot see a plugin install path), lists today's offenders, writes `.fan-out-baseline`, and wires the checks into lefthook pre-commit on staged files, pre-push and GitHub Actions on the whole repo, and the Claude Code `PostToolUse` hook in `.claude/settings.json`. A repo without lefthook gets versioned git hooks in `.githooks/` instead.
- `/structure:setting-up-import-boundaries`: Surveys a repo's modules and writes import-linter contracts (Python) or dependency-cruiser rules (TypeScript) with the user, then wires them into `mise run lint` and CI.

## The scripts

All in `skills/setting-up-the-checks/assets/`.

`check-file-size` checks the paths it gets as arguments, as staged, or with no arguments every file in HEAD's tree. It skips symlinks, submodules, lockfiles, binaries, fonts, PDFs and license texts; a repo adds globs in `.file-size-excludes`.

`check-fan-out` counts the files and folders in each folder, from git's list of tracked and untracked files (never ignored ones). It skips the repo root and names that start with `.`.

- `check-fan-out <path>...` checks every folder above each path.
- `check-fan-out --all` checks every folder.
- `check-fan-out --update-baseline` lowers or drops lines in `.fan-out-baseline`, never raises or adds one. With no file, it writes one from today's overages.

A folder fails when it holds more than 7 entries and more than its line in `.fan-out-baseline`. `.fan-out-excludes` lists folders it skips, one git glob per line with a comment above it that says why.

`structure-hook` reads Claude Code's hook JSON on stdin, runs both checks on `tool_input.file_path` (the size on disk, through a throwaway index), and exits 2 with their message on a failure. It needs `jq`.

The fallback git hooks ship beside them as `pre-commit` and `pre-push`.

`check-fan-out` and `structure-hook` start with a comment that names this folder as the canonical copy. Copies in other repos (the `pgoell/project-template` Copier template) stay byte-identical.

## Test

`tests/run.sh` builds throwaway git repos and runs the scripts, the fallback pre-commit hook and the editor hook (with fake JSON) against them. No network. Run it from the repo root:

```sh
bash plugins/structure/tests/run.sh
```

Last run, 2026-10-20: 56 passed, 0 failed.

## License

MIT, see `LICENSE`.
