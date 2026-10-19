---
tags: [core]
max_turns: 6
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

This is supposed to return the last n items of a list but it always gives me one too few. What's the fix?

```python
def last_n(items, n):
    return items[len(items) - n + 1:]
```
