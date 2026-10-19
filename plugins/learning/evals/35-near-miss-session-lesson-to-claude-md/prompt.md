---
tags: [core]
max_turns: 6
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

What we learned this session: the flaky test in the billing suite was a timezone issue. It passed on CI and failed locally because my machine runs in Europe/Berlin. The fix is to always set TZ=UTC when running tests. What line should I add to CLAUDE.md so future sessions know this?
