# Jira Workflow Operations

Read this when you transition, assign, or link issues, or change many issues at once.

## Transition Issue

**curl** (must fetch transition IDs first, then POST):

```bash
# Step 1: Get available transitions
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  "https://$ATLASSIAN_DOMAIN.atlassian.net/rest/api/3/issue/KEY-123/transitions"

# Step 2: POST with the transition ID from step 1
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -X POST "https://$ATLASSIAN_DOMAIN.atlassian.net/rest/api/3/issue/KEY-123/transitions" \
  -d '{"transition": {"id": "31"}}'
```

**acli (fallback, uses status name directly):**

```bash
acli jira workitem transition --key KEY-123 --status "Done"
```

## Assign Issue

**curl:**

```bash
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -X PUT "https://$ATLASSIAN_DOMAIN.atlassian.net/rest/api/3/issue/KEY-123/assignee" \
  -d '{"accountId": "5b10ac8d82e05b22cc7d4ef5"}'
```

Note: with curl, you must know the user's `accountId`. Use `GET /rest/api/3/myself` to get the current user's account ID for self-assignment.

**acli (fallback):**

```bash
acli jira workitem assign --key KEY-123 --assignee "@me"
```

## Link Issues

**curl:**

```bash
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -X POST "https://$ATLASSIAN_DOMAIN.atlassian.net/rest/api/3/issueLink" \
  -d '{
  "type": {"name": "Blocks"},
  "inwardIssue": {"key": "KEY-123"},
  "outwardIssue": {"key": "KEY-456"}
}'
```

**acli (fallback):**

```bash
acli jira workitem link create --inward-key KEY-123 --outward-key KEY-456 --type "Blocks"
```

## Bulk Operations

**acli** (transition all matching issues at once):

```bash
acli jira workitem transition \
  --jql "project = PROJ AND status = 'To Do'" \
  --status "In Progress" \
  --yes
```

Bulk operations are an acli-only feature. With curl, loop over search results and POST transitions individually.
