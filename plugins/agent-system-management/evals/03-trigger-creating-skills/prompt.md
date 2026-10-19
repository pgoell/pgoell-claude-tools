---
tags: [core]
max_turns: 6
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

Every Friday I do the same release routine by hand: read the merged PRs since the last tag, group them into features, fixes and chores, write a CHANGELOG entry, bump the version in package.json, tag the release, and post a short summary in our team channel. I keep explaining the steps to Claude from scratch each week.

Can you help me turn this into a new skill so I can just ask for it?
