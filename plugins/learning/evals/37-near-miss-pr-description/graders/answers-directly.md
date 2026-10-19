---
type: llm
---

The user pastes a diff that adds pagination to `list_orders` (50 rows per page, newest first, with LIMIT and OFFSET) and asks for the pull request description for this change. This is a writing task about the change, not a check of the user's understanding.

PASS if the response writes a PR description based on the diff, or briefly asks what else the branch changed before writing it. FAIL if the response starts quizzing the user on the change, asks them to explain it, or starts teaching them about pagination.
