---
name: confluence
description: Search, read, create, and update Confluence pages.
---

# Confluence Skill

Interact with Confluence Cloud to search pages, read documentation, create or update content, and browse spaces.

## Auth Approach

Do NOT check authentication upfront. Just run the command. If it fails with an auth error, see the **Self-Healing** section for diagnostics.

**NEVER print, echo, or log the values of `ATLASSIAN_API_TOKEN`, `ATLASSIAN_EMAIL`, or any credentials.** Only check whether they are set (e.g., `test -n`), never display their contents.

## Tool Preference

**Use raw curl for every operation.** `acli` has no Confluence commands (its reference lists admin, feedback, jira and rovodev only), so use curl for everything.

### Curl base URLs

Two API versions are in use. Use the correct one for each operation:

| API    | Base URL                                                    | Used for        |
| ------ | ----------------------------------------------------------- | --------------- |
| **v1** | `https://$ATLASSIAN_DOMAIN.atlassian.net/wiki/rest/api/...` | CQL search only |
| **v2** | `https://$ATLASSIAN_DOMAIN.atlassian.net/wiki/api/v2/...`   | Everything else |

### Curl auth pattern

```bash
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  "https://$ATLASSIAN_DOMAIN.atlassian.net/wiki/api/v2/..."
```

## Operations: Read

### Search pages (CQL)

**curl** (v1 API):

```bash
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  "https://$ATLASSIAN_DOMAIN.atlassian.net/wiki/rest/api/search?cql=type%3Dpage+AND+title+~+%22search+term%22"
```

See `cql-recipes.md` for common CQL patterns.

### Get page by ID

**curl** (v2 API):

```bash
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  "https://$ATLASSIAN_DOMAIN.atlassian.net/wiki/api/v2/pages/{id}?body-format=storage"
```

### List pages in space

**curl** (v2 API):

```bash
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  "https://$ATLASSIAN_DOMAIN.atlassian.net/wiki/api/v2/spaces/{space-id}/pages"
```

### List spaces

**curl** (v2 API):

```bash
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  "https://$ATLASSIAN_DOMAIN.atlassian.net/wiki/api/v2/spaces"
```

### View space

**curl** (v2 API), by ID:

```bash
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  "https://$ATLASSIAN_DOMAIN.atlassian.net/wiki/api/v2/spaces/{id}"
```

By key: look the space up first. The response holds `results[]`; take `results[0].id` and call `/spaces/{id}` as above. An empty `results` means the key is wrong or the user cannot see that space; say so and ask for the key.

```bash
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  "https://$ATLASSIAN_DOMAIN.atlassian.net/wiki/api/v2/spaces?keys=KEY"
```

### Get page comments

**curl** (v2 API):

```bash
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  "https://$ATLASSIAN_DOMAIN.atlassian.net/wiki/api/v2/pages/{id}/footer-comments"
```

## Operations: Write

### Create page

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

See `storage-format.md` for how to construct the body value.

### Update page

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

### Add comment

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

## Key Gotchas

- **v2 API does not return page body by default.** You must add `?body-format=storage` to get the body content.
- **Updating requires `version.number + 1`.** Always GET the page first to read the current version, then PUT with the next number. Skipping this will cause a 409 conflict error.
- **CQL search is v1 only.** Use `/wiki/rest/api/search?cql=...` for search. All other operations use v2 at `/wiki/api/v2/`.

## Common CQL Recipes

See `cql-recipes.md` for a full reference of CQL search patterns, including:

- Search by title, space, creator, and modification date
- Combining conditions with AND/OR
- Label-based and ancestor-based queries

## Storage Format Reference

See `storage-format.md` for the Confluence XHTML storage format reference, needed for creating and updating pages. Covers:

- Basic elements (paragraphs, headings, lists, tables, links)
- Confluence-specific macros (code blocks, TOC, info panels)
- Converting user intent into storage format XHTML

## Self-Healing

If an API call fails:

### Auth Errors (401, 403, or "not authenticated")

Check which variables are set, but **never print token or credential values**:

```bash
# Check if env vars are set (NOT their values)
test -n "${ATLASSIAN_DOMAIN:-}" && echo "ATLASSIAN_DOMAIN is set" || echo "ATLASSIAN_DOMAIN is NOT set"
test -n "${ATLASSIAN_EMAIL:-}" && echo "ATLASSIAN_EMAIL is set" || echo "ATLASSIAN_EMAIL is NOT set"
test -n "${ATLASSIAN_API_TOKEN:-}" && echo "ATLASSIAN_API_TOKEN is set" || echo "ATLASSIAN_API_TOKEN is NOT set"
```

If any of the variables is not set, tell the user:

> To use Confluence, set these environment variables:
>
> ```bash
> export ATLASSIAN_DOMAIN="yourcompany"        # yourcompany.atlassian.net
> export ATLASSIAN_EMAIL="you@company.com"
> export ATLASSIAN_API_TOKEN="your-token"
> ```
>
> Generate an API token at: https://id.atlassian.com/manage/api-tokens

If all three variables are set and curl returns 401, tell the user: "Confluence refused the email and token. Check `ATLASSIAN_EMAIL`, or make a new token at https://id.atlassian.com/manage/api-tokens and update `ATLASSIAN_API_TOKEN`." On 403, tell the user their account lacks permission for that space or page. Retry the curl call once the user has fixed it.

### Other Errors

1. Check the error message for clues (permissions, bad request body, version conflict).
2. If the API may have changed, check live docs via web search. Canonical URL:
   - Confluence v2 REST API: `https://developer.atlassian.com/cloud/confluence/rest/v2/`
3. Retry with corrected parameters.

## Behavioral Guidelines

- **Infer intent from natural language.** "Find the onboarding doc" becomes a CQL search: `type = page AND title ~ "onboarding"`.
- **Construct all CQL and storage format from user intent.** Never ask the user to write CQL or XHTML manually.
- **For page updates: ALWAYS GET first, then PUT.** "Update the design page with our new architecture" means: search or get the page, read the current version number, construct updated content in storage format, PUT with incremented version.
