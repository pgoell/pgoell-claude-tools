---
tags: [core]
max_turns: 6
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

Make a standalone HTML status report on this week's database migration. Facts: 14 of 20 tables moved from MySQL 5.7 to Postgres 16, two hours of read-only downtime on Tuesday, the orders table is blocked on a foreign key problem, and the finish date moved to 30 October. The default look is fine.
