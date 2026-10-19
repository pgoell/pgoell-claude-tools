# 2026-10-19: Fix

workbench 1.4.5, issue #230. The Codex and Cursor tool maps of `using-workbench` no longer name prompt files that workbench does not ship (a code reviewer agent file and a code quality reviewer prompt). `mise run check-docs` now fails when a backticked `*-prompt.md` or `agents/*.md` name in `README.md`, `AGENTS.md`, `plugins/` or `docs/` has no tracked file with that basename. No pages under `docs/` changed.
