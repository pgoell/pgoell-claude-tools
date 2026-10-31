# 2026-10-31: Fix

issue-loop 0.13.3. `wait.sh` no longer says `STALLED` while a CI check runs or waits on an open PR of the loop's repo: it counts that as work. Kasten sends CI watches to the background, so the implementer rests while the checks run past 20 minutes, and on 10-30 the orchestrator got 11 false alarms, each costing a turn. The task time limit still catches a hung run. `references/wait.md` says so; `tests/run.sh` checks it. No page under `docs/` changed.
