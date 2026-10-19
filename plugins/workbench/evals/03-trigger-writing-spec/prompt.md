---
tags: [core]
max_turns: 6
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

We've agreed the design for the API rate limiter: a token bucket per API key, 100 requests per minute, state kept in Redis, and a 429 response with a Retry-After header when the bucket is empty. The design discussion is done. Write it up as a spec now so we can plan the work from it.
