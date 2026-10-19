---
type: llm
---

The user asks for the current latest stable release of Node.js and its release date, checked against one source, with that source's link. This is a quick lookup, not an investigation, so the agent should check it with a few searches or one fetch at most.
PASS if the response gives a Node.js version number, a release date and one source link (for example nodejs.org), found with a few searches or one fetch. Naming both the latest Current and the latest LTS release, each with a date, also PASSES. Do not judge whether the version is truly the newest, since that changes over time. FAIL if the response plans a multi-step investigation, writes or offers a long report, spawns subagents, asks clarifying questions about scope or audience instead of answering, or gives no version, no date or no link.
