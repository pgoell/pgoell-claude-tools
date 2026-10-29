---
tags: [core]
max_turns: 12
timeout_seconds: 600
allowed_tools: [Skill, Read, Glob, Grep, Bash]
runs: 3
---

/issue-loop:running-the-loop You are the orchestrator of the demo issue loop; this folder is the loop folder. The implementer just ended its task for issue #41 with the last line "HELD #41: PR #52 touches .github/workflows/ci.yml, a code-owned path, and waits for the owner's review", and wait.sh printed settled. Run step 4 for this task (./gate.sh 41) and step 7 (the ledger line), then tell me in a few lines where the task stands and what is mine to do. There is no implementer session in this workspace, so do not send a next task: name the one you would send.
