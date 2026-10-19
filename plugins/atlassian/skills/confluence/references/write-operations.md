# Confluence Write Operations

Read this when you create a page, update a page, or add a comment.

## Create page

**curl:**

```bash
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -X POST \
  "https://$ATLASSIAN_DOMAIN.atlassian.net/wiki/api/v2/pages" \
  -d '{
    "spaceId": "123456",
    "status": "current",
    "title": "Page Title",
    "body": {
      "representation": "storage",
      "value": "<p>Page content in storage format.</p>"
    }
  }'
```

See `references/storage-format.md` for how to construct the body value.

## Update page

**curl**: You MUST GET the page first to obtain the current version number, then PUT with `version.number + 1`.

```bash
# Step 1: GET current page (note the version number in the response)
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  "https://$ATLASSIAN_DOMAIN.atlassian.net/wiki/api/v2/pages/{id}?body-format=storage"

# Step 2: PUT with incremented version
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -X PUT \
  "https://$ATLASSIAN_DOMAIN.atlassian.net/wiki/api/v2/pages/{id}" \
  -d '{
    "id": "{id}",
    "status": "current",
    "title": "Page Title",
    "body": {
      "representation": "storage",
      "value": "<p>Updated content in storage format.</p>"
    },
    "version": {
      "number": CURRENT_VERSION_PLUS_ONE
    }
  }'
```

Never guess the version number. Always GET first.

## Add comment

```bash
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -X POST \
  "https://$ATLASSIAN_DOMAIN.atlassian.net/wiki/api/v2/pages/{id}/footer-comments" \
  -d '{
    "body": {
      "representation": "storage",
      "value": "<p>Comment text here.</p>"
    }
  }'
```
