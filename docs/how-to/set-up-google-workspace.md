---
type: How-to Guide
title: Set up the google-workspace plugin
description: Install and log in to the gws CLI so the gmail and calendar skills can reach your Google account.
tags: [google-workspace, gmail, calendar, gws, setup]
status: stable
---

# Set up the google-workspace plugin

`/google-workspace:gmail` and `/google-workspace:calendar` drive the Google Workspace CLI, `gws`. Install it and log in once.

1. Install `gws`, one of:

   ```bash
   npm install -g @googleworkspace/cli
   brew install googleworkspace-cli
   ```

2. If you have no OAuth client yet, create one. This step needs the `gcloud` CLI:

   ```bash
   gws auth setup
   ```

3. Log in for the two services the skills use:

   ```bash
   gws auth login -s gmail,calendar
   ```

   Asking for these two services only keeps the scope list short. An OAuth app in Google's testing mode allows about 25 scopes, so asking for every Google service at once fails there.

## Check it worked

```bash
which gws && gws auth status
```

Then ask the agent for "today's agenda" or "my unread mail".

Full instructions, including other install routes: https://github.com/googleworkspace/cli.

See [the google-workspace reference page](/reference/plugins/google-workspace.md) for what each skill does.
