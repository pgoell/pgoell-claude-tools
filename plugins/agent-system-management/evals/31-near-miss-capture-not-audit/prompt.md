---
tags: [core]
max_turns: 6
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

Improve our CLAUDE.md with what we learned today: the image upload tests need `MINIO_ENDPOINT=http://localhost:9000` set or they hang for two minutes and then time out, and `pnpm install` must run from the repo root, never inside `apps/web`, because the workspace lockfile lives at the root. Don't review the rest of the file, just get today's lessons in.
