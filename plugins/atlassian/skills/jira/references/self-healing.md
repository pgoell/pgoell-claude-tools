# Jira Self-Healing

Read this when a curl call or acli command fails, or when you need to find a project's fields or issue types.

## Auth Errors (401, 403, or "not authenticated")

Check which auth paths are available, but **never print token or credential values**:

```bash
# Check if env vars are set (NOT their values)
test -n "${ATLASSIAN_DOMAIN:-}" && echo "ATLASSIAN_DOMAIN is set" || echo "ATLASSIAN_DOMAIN is NOT set"
test -n "${ATLASSIAN_EMAIL:-}" && echo "ATLASSIAN_EMAIL is set" || echo "ATLASSIAN_EMAIL is NOT set"
test -n "${ATLASSIAN_API_TOKEN:-}" && echo "ATLASSIAN_API_TOKEN is set" || echo "ATLASSIAN_API_TOKEN is NOT set"
```

```bash
# Check acli (optional fallback)
command -v acli && acli jira auth status
```

If `acli jira auth status` exits 0, acli is logged in: a bulk transition or sprint command may still go through acli while curl fails. Every other task waits for curl to work. If it exits non-zero or acli is missing, ignore the acli check.

If all three variables are set and curl returns 401, tell the user: "Jira refused the email and token. Check `ATLASSIAN_EMAIL`, or make a new token at https://id.atlassian.com/manage/api-tokens and update `ATLASSIAN_API_TOKEN`." On 403, tell the user their account lacks permission for that project or action. Retry the curl call once the user has fixed it. If any variable is missing, tell the user:

> I cannot connect to Jira. Set these environment variables:
>
> - `ATLASSIAN_DOMAIN`: your subdomain (e.g., `mycompany` for `mycompany.atlassian.net`)
> - `ATLASSIAN_EMAIL`: your Atlassian account email
> - `ATLASSIAN_API_TOKEN`: generate one at https://id.atlassian.com/manage/api-tokens
>
> Optional: for bulk transitions and sprint commands, also install the Atlassian CLI and log in:
>
> ```
> acli jira auth login --web
> ```

## Other Errors

1. **For acli errors:** check `acli [command] --help` for current flags and syntax
2. **For REST API errors:** check the response body for error details and verify the endpoint
3. **Search live docs** if the error is unclear:
   - Jira REST API v3: `https://developer.atlassian.com/cloud/jira/platform/rest/v3/`
   - acli reference: `https://developer.atlassian.com/cloud/acli/reference/commands/`

## Field Discovery

When you need to find available fields or issue types:

```bash
# Available issue types and fields for a project
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  "https://$ATLASSIAN_DOMAIN.atlassian.net/rest/api/3/issue/createmeta/PROJ/issuetypes"

# All available fields in the instance
curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  -H "Accept: application/json" \
  "https://$ATLASSIAN_DOMAIN.atlassian.net/rest/api/3/field"
```
