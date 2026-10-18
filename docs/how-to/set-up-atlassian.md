---
type: How-to Guide
title: Set up the atlassian plugin
description: Give the jira and confluence skills access to your Atlassian Cloud site, with an API token and, if you want bulk and sprint commands, the Atlassian CLI.
tags: [atlassian, jira, confluence, setup]
status: stable
---

# Set up the atlassian plugin

`/atlassian:jira` and `/atlassian:confluence` call the Atlassian Cloud REST API with `curl`. They need three environment variables. The Atlassian CLI (`acli`) is optional: the Jira skill falls back to it for bulk transitions and some sprint commands, and the Confluence skill for a few reads.

## Set the API token

1. Create a token at https://id.atlassian.com/manage/api-tokens.
2. Export three variables in your shell profile, such as `~/.bashrc` or `~/.zshrc`:

   ```bash
   export ATLASSIAN_DOMAIN="mycompany"          # for mycompany.atlassian.net
   export ATLASSIAN_EMAIL="you@company.com"
   export ATLASSIAN_API_TOKEN="<your token>"
   ```

3. Open a new shell, then start your agent from it so the session inherits the variables.

## Add the Atlassian CLI (optional)

1. Install it. On macOS with Homebrew:

   ```bash
   brew tap atlassian/homebrew-acli
   brew install acli
   ```

   For Linux and Windows, follow https://developer.atlassian.com/cloud/acli/guides/install-acli/.
2. Log in to Jira, in the browser or with the token from above:

   ```bash
   acli jira auth login --web
   ```

## Check it worked

```bash
test -n "$ATLASSIAN_API_TOKEN" && echo set
curl -s -o /dev/null -w '%{http_code}\n' -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  "https://$ATLASSIAN_DOMAIN.atlassian.net/rest/api/3/myself"
acli jira auth status    # only if you installed acli
```

The `curl` call prints `200`. Then ask the agent something like "show my open Jira issues".

The skills never print the token; when a call fails with 401 or 403 they check only whether each variable is set.

See [the atlassian reference page](/reference/plugins/atlassian.md) for what each skill does.
