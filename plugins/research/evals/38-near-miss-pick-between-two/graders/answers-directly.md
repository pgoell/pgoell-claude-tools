---
type: llm
---

The user asks to compare PostgreSQL and SQLite for a small single-user desktop app that stores a few thousand notes locally, and to pick one in one paragraph from knowledge, with no sources. This is a quick judgment, not a market comparison.
PASS if the response picks one in about one paragraph with a short reason, from knowledge (SQLite is the expected pick, since it is embedded, needs no server and fits one local user). Picking PostgreSQL with a sound reason also PASSES. FAIL if the response plans a multi-step investigation, searches for or cites sources, writes or offers a long report or comparison table, spawns subagents, asks clarifying questions about scope or audience instead of answering, or picks neither.
