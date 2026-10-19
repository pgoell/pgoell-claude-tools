# Jira Read Operations

Read this when you search issues, view an issue or its comments, list projects, or list sprints.

## Search Issues

**curl:**

```bash
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -X POST "https://$ATLASSIAN_DOMAIN.atlassian.net/rest/api/3/search/jql" \
  -d '{"jql": "assignee = currentUser() AND resolution = Unresolved", "maxResults": 50}'
```

**acli (fallback):**

```bash
acli jira workitem search --jql "assignee = currentUser() AND resolution = Unresolved" --json
```

For common JQL patterns, read `jql-recipes.md` in this folder.

## View Issue

**curl:**

```bash
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  "https://$ATLASSIAN_DOMAIN.atlassian.net/rest/api/3/issue/KEY-123"
```

**acli (fallback):**

```bash
acli jira workitem view KEY-123 --json
```

## List Projects

**acli:**

```bash
acli jira project list
```

**curl:**

```bash
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  "https://$ATLASSIAN_DOMAIN.atlassian.net/rest/api/3/project/search"
```

## View Comments

**acli:**

```bash
acli jira workitem comment list --key KEY-123
```

**curl:**

```bash
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  "https://$ATLASSIAN_DOMAIN.atlassian.net/rest/api/3/issue/KEY-123/comment"
```

## Sprints

**List sprints for a board:**

```bash
acli jira board list-sprints --board-id {id}
```

**List work items in a sprint:**

```bash
acli jira sprint list-workitems --sprint-id {id}
```

For sprint operations without acli, use the Jira Agile REST API (`/rest/agile/1.0/...`).
