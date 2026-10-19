---
tags: [core]
max_turns: 6
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

In Jira, find every ticket in the PAY project that is still In Review and has not been updated for two weeks, move each one back to To Do, and add a comment saying it went stale in review.
