# File Size

Caps every authored file in a repo at 5000 tokens, counted as bytes/4. Big files cost agents: they read them in pieces and lose track. A failing run says how to split the file along a deep module (John Ousterhout, "A Philosophy of Software Design"), not by line count.

## Skills

- `/file-size:setting-up-the-check`: Sets up the check in a repo. Copies the script to `scripts/check-file-size` (CI and fresh clones cannot see a plugin install path) and wires it in three places: lefthook pre-commit on staged files, pre-push and GitHub Actions on every tracked file at HEAD. A repo without lefthook or mise gets versioned git hooks in `.githooks/` instead, turned on per clone with `git config core.hooksPath .githooks`.

## The script

`skills/setting-up-the-check/assets/check-file-size` checks the paths it gets as arguments, as staged, or with no arguments every file in HEAD's tree. It skips symlinks and submodules, and exits 1 with one line per file over the limit, then the advice once.

It skips these files by default:

- lockfiles: `mise.lock`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `bun.lockb`, `uv.lock`, `poetry.lock`, `Pipfile.lock`, `Cargo.lock`, `Gemfile.lock`, `composer.lock`, `go.sum`, `flake.lock`, in any folder
- binaries: `png`, `jpg`, `jpeg`, `gif`, `webp`, `ico`, `woff`, `woff2`, `ttf`, `otf`, `pdf`
- license texts: `LICENSE*` and `NOTICE`

A repo adds its own globs in `.file-size-excludes` at its root, one per line, in git glob syntax anchored at the root (`plugins/deprecated/**`, `**/generated-*.mjs`). A line that starts with `#` is a comment; blank lines are skipped. Without the file the script uses the defaults alone. It reads the file from the working tree and finds it from any subdirectory.

The fallback hooks ship beside the script as `assets/pre-commit` and `assets/pre-push`.

## Test

`tests/run.sh` builds throwaway git repos and runs the script and the fallback pre-commit hook against them. No network. Run it from the repo root:

```sh
bash plugins/file-size/tests/run.sh
```

Last run, 2026-10-19: 34 passed, 0 failed.

## License

MIT, see `LICENSE`.
