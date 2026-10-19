---
tags: [core]
max_turns: 6
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

Draft a short design doc in markdown, right here in the chat, for adding rate limiting to our public API: a token bucket per API key, 100 requests a minute, a 429 reply with a Retry-After header. Sections for context, proposal, alternatives and open questions. I'll paste it into the team wiki myself.
