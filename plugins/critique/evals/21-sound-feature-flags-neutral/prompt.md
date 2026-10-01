---
tags: [core]
max_turns: 40
timeout_seconds: 1200
allowed_tools: [Skill, Read, Agent]
runs: 1
---

Critique this.

Our web app is a monolith worked on by 12 engineers in two teams; we deploy twice a week. Three production incidents last quarter came from releases that could only be undone by a full rollback deploy (about 40 minutes each).

The plan: adopt OpenFeature with a self-hosted flagd server so that new risky features ship behind a flag and can be switched off in seconds. Scope is limited: flags only for new risky features, not for configuration. Every flag gets an owner and a removal date at most 30 days out, and a CI check fails the build when a flag outlives its removal date. We pilot with one team for 6 weeks and measure the number of rollback deploys and time to mitigate incidents; if the pilot shows no improvement or flag cleanup slips, we stop and remove the library.
