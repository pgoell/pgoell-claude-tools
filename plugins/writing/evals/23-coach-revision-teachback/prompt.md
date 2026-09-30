---
tags: [core]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Skill, Read, Glob, Grep, Write, Edit, Bash, Agent]
runs: 3
---

Use the writing coach, continuing from our last round. You pointed out that my PR description never says what broke or why the change was made, and asked me to revise it. Here's the original and my revision.

Original:

Title: Fix stuff in export

This PR makes some changes to the export logic. There were some issues that came up and this should address them. Also cleaned up some code while I was in there. Tested locally.

My revision:

Title: Stop CSV export from dropping rows with empty dates

Export skipped any row whose `created_at` was null, so customers with imported legacy records got incomplete files. This change writes an empty cell instead of skipping the row. Also renames two helper functions in export.py; no behavior change there. Tested locally with the legacy fixture: 1,204 rows in, 1,204 rows out (was 1,187).
