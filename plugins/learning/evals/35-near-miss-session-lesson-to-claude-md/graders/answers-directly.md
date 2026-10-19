---
type: llm
---

The user states what this session taught them (a flaky billing test was a timezone issue; it passed on CI and failed on a machine in Europe/Berlin; the fix is to always set TZ=UTC when running tests) and asks which line to add to CLAUDE.md so future sessions know it. This is a request for instruction text, not for a lesson.

PASS if the response proposes the instruction line (a proposed line passes, since the available tools cannot write files) or reads CLAUDE.md to decide where the line belongs. FAIL if the response starts teaching the user about timezones or the session's work, or quizzes the user or asks them to answer questions about it.
