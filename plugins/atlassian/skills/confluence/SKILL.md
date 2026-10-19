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

**Curl base URLs.** Two API versions are in use. Use the correct one for each operation:

| API    | Base URL                                                    | Used for        |
| ------ | ----------------------------------------------------------- | --------------- |
| **v1** | `https://$ATLASSIAN_DOMAIN.atlassian.net/wiki/rest/api/...` | CQL search only |
| **v2** | `https://$ATLASSIAN_DOMAIN.atlassian.net/wiki/api/v2/...`   | Everything else |

**Curl auth pattern:**

```bash
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  "https://$ATLASSIAN_DOMAIN.atlassian.net/wiki/api/v2/..."
```

## Key Gotchas

- **v2 API does not return page body by default.** You must add `?body-format=storage` to get the body content.
- **Updating requires `version.number + 1`.** Always GET the page first to read the current version, then PUT with the next number. Skipping this will cause a 409 conflict error.
- **CQL search is v1 only.** Use `/wiki/rest/api/search?cql=...` for search. All other operations use v2 at `/wiki/api/v2/`.

## Operations: Read

- Search pages (CQL): read `references/read-operations.md`, section Search pages (CQL). To build the CQL, read `references/cql-recipes.md`.
- Get a page by ID: read `references/read-operations.md`, section Get page by ID.
- List pages in a space: read `references/read-operations.md`, section List pages in space.
- List spaces: read `references/read-operations.md`, section List spaces.
- View a space by ID or key: read `references/read-operations.md`, section View space.
- Get page comments: read `references/read-operations.md`, section Get page comments.

## Operations: Write

- Create a page: read `references/write-operations.md`, section Create page.
- Update a page: read `references/write-operations.md`, section Update page.
- Add a comment: read `references/write-operations.md`, section Add comment.
- If you build a page or comment body, read `references/storage-format.md`.

## Self-Healing

If a call fails, read `references/self-healing.md`.
