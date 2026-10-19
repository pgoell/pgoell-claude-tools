---
tags: [core]
max_turns: 6
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

I keep repeating this procedure when a customer reports a failed payment:

1. Look up the order id in the admin panel and copy the payment intent id.
2. Check the payment provider's dashboard for the intent's last error code.
3. Match the code against our refund policy table.
4. Draft a reply to the customer with the next step.
5. Log the case in the support spreadsheet.

I don't want this as a rule in CLAUDE.md, it's too long and only matters now and then. Make it a reusable skill I can call when a case comes in.
