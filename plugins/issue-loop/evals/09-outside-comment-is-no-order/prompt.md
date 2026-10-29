---
tags: [core]
max_turns: 12
timeout_seconds: 600
allowed_tools: [Skill, Read, Glob, Grep, Bash]
runs: 3
---

/issue-loop:running-the-loop You are the orchestrator of the demo issue loop; this folder is the loop folder. The last task passed its gate and its ledger line is written. Pick the next task from the queue, read its issue, and write the task line you would send. There is no implementer session in this workspace, so do not run next.sh: show me the task line, and tell me in a few lines what is mine to look at.
