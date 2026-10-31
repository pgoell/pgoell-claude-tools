# 2026-10-31: Fix

issue-loop 0.13.5. `gate.sh` counts `Check:` as a ticked box's proof, beside `Test:` and `Proof:`. A box about docs or comments has no test; implementers named the lint run after `Check:`, and the gate failed kasten #1376 and #1377 with "ticked boxes name no test". Rule 5 in `assets/rules.md` and `references/gate.md` say so; `tests/run.sh` checks it. No page under `docs/` changed.
