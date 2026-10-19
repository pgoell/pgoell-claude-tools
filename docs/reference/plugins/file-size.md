---
type: Reference
title: The file-size plugin
description: The skill that sets up a 5000-token cap on authored files in a repo, on commit, on push and in CI.
tags: [plugin, file-size, lint, ci]
status: stable
---

# file-size

One skill that sets up a size check in any repo: no authored file may pass 5000 tokens, counted as bytes/4. Big files cost agents, who read them in pieces and lose track. When a file passes the limit, the check prints which file and how to split it along a deep module, never by line count.

**Runtimes:** Claude Code, Codex, Cursor

**Source:** `plugins/file-size/`.

**Setup:** None beyond install. The skill wires the check into the target repo.

## Skills

| Invocation                        | What it does                                                                                                                                                                                                                                                                       |
| --------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/file-size:setting-up-the-check` | List the files that already pass the limit, copy the script to `scripts/check-file-size`, and wire it: lefthook pre-commit on staged files, pre-push on every tracked file, and a GitHub Actions step after checkout. It merges into existing hooks and CI, never overwrites them. |

## The script

The script lives at `plugins/file-size/skills/setting-up-the-check/assets/check-file-size`. With paths as arguments it sizes the staged copy of each; run bare, it sizes every file tracked at HEAD. The skill copies it into the target repo, since CI and fresh clones cannot see the plugin's install path. Run the skill again to copy a newer script; it leaves `.file-size-excludes` alone.

## Excludes

The script skips files no person or agent writes by hand:

- lockfiles (`mise.lock`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `bun.lockb`, `uv.lock`, `poetry.lock`, `Pipfile.lock`, `Cargo.lock`, `Gemfile.lock`, `composer.lock`, `go.sum`, `flake.lock`);
- images, fonts and PDFs;
- license texts (`LICENSE*`, `NOTICE`).

A repo adds its own in `.file-size-excludes` at its root: one git glob per line, anchored at the repo root, also when the script runs from a subfolder. A line that starts with `#` is a comment, and blank lines are skipped. Without the file, only the defaults apply.

```
# generated
**/generated-*.mjs
# frozen archive
plugins/deprecated/**
```

## Without lefthook or mise

A repo with neither gets versioned hooks from the templates `assets/pre-commit` and `assets/pre-push`: `.githooks/pre-commit` checks the staged files and `.githooks/pre-push` runs the script bare. Each clone turns them on once with `git config core.hooksPath .githooks`.

## Tests

`bash plugins/file-size/tests/run.sh` checks the script against throwaway git repos, with no network.

## In this repo

This repo runs the plugin's own copy, so the check has one source: `mise-tasks/check-file-size` calls the script, and lefthook and the CI lint job call that task. This repo's excludes (generated, ported and frozen files) are in `.file-size-excludes` at the root.
