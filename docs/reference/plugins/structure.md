---
type: Reference
title: The structure plugin
description: Skills that cap file size and folder fan-out in a repo, on commit, push, CI and edit, and set up import boundaries between modules.
tags: [plugin, structure, file-size, fan-out, imports, lint, ci]
status: stable
---

# structure

Keeps a repo easy for agents to read. No authored file may pass 5000 tokens (bytes/4), and no folder may hold more than 7 entries. A Claude Code hook runs both checks on each file the agent edits, and import rules keep modules behind their interfaces. Each failure says how to fix it along a deep module (a small interface over much hidden work), never by line count or into a `utils/` bucket.

This plugin was called `file-size` up to 0.1.0. An install of `file-size@pgoell-claude-tools` must change to `structure@pgoell-claude-tools`, for example in `enabledPlugins` in `~/.claude/settings.json`.

**Runtimes:** Claude Code, Codex, Cursor. The editor hook is for Claude Code.

**Source:** `plugins/structure/`.

**Setup:** None beyond install. The skills wire the checks into the target repo.

## Skills

| Invocation                                | What it does                                                                                                                                                                                                                                                  |
| ----------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/structure:setting-up-the-checks`        | Copy `check-file-size`, `check-fan-out` and `structure-hook` to `scripts/`, list today's offenders, write `.fan-out-baseline`, and wire both checks: lefthook pre-commit on staged files, pre-push and GitHub Actions on the whole repo, and the editor hook. |
| `/structure:setting-up-import-boundaries` | Survey the repo's modules, write import-linter contracts (Python) or dependency-cruiser rules (TypeScript) with the user, and wire them into `mise run lint` and CI. The rules belong to the repo; there is no shared config.                                 |

## The scripts

All in `plugins/structure/skills/setting-up-the-checks/assets/`. The skill copies them into the target repo, since CI and fresh clones cannot see the plugin's install path. Run it again to copy newer scripts; it leaves the repo's excludes and baseline alone.

- `check-file-size [path...]`: with paths, sizes the staged copy of each; bare, every file tracked at HEAD. It skips lockfiles, images, fonts, PDFs and license texts (`LICENSE*`, `NOTICE`); a repo adds globs in `.file-size-excludes`.
- `check-fan-out <path>...`: checks every folder above each path. `--all` checks every folder. `--update-baseline` lowers or drops lines in `.fan-out-baseline` and never raises or adds one; with no file, it writes one from today's overages. Entries come from git: tracked and untracked files, never ignored ones. The repo root and names that start with `.` do not count.
- `structure-hook`: a Claude Code `PostToolUse` hook for `Edit|Write|MultiEdit`. It reads `tool_input.file_path` from the hook JSON, runs both checks on that file (its size on disk), and exits 2 with their message, which Claude Code shows to Claude. It needs `jq`.

## Files in the target repo

- `.file-size-excludes`: one git glob per line, anchored at the repo root.
- `.fan-out-excludes`: folders the fan-out check skips, one git glob per line, with a comment line above each that says why.
- `.fan-out-baseline`: `<folder> <count>` per line. A folder fails when it passes both 7 and its line. A person raises a line by hand, and the diff shows it.
- `.claude/settings.json`: the `PostToolUse` block that runs `scripts/structure-hook`, a project hook so it fires only in that repo.

## Without lefthook or mise

A repo with neither gets versioned hooks from the templates `assets/pre-commit` and `assets/pre-push`. Each clone turns them on once with `git config core.hooksPath .githooks`.

## Tests

`bash plugins/structure/tests/run.sh` checks the scripts, the fallback pre-commit hook and the editor hook (with fake JSON) against throwaway git repos, with no network.

## In this repo

This repo runs the plugin's own copies, so each check has one source. `mise-tasks/check-file-size` and `mise-tasks/check-fan-out` call the scripts; lefthook pre-commit runs both on staged files, and `mise run lint` (pre-push and the CI lint job) runs both on the whole repo. `.claude/settings.json` runs the plugin's `structure-hook` on each edit. The excludes are in `.file-size-excludes` and `.fan-out-excludes`, the accepted fan-out overages in `.fan-out-baseline`, all at the root.

The `pgoell/project-template` Copier template carries byte-identical copies of `check-fan-out` and `structure-hook`; the plugin's copies are canonical.
