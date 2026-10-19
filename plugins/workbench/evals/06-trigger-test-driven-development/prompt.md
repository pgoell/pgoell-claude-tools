---
tags: [core]
max_turns: 6
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

Add a function slugify(title) to text_utils.py. It should lowercase the title, strip accents (so "Crème Brûlée" becomes "creme brulee"), and join the words with hyphens, giving "creme-brulee".
