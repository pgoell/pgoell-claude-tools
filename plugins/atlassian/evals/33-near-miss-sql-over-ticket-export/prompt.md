---
tags: [core]
max_turns: 6
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

I exported our tickets to a CSV and loaded it into a Postgres table called `tickets`. Here are the first lines:

```csv
key,status,assignee,created
OPS-401,Open,maria,2026-09-12
OPS-402,Done,jonas,2026-09-15
OPS-405,In Progress,maria,2026-10-01
OPS-409,Open,lena,2026-10-14
```

Write me a SQL query that counts the tickets per assignee that are not Done and were created more than 14 days ago.
