---
type: Reference
title: The atlassian plugin
description: The Jira and Confluence skills for Atlassian Cloud, and the credentials they read.
tags: [plugin, atlassian, jira, confluence]
status: stable
---

# atlassian

Jira and Confluence skills for Atlassian Cloud. Both call the Atlassian REST API with `curl`. The Jira skill falls back to the Atlassian CLI (`acli`) for the few jobs `curl` handles badly; `acli` has no Confluence commands.

**Runtimes:** Claude Code, Codex, Cursor

**Source:** vendored in `plugins/atlassian/`; the plugin has no README of its own.

**Setup:** [Set up the atlassian plugin](/how-to/set-up-atlassian.md)

**Tests:** `bash plugins/atlassian/tests/run.sh` parses every JSON body in the skills' examples (`json` code fences and curl `-d` bodies) with no network. Last run 2026-10-19: 30 bodies, 0 failed.

## Skills

| Invocation              | What it does                                                                                                                          |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `/atlassian:jira`       | Search issues with JQL, create and update tickets, add comments, move issues through the workflow, inspect sprints, bulk transitions. |
| `/atlassian:confluence` | Search pages with CQL, read pages, create and update pages, browse spaces.                                                            |

## Credentials

The skills read `ATLASSIAN_DOMAIN`, `ATLASSIAN_EMAIL` and `ATLASSIAN_API_TOKEN` from the environment. They check only that each is set and never print the values. They do not check auth up front: they run the command and diagnose a failure afterwards.
