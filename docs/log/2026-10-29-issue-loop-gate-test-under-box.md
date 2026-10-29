# 2026-10-29: Fix

issue-loop 0.11.1. `gate.sh` now counts a ticked box's test when `Test:` or `Proof:` sits on an indented line under the box, not only on the box line. Implementers wrote the test there, and the gate failed every such PR with "ticked boxes name no test". Rule 5 in `assets/rules.md` and `references/gate.md` say so; `tests/run.sh` checks it. No page under `docs/` changed.
