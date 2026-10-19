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

**Tests:** `bash plugins/atlassian/tests/run.sh` parses every JSON body in the skills' examples (`json` code fences and curl `-d` bodies) with no network. Last run 2026-10-19: 30 bodies, 0 failed. The eval suite in `plugins/atlassian/evals/` tests when the skills fire (see "Evals").

## Skills

| Invocation              | What it does                                                                                                                          |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `/atlassian:jira`       | Search issues with JQL, create and update tickets, add comments, move issues through the workflow, inspect sprints, bulk transitions. |
| `/atlassian:confluence` | Search pages with CQL, read pages, create and update pages, browse spaces.                                                            |

## Evals

`plugins/atlassian/evals/` holds 10 `claude plugin eval` cases that test when `jira` and `confluence` fire. Cases 01 and 02 are triggers: in 01, a Jira job, `atlassian:jira` must fire and `atlassian:confluence` must not; 02, a Confluence job, is the reverse. Cases 21 to 23 are negatives (a concept question, a translation, a one-paragraph summary): neither skill may fire.

Cases 31 and 32 are near-misses between the two skills. Case 31 is a Jira job in wiki words (comment on a ticket with a link to a runbook page): `jira` must fire and `confluence` must not. Case 32 is a Confluence job in ticket and sprint words (a sprint retrospective page that lists ticket keys): `confluence` must fire and `jira` must not. Case 31 never says "Confluence" and case 32 never says "Jira", so the model must route on the job, not the product name.

Cases 33 to 35 are near-misses outside the plugin: neither skill may fire, and an `llm` grader checks the reply. Case 33 asks for a SQL query over a CSV export of tickets. It is not a JQL ask, since the `jira` skill carries JQL recipes and a JQL ask may rightly fire it. Case 34 asks for a design doc drafted in chat as markdown for the user to paste into the wiki. Case 35 asks for the open bug issues in a GitHub repo and passes when the reply treats it as GitHub.

Every case allows only Skill, Read, Glob and Grep, so no case needs Atlassian credentials or network. The graders match the full names `atlassian:jira` and `atlassian:confluence`, so a word in a call's args does not match.

No one has run the suite yet; a run costs money, so the user decides when. Run from `plugins/atlassian`:

```bash
claude plugin eval . --trust-plugin --tag core --runs 1 -j 4 --max-cost-usd 5 --no-publish
```

## Credentials

The skills read `ATLASSIAN_DOMAIN`, `ATLASSIAN_EMAIL` and `ATLASSIAN_API_TOKEN` from the environment. They check only that each is set and never print the values. They do not check auth up front: they run the command and diagnose a failure afterwards.
