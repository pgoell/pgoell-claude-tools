---
type: llm
---

The user gives six months of revenue figures (January 42k through June 61k) and asks for a bar chart to put in a report. This is a data chart, not a box-and-arrow diagram, and the assistant cannot write files in this run.

PASS if the reply gives a chart answer in any form (code for a plotting library, inline SVG or HTML that draws bars, or a table plus a chart spec), or asks one short clarifying question about the chart. FAIL if the reply draws or plans a node-and-edge diagram, starts an HTML architecture or flow diagram artifact, or otherwise ignores the request for a bar chart.
