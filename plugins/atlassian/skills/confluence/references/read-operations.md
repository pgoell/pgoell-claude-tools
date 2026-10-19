# Confluence Read Operations

Read this when you search pages, get a page, list pages or spaces, view a space, or get page comments.

## Search pages (CQL)

**curl** (v1 API):

```bash
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  "https://$ATLASSIAN_DOMAIN.atlassian.net/wiki/rest/api/search?cql=type%3Dpage+AND+title+~+%22search+term%22"
```

See `references/cql-recipes.md` for common CQL patterns.

## Get page by ID

**curl** (v2 API):

```bash
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  "https://$ATLASSIAN_DOMAIN.atlassian.net/wiki/api/v2/pages/{id}?body-format=storage"
```

## List pages in space

**curl** (v2 API):

```bash
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  "https://$ATLASSIAN_DOMAIN.atlassian.net/wiki/api/v2/spaces/{space-id}/pages"
```

## List spaces

**curl** (v2 API):

```bash
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  "https://$ATLASSIAN_DOMAIN.atlassian.net/wiki/api/v2/spaces"
```

## View space

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

## Get page comments

**curl** (v2 API):

```bash
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  "https://$ATLASSIAN_DOMAIN.atlassian.net/wiki/api/v2/pages/{id}/footer-comments"
```
