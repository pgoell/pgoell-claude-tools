# Jira Write Operations

Read this when you create an issue, add a comment, or edit fields.

ADF is required for curl write operations (create issue descriptions, add comments, update descriptions); read `references/adf-format.md` to build the body. When falling back to `acli`, pass plain text directly; no ADF required.

## Create Issue

**Before creating a user story, task, or research/design ticket, ask the user:**

> Do you have a ticket template or writing guide you'd like me to follow (e.g., a team standard for Description + Acceptance Criteria)?
>
> If not, I can use the default template in `references/ticket-template.md`. It structures Context, Deliverable, Scope, Stakeholders, Timebox, References, and Acceptance Criteria checkboxes.

If the user has their own template, follow it. If they opt into the default (or don't have one), read `references/ticket-template.md` and structure the `--summary`, `--description`, and acceptance criteria fields according to it. For trivial bug reports or quick one-line tasks, skip the prompt unless the user explicitly asks for a structured ticket.

**curl** (requires ADF body for description, see `references/adf-format.md`):

```bash
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -X POST "https://$ATLASSIAN_DOMAIN.atlassian.net/rest/api/3/issue" \
  -d '{
  "fields": {
    "project": {"key": "PROJ"},
    "summary": "Implement rate limiting",
    "issuetype": {"name": "Task"},
    "description": {
      "version": 1,
      "type": "doc",
      "content": [
        {
          "type": "paragraph",
          "content": [{"type": "text", "text": "Add rate limiting to auth endpoints to prevent brute-force attacks."}]
        }
      ]
    }
  }
}'
```

**acli (fallback, plain text, no ADF needed):**

```bash
acli jira workitem create \
  --project PROJ \
  --type Task \
  --summary "Implement rate limiting" \
  --description "Add rate limiting to auth endpoints to prevent brute-force attacks."
```

## Add Comment

**curl** (requires ADF body):

```bash
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -X POST "https://$ATLASSIAN_DOMAIN.atlassian.net/rest/api/3/issue/KEY-123/comment" \
  -d '{
  "body": {
    "version": 1,
    "type": "doc",
    "content": [
      {
        "type": "paragraph",
        "content": [{"type": "text", "text": "Investigated the issue. Root cause identified. Fix incoming."}]
      }
    ]
  }
}'
```

**acli (fallback, plain text):**

```bash
acli jira workitem comment create --key KEY-123 --body "Investigated the issue. Root cause identified. Fix incoming."
```

## Edit Fields

**curl:**

```bash
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -X PUT "https://$ATLASSIAN_DOMAIN.atlassian.net/rest/api/3/issue/KEY-123" \
  -d '{
  "fields": {
    "summary": "Updated summary",
    "labels": ["backend", "urgent"]
  }
}'
```

**acli (fallback):**

```bash
acli jira workitem edit --key KEY-123 --summary "Updated summary" --description "New description" --labels "backend,urgent"
```
