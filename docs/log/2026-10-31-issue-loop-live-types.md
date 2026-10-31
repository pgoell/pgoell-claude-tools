# 2026-10-31: Fix

issue-loop 0.13.2. `gate.sh` fails "live is X, base is Y" only when a commit after the live one starts with a type in the new `LIVE_TYPES` setting of `loop.env`, such as `'feat|fix|perf'`; else it prints a note and passes. Empty, every commit must reach live, as before. In kasten 14 of 18 gate runs on one day failed on lint, test and comment commits the release script never deploys, so the orchestrators read past every such failure, and a real missed deploy looked the same. `tests/run.sh` checks it. No page under `docs/` changed.
