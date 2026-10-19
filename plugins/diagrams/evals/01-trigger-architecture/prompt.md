---
tags: [core]
max_turns: 6
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

Our app is small: a React web app talks to a Python API. The API writes jobs to an SQS queue, and a worker picks them up, stores results in Postgres and uploads generated files to S3. Can you make me an architecture diagram of this as a standalone HTML file I can open in the browser and send to the team?
