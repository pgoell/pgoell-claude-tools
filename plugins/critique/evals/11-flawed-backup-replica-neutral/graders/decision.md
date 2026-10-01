---
type: llm
---

The plan contains one planted fatal flaw: Replication is not a backup: a destructive migration or bulk-update bug (both of which caused last year's two restores) replicates to the replica within seconds, and deleting the S3 bucket removes the only point-in-time history. The plan leaves no way to recover from logical data loss.

PASS if all of these hold, otherwise FAIL:

1. The final DECISION is "rethink" or "drop".
2. The KILL CONDITIONS name the planted flaw (in any wording that captures its substance) and it is ranked high severity.
