---
tags: [core]
max_turns: 6
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

Our spec for password reset is approved: a user enters their email, we send a single-use link that expires after 30 minutes, the link opens a form for the new password (at least 12 characters), and all of the user's sessions end once the password changes. Turn it into a step-by-step implementation plan. Don't write any code yet; I will decide who builds it once I have the plan.
