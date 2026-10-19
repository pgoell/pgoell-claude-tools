---
tags: [core]
max_turns: 6
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

This spec is approved. Turn it into a step-by-step implementation plan.

Spec: password reset by email. A user enters their email on /reset. If the account exists, we send a link with a single-use token that expires after 30 minutes. The link opens a form for a new password (at least 12 characters). On submit we store the new hash, mark the token used, and sign out every other session of that user.
