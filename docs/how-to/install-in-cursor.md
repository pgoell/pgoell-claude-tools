---
type: How-to Guide
title: Install in Cursor
description: Install plugins from this repository in Cursor, from the Cursor Marketplace, a team marketplace, or a local copy.
tags: [install, cursor]
status: stable
---

# Install in Cursor

The repository is also a Cursor plugin marketplace: `.cursor-plugin/marketplace.json` at the root lists 16 plugins. Cursor offers `atlassian`, `google-workspace`, `research`, `writing`, `runtime-bridge`, `agent-system-management`, `workbench`, `terminal`, `playground`, `databricks`, `learning`, `critique`, `presentations`, `diagrams`, `news` and `insights`. Why the other plugins are missing is in [Runtimes](/reference/runtimes.md).

Pick one of three ways.

## From the Cursor Marketplace

Once a plugin is listed there: open **Customize**, search for the plugin, and choose **Install**.

## From a team marketplace

This needs a Cursor Teams or Enterprise plan.

1. Open **Dashboard > Plugins & MCPs > Add Marketplace > Import from Repo**.
2. Enter `https://github.com/pgoell/pgoell-claude-tools`.
3. Turn on **Auto Refresh** so Cursor picks up each push to `master`.

## As a local copy, one plugin at a time

1. Clone the repository:

   ```bash
   git clone https://github.com/pgoell/pgoell-claude-tools.git
   ```

2. Copy the plugin folder:

   ```bash
   mkdir -p ~/.cursor/plugins/local
   cp -r pgoell-claude-tools/plugins/<name> ~/.cursor/plugins/local/<name>
   ```

   Copy, do not link: Cursor skips symlinks that point outside that folder.
3. Run **Developer: Reload Window**.

## Check it worked

The plugin's skills show up in Cursor's skill list. Ask for something one of them does, such as "brainstorm this feature with me" for `workbench`.

Some plugins need more setup after install; see the [how-to index](/how-to/index.md). To pull new versions later, see [Update plugins](/how-to/update-plugins.md).
