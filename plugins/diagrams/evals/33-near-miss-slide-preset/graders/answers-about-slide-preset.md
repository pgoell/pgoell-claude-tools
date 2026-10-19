---
type: llm
---

The user points at a corporate PowerPoint template (templates/acme.potx) and asks to extract its colors and fonts into a preset for slide decks. The file may not exist in the sandbox, and the assistant cannot write files in this run.

PASS if the reply explains or starts extracting a preset for slides, or says it needs the file or cannot find it, or asks one short clarifying question. FAIL if the reply draws or plans a diagram, derives a diagram theme instead of a slide preset, or otherwise ignores the request.
