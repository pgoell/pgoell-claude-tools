---
tags: [core]
max_turns: 40
timeout_seconds: 1200
allowed_tools: [Skill, Read, Agent]
runs: 1
---

Critique this.

Our production Postgres runs in eu-west-1. Today we take a nightly pg_dump to S3, keep 30 days of dumps, and pay about $400 a month for storage and the dump job. A full restore takes about 4 hours. Last year we restored from these backups twice: once after a migration dropped a column in production, and once after a bug in a bulk-update script overwrote customer addresses.

The plan: set up a streaming replica in eu-central-1 with replication lag under one second, stop the nightly dumps, and delete the S3 backup bucket to cut the cost. If the primary fails, we promote the replica in about 5 minutes instead of waiting 4 hours for a restore. The replica costs about $250 a month, so we save $150 a month and recover much faster. The change takes about two days of work and would go live next week.
