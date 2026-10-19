---
tags: [core]
max_turns: 6
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

Draw a small ASCII box diagram for a docstring showing how a request flows: client -> load balancer -> two app servers -> database. Plain text only, so it fits in a Python docstring.
