# 2026-11-02: Fix

issue-loop 0.13.7. `gate.sh` no longer fails an open issue when a PR made since the task began says `Part of #N` in its body, since an umbrella issue stays open on purpose. On 2026-11-01 this line made 15 of 44 gate runs fail, all on one kasten issue. `references/gate.md` says so; `tests/run.sh` checks it. No page under `docs/` changed.
