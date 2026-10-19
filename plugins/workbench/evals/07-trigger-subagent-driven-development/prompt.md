---
tags: [core]
max_turns: 6
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

Execute this plan task by task. Give each task to a fresh subagent and review its work before you start the next one.

1. Add a `last_login_at` column to the users table with a migration.
2. Set `last_login_at` to the current time in the login handler after a successful sign-in.
3. Show "Last login" with that date on the profile page.
