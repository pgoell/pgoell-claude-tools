---
type: llm
---

The user states what this session taught them (a flaky billing test was a timezone issue; it passed on CI and failed on a machine in Europe/Berlin; the fix is to always set TZ=UTC when running tests) and asks which line to add to CLAUDE.md so future sessions know it. This is a request for instruction text, not for a lesson.

PASS if the response proposes the instruction line to add (a proposed line passes, since the available tools cannot write files; reading CLAUDE.md first is fine, and a one-sentence reason next to the line is fine). FAIL if the response proposes no line, if it is mainly a lesson on timezones or the session's work, or if it quizzes the user or asks them to answer questions about it.
