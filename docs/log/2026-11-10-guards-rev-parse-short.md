# 2026-11-10: Update

guards 0.2.0. New `PreToolUse` hook `rev-parse-short-multi` denies `git rev-parse --short` with two or more revisions, which always exits 128 ("Needed a single revision") and cuts an `&&` chain short. Pages changed: `reference/plugins/guards.md`, `reference/plugins/index.md`, `explanation/plugins-without-skills.md`.
