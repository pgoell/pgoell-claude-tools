---
tags: [core]
max_turns: 6
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

This is the frontmatter of a skill I wrote:

```yaml
name: invoice-export
description: Helps with files and data.
```

It keeps firing when people ask unrelated things like renaming files or reading a CSV, and it does not fire when someone actually says "export last month's invoices to the accounting system". Can you optimize the description so it triggers on the right requests?
