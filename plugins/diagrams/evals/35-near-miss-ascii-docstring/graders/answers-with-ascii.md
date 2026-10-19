---
type: llm
---

The user asks for a small ASCII box diagram of a request going from client to load balancer to two app servers to a database, to put in a Python docstring. The user wants plain text, not a rendered page.

PASS if the reply contains a plain-text ASCII diagram of that flow, or asks one short clarifying question. FAIL if the reply gives HTML or SVG instead of plain text, starts an HTML diagram artifact, or otherwise ignores the request.
