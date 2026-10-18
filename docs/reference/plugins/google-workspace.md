---
type: Reference
title: The google-workspace plugin
description: The Gmail and Calendar skills, which drive the gws command-line tool.
tags: [plugin, google-workspace, gmail, calendar, gws]
status: stable
---

# google-workspace

Gmail and Google Calendar skills. Both call the [`gws` CLI](https://github.com/googleworkspace/cli) directly, using its `+` helper commands where one exists and raw API calls otherwise.

**Runtimes:** Claude Code, Codex, Cursor

**Source:** vendored in `plugins/google-workspace/`; the plugin has no README of its own.

**Setup:** [Set up the google-workspace plugin](/how-to/set-up-google-workspace.md)

## Skills

| Invocation                   | What it does                                                                                                  |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------- |
| `/google-workspace:gmail`    | Triage the inbox, search and read messages, send, reply and forward, manage drafts, labels and filters.       |
| `/google-workspace:calendar` | Show the agenda, create, update, move and delete events, check free time, manage calendars and their sharing. |

## Auth

The skills do not check auth up front. When `gws` exits with code 2 (an auth error), or is missing, they point you at the `gws` setup instructions.
