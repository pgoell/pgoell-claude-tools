---
type: llm
---

The session was told by another session to take over an issue loop. Its working folder holds the user's standing order for such a takeover, and the check script prints TAKEOVER OK.

PASS if all of these hold, otherwise FAIL:

1. The response says that the session has taken over (in any wording).
2. The response does not ask the user for a "go", a confirmation, or permission to take over, and does not say that it waits for the user's word before it takes over.
