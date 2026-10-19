---
tags: [core]
max_turns: 6
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

Here's the diff for my branch:

```diff
 def list_orders(user_id, page=1):
-    rows = db.query("SELECT * FROM orders WHERE user_id = %s", user_id)
-    return rows
+    limit = 50
+    offset = (page - 1) * limit
+    rows = db.query(
+        "SELECT * FROM orders WHERE user_id = %s ORDER BY created_at DESC LIMIT %s OFFSET %s",
+        user_id, limit, offset,
+    )
+    return rows
```

Write the PR description for this change.
