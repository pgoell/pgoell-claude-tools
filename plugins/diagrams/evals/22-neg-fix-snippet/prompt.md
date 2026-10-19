---
tags: [core]
max_turns: 6
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

This is supposed to return the average of a list but it crashes on some inputs. What's wrong?

```python
def average(values):
    total = 0
    for v in values:
        total += v
    return total / len(values)
```
