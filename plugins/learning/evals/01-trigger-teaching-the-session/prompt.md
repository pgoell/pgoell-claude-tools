---
tags: [core]
max_turns: 6
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

Here's the change we just made to the webhook sender:

```diff
 def send(event):
-    return post(WEBHOOK_URL, event.payload)
+    for attempt in range(MAX_ATTEMPTS):
+        resp = post(WEBHOOK_URL, event.payload)
+        if resp.status_code < 500:
+            return resp
+        time.sleep(BASE_DELAY * 2 ** attempt + random.uniform(0, 1))
+    raise WebhookFailed(event.id)
```

Before I open the PR, quiz me on what we did here so I'm sure I really understand it.
