---
tags: [core]
max_turns: 6
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

We settled the design for invoice reminder emails: a first reminder 3 days after the due date, a second after 10 days, then the account manager gets a task instead of a third email; customers can turn reminders off per invoice. Write this up as a spec I can open in the browser and share with the team.
