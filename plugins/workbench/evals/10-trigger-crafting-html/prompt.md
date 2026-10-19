---
tags: [core]
max_turns: 6
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

Make me a standalone HTML incident report for yesterday's checkout outage. Facts: checkout was down for 40 minutes, from 14:05 to 14:45 UTC; the cause was an expired TLS certificate on the payments proxy; about 1,200 orders failed; we fixed it by renewing the certificate by hand, and we now have an alert 14 days before any certificate expires.
