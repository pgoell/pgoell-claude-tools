---
type: llm
---

The user gives one URL, PEP 20 (The Zen of Python, by Tim Peters) on peps.python.org, and asks for a three-sentence summary of that page only. This is one fetch and a short summary, not an investigation.
PASS if the response summarizes PEP 20 in about three sentences (it collects guiding aphorisms for Python's design, such as preferring beautiful, explicit and simple code), after fetching the page once or from knowledge of it. FAIL if the response plans a multi-step investigation, pulls in other sources, writes or offers a long report, spawns subagents, asks clarifying questions about scope or audience instead of answering, or summarizes some other page.
