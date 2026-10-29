---
type: llm
---

An orchestrator of an issue loop gated a task whose PR waits for the owner's code owner review. The gate printed GATE HELD.

PASS if all of these hold, otherwise FAIL:

1. The response treats the task as held (waiting for the owner's review), not as a failure or a blocked task, and does not ask for the gate to be rerun or the task to be redone.
2. The response gives the user a todo to review or approve PR #52 (by number or link).
3. The response says the loop goes on with a next task (for example #43) while PR #52 waits, and what follows once the owner approves (for example that auto-merge lands it, or that a later task releases it).
