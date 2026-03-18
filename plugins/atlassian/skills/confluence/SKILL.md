---
name: confluence
description: Use when the user wants to interact with Confluence — search pages, read documentation, create or update pages, or browse spaces
---

# Confluence Skill

Interact with Confluence Cloud to search pages, read documentation, create or update content, and browse spaces.

## Auth Gate

**You MUST confirm authentication before making any API calls.**

### Step 1 — Check env vars (PRIMARY — required for most operations)

```bash
echo "ATLASSIAN_DOMAIN=${ATLASSIAN_DOMAIN:-(not set)}"
echo "ATLASSIAN_EMAIL=${ATLASSIAN_EMAIL:-(not set)}"
echo "ATLASSIAN_API_TOKEN=${ATLASSIAN_API_TOKEN:-(not set)}"
```

All three must be set for curl-based operations. Since curl is the primary tool for Confluence, these are effectively required for any real workflow. **If env vars are set, you are good to proceed — do not wait for acli.**

### Step 2 — Optionally check acli (supplementary only)

```bash
command -v acli && acli auth status
```

If available and authenticated, acli can supplement curl for a few operations (page view by ID, space list/view). But acli is **not required** and **not the primary tool** for Confluence.

**Important: If acli is not installed or not authenticated, silently fall back to curl. Do NOT ask the user about acli setup. Do NOT stop or prompt — just use curl.**

### If env vars are not set AND acli is not available — STOP

Only stop if **neither** auth path works. Tell the user:

> To use Confluence, set these environment variables:
>
> ```bash
> export ATLASSIAN_DOMAIN="yourcompany"        # yourcompany.atlassian.net
> export ATLASSIAN_EMAIL="you@company.com"
> export ATLASSIAN_API_TOKEN="your-token"
> ```
>
> Generate an API token at: https://id.atlassian.com/manage/api-tokens

**Do not proceed without auth. This is a hard gate.**

## Script Detection

Check if wrapper scripts are available:

```bash
test -f "${CLAUDE_PLUGIN_ROOT}/scripts/_common.sh" && echo "SCRIPTS OK"
```

If available, prefer scripts for all curl-based operations. Scripts handle auth, URL construction, and error handling internally.

## Tool Preference

**Wrapper scripts are the preferred tool for Confluence**, followed by acli for limited operations, then raw curl as fallback.

| Priority | Tool | Use for |
|----------|------|---------|
| 1 | **Wrapper scripts** (`${CLAUDE_PLUGIN_ROOT}/scripts/confluence/...`) | Preferred for all curl-based operations |
| 2 | **acli** | Page view by ID, space list, space view |
| 3 | **Raw curl** | Fallback if scripts aren't available |

### Curl base URLs

Two API versions are in use. Use the correct one for each operation:

| API | Base URL | Used for |
|-----|----------|----------|
| **v1** | `https://$ATLASSIAN_DOMAIN.atlassian.net/wiki/rest/api/...` | CQL search only |
| **v2** | `https://$ATLASSIAN_DOMAIN.atlassian.net/wiki/api/v2/...` | Everything else |

### Curl auth pattern

```bash
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  "https://$ATLASSIAN_DOMAIN.atlassian.net/wiki/api/v2/..."
```

## Operations — Read

### Search pages (CQL)

**script:**

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/confluence/search.sh <cql> [--limit N]
```

**curl** (v1 API) — acli does not support CQL search.

```bash
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  "https://$ATLASSIAN_DOMAIN.atlassian.net/wiki/rest/api/search?cql=type%3Dpage+AND+title+~+%22search+term%22"
```

See `cql-recipes.md` for common CQL patterns.

### Get page by ID

**script:**

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/confluence/get-page.sh <page-id> [--body-format storage|atlas_doc_format|view]
```

**acli:**

```bash
acli confluence page view --id {id} --body-format storage --json
```

**curl** (v2 API):

```bash
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  "https://$ATLASSIAN_DOMAIN.atlassian.net/wiki/api/v2/pages/{id}?body-format=storage"
```

### List pages in space

**curl only** (v2 API):

```bash
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  "https://$ATLASSIAN_DOMAIN.atlassian.net/wiki/api/v2/spaces/{space-id}/pages"
```

### List spaces

**script:**

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/confluence/list-spaces.sh [--limit N]
```

**acli:**

```bash
acli confluence space list --json
```

**curl** (v2 API):

```bash
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  "https://$ATLASSIAN_DOMAIN.atlassian.net/wiki/api/v2/spaces"
```

### View space

**acli:**

```bash
acli confluence space view --key KEY --json
```

**curl** (v2 API):

```bash
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  "https://$ATLASSIAN_DOMAIN.atlassian.net/wiki/api/v2/spaces/{id}"
```

### Get page comments

**curl only** (v2 API):

```bash
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  "https://$ATLASSIAN_DOMAIN.atlassian.net/wiki/api/v2/pages/{id}/footer-comments"
```

## Operations — Write

All write operations require curl. acli does not support Confluence page create, update, or comments.

### Create page

**script:**

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/confluence/create-page.sh --space-id ID --title "..." --body "..."
```

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

**script:**

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/confluence/update-page.sh <page-id> --body "..." [--title "..."]
```

**curl** — You MUST GET the page first to obtain the current version number, then PUT with `version.number + 1`.

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
- **acli Confluence support is limited.** Only use acli for page view (by ID) and space operations (list, view). Everything else requires curl.

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

If an API call or acli command fails:

1. Check the error message for clues (auth, permissions, bad request body, version conflict).
2. For acli errors, run `acli confluence [command] --help` for current flags and syntax.
3. If the API may have changed, check live docs via web search. Canonical URLs:
   - Confluence v2 REST API: `https://developer.atlassian.com/cloud/confluence/rest/v2/`
   - acli reference: `https://developer.atlassian.com/cloud/acli/reference/commands/`
4. Retry with corrected parameters.

## Behavioral Guidelines

- **Infer intent from natural language.** "Find the onboarding doc" becomes a CQL search: `type = page AND title ~ "onboarding"`.
- **Construct all CQL and storage format from user intent.** Never ask the user to write CQL or XHTML manually.
- **For page updates: ALWAYS GET first, then PUT.** "Update the design page with our new architecture" means: search or get the page, read the current version number, construct updated content in storage format, PUT with incremented version.
- **Use acli for quick page views by ID and space operations** when acli is available. Fall back to curl for everything else.
- **Use `--json` flag with acli** when you need to parse structured output.
