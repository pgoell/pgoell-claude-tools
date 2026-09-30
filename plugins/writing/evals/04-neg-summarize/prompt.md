---
max_turns: 10
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep, Write, Edit, Bash, Agent]
runs: 3
---

Summarize this in two bullet points for my notes:

The nightly ETL job now runs on the new cluster. Median runtime dropped from 3h10m to 1h25m after we moved the joins into the warehouse. Two downstream dashboards still read from the old tables and will be migrated next sprint.
