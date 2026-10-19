---
type: llm
---

The user asks for the open issues labelled bug in this repo's GitHub issue tracker. The session has no shell or network tools, so it cannot fetch the list itself; the question is whether it treats the tracker as GitHub.
PASS if the response treats it as GitHub: it gives or reaches for a `gh issue list` command, points to the GitHub API or web page, or says it needs shell or network access to fetch the issues. FAIL if the response treats the repo as a Jira project, writes JQL, asks for a Jira site or project key, or makes up a list of issues.
