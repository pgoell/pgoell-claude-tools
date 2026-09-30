---
max_turns: 20
timeout_seconds: 600
allowed_tools: [Skill, Read, Glob, Grep, Write, Edit, Bash, Agent]
runs: 3
---

Here's the PR description I wrote. Rewrite it into something I can paste into GitHub. The change: CSV export used to skip rows whose created_at was null; now it writes an empty cell instead. I also renamed two helper functions in export.py, no behavior change.

Title: Fix stuff in export

This PR makes some changes to the export logic. There were some issues that came up and this should address them. Also cleaned up some code while I was in there. Tested locally.
