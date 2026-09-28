---
max_turns: 15
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep, Write]
runs: 3
---

Make a one-page HTML status report of this sprint and save it as `report.html`.

Sprint 42, 15 to 26 September:

- Committed 34 story points, delivered 29.
- Shipped: saved payment methods, faster search autocomplete (p95 from 480 ms to 190 ms).
- Slipped: invoice PDF export (blocked on the tax API contract, now expected 10 October).
- Incidents: 1 (checkout degraded 22 minutes on 18 September, root cause a cache eviction bug, fixed).
- Next sprint focus: invoice PDF export, accessibility fixes on checkout.
