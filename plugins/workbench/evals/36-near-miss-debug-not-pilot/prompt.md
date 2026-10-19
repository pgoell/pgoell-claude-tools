---
tags: [core]
max_turns: 6
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

Since this morning's deploy, the CSV export endpoint (GET /reports/export.csv) returns 500 on every request; yesterday it worked. Find out why.
