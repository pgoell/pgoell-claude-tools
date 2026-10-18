---
type: How-to Guide
title: Set up the databricks plugin
description: Install the Databricks CLI and add an OAuth profile so databricks-core can work against your workspace.
tags: [databricks, cli, setup]
status: stable
---

# Set up the databricks plugin

`/databricks:databricks-core` runs the `databricks` CLI against the profiles in `~/.databrickscfg`. `/databricks:databricks-docs` only reads `docs.databricks.com` and needs no setup.

1. Install the Databricks CLI, version `v0.292.0` or newer. On Linux, macOS or WSL:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh | sh
   ```

   Homebrew and Windows routes: https://docs.databricks.com/aws/en/dev-tools/cli/install.
2. Add a profile per workspace with OAuth (the skill does not use personal access tokens):

   ```bash
   databricks auth login --host https://<workspace>.cloud.databricks.com --profile <name>
   ```

   The command opens a browser to log in and writes the profile to `~/.databrickscfg`.

## Check it worked

```bash
databricks --version
databricks auth profiles
```

The profile shows as valid. Ask the agent to "list the catalogs in profile `<name>`"; the skill passes `--profile` on each command.

The plugin's upstream license restricts the ported `databricks-core` files to use with Databricks Services. See [the databricks reference page](/reference/plugins/databricks.md).
