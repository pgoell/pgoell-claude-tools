---
type: Reference
title: The databricks plugin
description: The Databricks CLI and documentation skills, what they need, and the licence that limits databricks-core.
tags: [plugin, databricks, cli, docs]
status: stable
---

# databricks

Two Databricks skills: one for work through the `databricks` CLI, one that answers product questions from the live documentation.

**Runtimes:** Claude Code, Codex, Cursor

**Source:** vendored in `plugins/databricks/`; see the [plugin README](../../../plugins/databricks/README.md) for details and credits.

**Setup:** [Set up the databricks plugin](/how-to/set-up-databricks.md)

## Skills

| Invocation                    | What it does                                                                                                                                                                                                                                                                                                     |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/databricks:databricks-core` | Databricks CLI work: authentication, profile selection, data exploration (schemas, queries, warehouses) and bundles. Needs `databricks` CLI v0.292.0 or newer and works against your existing CLI profiles.                                                                                                      |
| `/databricks:databricks-docs` | Answer product questions the CLI notes do not cover (Apps, bundles, Jobs, Lakebase, Model Serving, Pipelines, Unity Catalog, SQL Warehouses, MLflow, serverless, secrets, workflows). Looks up a URL in a curated index and fetches it from `docs.databricks.com` with the host's web fetch tool; needs no auth. |

## Licence

`databricks-core` is a verbatim port of [databricks/databricks-agent-skills](https://github.com/databricks/databricks-agent-skills) at commit `bf6d932`, under the Databricks License: you may use it only in connection with Databricks Services. The plugin vendors that licence as `LICENSE-upstream`. `databricks-docs` and the rest of the plugin are original MIT work. The plugin's `NOTICE` maps each file.
