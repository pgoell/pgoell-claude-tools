---
tags: [core]
max_turns: 6
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

I want to understand why TCP opens a connection with a three-way handshake and not two messages or four. Don't just explain it. Let me try to design a connection setup myself first, then poke holes in my version until I see why it ended up the way it did.
