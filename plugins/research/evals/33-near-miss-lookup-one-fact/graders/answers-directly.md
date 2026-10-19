---
type: llm
---

The user asks for one fact: the year the IEEE 754 floating point standard was first ratified, checked against one source, with that source's link. This is a quick lookup, not an investigation, so the agent should answer from knowledge or with a few searches or one fetch at most.
PASS if the response gives a year (1985 is correct) and one source link, whether it answered from knowledge or looked it up briefly. A short note on later revisions (2008, 2019) alongside the answer also PASSES. FAIL if the response plans a multi-step investigation, writes or offers a long report, spawns subagents, asks clarifying questions about scope or audience instead of answering, or gives no year or no link.
