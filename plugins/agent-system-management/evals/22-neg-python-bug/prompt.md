---
tags: [core]
max_turns: 6
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

Why does this keep adding to the same list across calls?

```python
def add_tag(tag, tags=[]):
    tags.append(tag)
    return tags

print(add_tag("a"))
print(add_tag("b"))  # prints ['a', 'b'], I expected ['b']
```

Please fix it.
