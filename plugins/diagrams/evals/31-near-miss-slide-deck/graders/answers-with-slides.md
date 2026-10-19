---
type: llm
---

The user pastes short notes for a quarterly update (revenue, churn, shipped features, hiring, Q4 focus) and asks to turn them into a 5-slide deck for an all-hands. The assistant cannot write files in this run, so an inline answer is expected.

PASS if the reply gives slide content in text (slide titles with bullets, or an outline of about five slides), or asks one short clarifying question about the deck. FAIL if the reply draws or plans a box-and-arrow architecture or flow diagram, starts an HTML diagram artifact, or otherwise ignores the request for slides.
