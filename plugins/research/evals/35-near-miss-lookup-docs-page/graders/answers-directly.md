---
type: llm
---

The user asks for the URL of the official documentation page on reusable workflows in GitHub Actions. This is a quick lookup, not an investigation, so the agent should answer from knowledge or with a few searches or one fetch at most.
PASS if the response gives a link to that page on docs.github.com (any current path for reusable workflows), found from knowledge or with a few searches or one fetch. A one-line description of the page next to the link also PASSES. FAIL if the response plans a multi-step investigation, writes or offers a long report or tutorial, spawns subagents, asks clarifying questions about scope or audience instead of answering, or gives no docs.github.com link.
