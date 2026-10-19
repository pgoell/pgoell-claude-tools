---
type: llm
---

The user pastes the first lines of a CSV export of tickets (columns key, status, assignee, created), says it sits in a Postgres table called `tickets`, and asks for a SQL query that counts the tickets per assignee that are not Done and were created more than 14 days ago. The data is local, so this is a short SQL answer, not an issue tracker search.
PASS if the response gives a SQL query over the `tickets` table (filtering out Done, comparing `created` with a date 14 days back, grouping by assignee), with at most a short note on it. FAIL if the response writes JQL instead of SQL, tries to search an issue tracker, asks for a site URL, a project key or credentials, or plans steps instead of giving the query.
