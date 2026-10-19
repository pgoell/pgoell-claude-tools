---
tags: [core]
max_turns: 6
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

I need to explain our order lifecycle to the support team. An order starts as Created. Payment moves it to Paid, or it times out to Cancelled. A Paid order goes to Shipped, then Delivered. From Delivered the customer can ask for a return, which moves it to Returned and then Refunded. Support can cancel a Paid order before it ships, which also ends in Refunded. Please draw this as a state diagram in an HTML file I can share with them.
