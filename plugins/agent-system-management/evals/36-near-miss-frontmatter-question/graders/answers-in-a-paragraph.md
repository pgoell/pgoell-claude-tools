---
type: llm
---

The user asks in one line what the `description` field in a SKILL.md frontmatter does and wants one paragraph. This is a factual question, not a request to build or tune a skill.

PASS if the response is a short, direct explanation (about one paragraph) that says the description is what the model reads to decide when to load or use the skill. FAIL if the response starts a skill-building or description-tuning workflow, asks the user for a skill to work on, or turns into a long lesson well past one paragraph.
