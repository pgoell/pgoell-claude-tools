---
name: jira
description: Search Jira, manage issues, add comments, transition work, and inspect sprints.
---

# Jira Skill

Interact with Jira Cloud: search issues, create and update tickets, transition workflows, add comments, manage sprints, and perform bulk operations.

---

## Auth Approach

Do NOT check authentication upfront. Just run the command. If it fails with an auth error, see the **Self-Healing** section for diagnostics.

**NEVER print, echo, or log the values of `ATLASSIAN_API_TOKEN`, `ATLASSIAN_EMAIL`, or any credentials.** Only check whether they are set (e.g., `test -n`), never display their contents.

---

## Tool Preference

**Prefer raw curl for all operations.** It has the fewest dependencies and the clearest behavior. Only fall back to `acli` for the handful of things curl can't do ergonomically: bulk transitions (`--jql` + `--yes`) and some sprint operations.

Pattern for all curl requests:

```bash
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  "https://$ATLASSIAN_DOMAIN.atlassian.net/rest/api/3/..."
```

For write operations, add:

```bash
-H "Content-Type: application/json" -X POST -d '...'
```

---

## Operations: Tier 1 (Read)

- Search issues (JQL): read `references/read-operations.md`, section Search Issues. To build the JQL, read `references/jql-recipes.md`.
- View an issue: read `references/read-operations.md`, section View Issue.
- List projects: read `references/read-operations.md`, section List Projects.
- View comments: read `references/read-operations.md`, section View Comments.
- List sprints or the work items in a sprint: read `references/read-operations.md`, section Sprints.

## Operations: Tier 2 (Write)

- Create an issue (story, task, bug, research or design ticket): read `references/write-operations.md`, section Create Issue, before you write anything.
- Add a comment: read `references/write-operations.md`, section Add Comment.
- Edit fields: read `references/write-operations.md`, section Edit Fields.
- If you build a curl write body (description, comment), read `references/adf-format.md`.

## Operations: Tier 3 (Workflow)

- Transition an issue: read `references/workflow-operations.md`, section Transition Issue.
- Assign an issue: read `references/workflow-operations.md`, section Assign Issue.
- Link issues: read `references/workflow-operations.md`, section Link Issues.
- Transition many issues at once: read `references/workflow-operations.md`, section Bulk Operations.

---

## Self-Healing

If a call fails, or you need a project's fields or issue types, read `references/self-healing.md`.

---

## Behavioral Guidelines

- **Map natural language to operations directly (curl-first):**
  - "Move PROJ-123 to done" = GET `/issue/PROJ-123/transitions`, then POST the matching transition ID
  - "Assign this to me" = GET `/myself` for accountId, then PUT `/issue/PROJ-123/assignee`
  - "What am I working on?" = POST `/search/jql` with `assignee = currentUser() AND statusCategory = 'In Progress'`
  - "Create a bug for the login issue" = POST `/issue` with ADF description
