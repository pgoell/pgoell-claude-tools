---
tags: [core]
max_turns: 6
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

This is the change we made today:

```diff
 class SessionCache:
-    def get(self, key):
-        return self.store.get(key)
+    def get(self, key):
+        entry = self.store.get(key)
+        if entry and entry.expires_at < time.time():
+            self.store.delete(key)
+            return None
+        return entry
```

Before I merge, I want to be sure I can actually explain this in review. Go through it with me point by point and check that I really understand each part.
