# Confluence Self-Healing

Read this when a curl call fails.

## Auth Errors (401, 403, or "not authenticated")

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

## Other Errors

1. Check the error message for clues (permissions, bad request body, version conflict).
2. If the API may have changed, check live docs via web search. Canonical URL:
   - Confluence v2 REST API: `https://developer.atlassian.com/cloud/confluence/rest/v2/`
3. Retry with corrected parameters.
