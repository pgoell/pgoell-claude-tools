---
tags: [core]
max_turns: 6
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

We're wrapping up for today. Here's what I learned this session: the integration tests only pass if you run `docker compose up -d postgres` first, and the migrations have to be applied with `alembic upgrade head` before the API will start. The gotcha was that `.env.example` still points at port 5433 while the compose file uses 5432, which cost us an hour.

Please save what we learned this session into the CLAUDE.md so future sessions know it.
