---
tags: [core]
max_turns: 6
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

We agreed on this design for rate limiting our public API: a token bucket per API key, 100 requests per minute with a burst of 20, buckets stored in Redis, and over-limit requests answered with 429 and a Retry-After header. Write it up as a spec document. Just the spec for now; the team decides next sprint whether we build it at all.
