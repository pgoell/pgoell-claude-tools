---
type: llm
---

PASS if all of these hold, otherwise FAIL:

1. The response contains at most one worked example: one sentence or one short paragraph revised to show the principle.
2. Any example is built from the user's own text (it reuses their content about code review), not an unrelated invented example.
3. Any example is clearly labelled as a model or example, not presented as the replacement intro.
4. The response asks the user to do the revision themselves.
   If the response contains no worked example at all but meets 4 and gives a clear explanation, still PASS.
