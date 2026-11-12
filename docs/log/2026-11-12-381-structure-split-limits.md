# 2026-11-12: Fix

structure 0.2.17, issue #381. The failure messages of `check-file-size` and `check-fan-out` now limit the restructure they ask for: move only what it takes, change nothing but paths and imports, and say in the final message what moved. The file-size message names `.file-size-excludes` at the repo root and stops after one failed second try, so a person picks another split or an exclude. Step 2 of `setting-up-the-checks` no longer says "never touch" the excludes and baseline that steps 3 and 4 edit. Pages changed: `reference/plugins/structure.md`.
