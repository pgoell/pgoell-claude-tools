# 2026-11-02: Fix

issue-loop 0.13.8. `gate.sh` also checks each PR the HELD line names, so a task that only fixed an older held PR no longer fails with "no PR of it is open". `references/gate.md` says so; `tests/run.sh` checks it. No page under `docs/` changed.
