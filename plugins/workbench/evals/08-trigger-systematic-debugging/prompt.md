---
tags: [core]
max_turns: 6
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

test_invoice_totals fails about one CI run in five with `AssertionError: 99.99 != 100.0`, but it always passes on my machine. What is wrong?
