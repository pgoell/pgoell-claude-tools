---
type: How-to Guide
title: Update plugins
description: Pull the newest plugin versions from this marketplace into Claude Code, Codex or Cursor.
tags: [install, update, claude-code, codex, cursor]
status: stable
---

# Update plugins

Every change to a plugin in this repository bumps its version, so an update picks up exactly the plugins that changed. External plugins (`ponytail`, `emil`, `taste-skill`, `vercel`) follow their upstream `main` and change whenever upstream does.

## Claude Code

1. Open `/plugin`, go to the Marketplaces tab, pick `pgoell-claude-tools` and choose **Update marketplace**. This refreshes the listing and updates the plugins you installed from it.
2. Or work plugin by plugin. Refresh the listing, then update each plugin, from your shell:

   ```bash
   claude plugin marketplace update pgoell-claude-tools
   claude plugin update workbench@pgoell-claude-tools
   ```

   The refresh alone leaves installed plugins at their versions. Inside a session, `/plugin marketplace update pgoell-claude-tools` refreshes the listing, and the Installed tab of `/plugin` has **Update now** per plugin.
3. Run `/reload-plugins` in a running session, or start a new one.

To update without asking, open `/plugin`, pick the marketplace on the Marketplaces tab and choose **Enable auto-update**. It is off by default for third-party marketplaces such as this one.

## Codex

1. Refresh the marketplace from your shell:

   ```bash
   codex plugin marketplace upgrade pgoell-claude-tools
   ```

2. Start `codex`, open `/plugins`, and install the changed plugins again.

## Cursor

- **Team marketplace:** with **Auto Refresh** on (Dashboard > Plugins & MCPs), Cursor picks up each push to `master` by itself.
- **Local plugin:** copy `plugins/<name>/` from a fresh `git pull` over `~/.cursor/plugins/local/<name>/` again, then run **Developer: Reload Window**.
- **Cursor Marketplace:** Cursor reviews each update before it reaches users.

## Check it worked

In Claude Code, the Installed tab of `/plugin` shows each plugin's version. Compare it with the [plugin reference pages](/reference/plugins/index.md) or `.claude-plugin/marketplace.json`.

How to install in the first place: [Getting started](/tutorials/getting-started.md) and [Install in Cursor](/how-to/install-in-cursor.md).
