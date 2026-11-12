---
name: "databricks-core"
description: "Databricks CLI operations: auth, profiles, data exploration, and bundles. Contains up-to-date guidelines for Databricks-related CLI tasks."
compatibility: Requires databricks CLI (>= v0.292.0)
---

# Databricks

Core skill for Databricks CLI, authentication, and data exploration.

## Prerequisites

`databricks --version` must report `v0.292.0` or newer. Installation is the user's responsibility; if the CLI is missing, run the command anyway and let the shell's `command not found` surface the problem to the user.

**Authenticated:** `databricks auth profiles`. If empty: see [CLI Authentication](databricks-cli-auth.md).

## Profile Selection - CRITICAL

Do not pick among several profiles on your own: a wrong pick runs commands against the wrong workspace.

1. Use the profile the user named in this request or chose earlier in this session, and say which one you use.
2. Otherwise list profiles: `databricks auth profiles`
3. If exactly one exists, use it and say so.
4. If several exist, list them with their workspace URLs and ask once.
5. Offer to create a new profile if needed.

Run read-only commands (list, get, discover-schema, SELECT) without asking. Ask before `bundle deploy` or `bundle run` to a target the user did not name, and before SQL that writes, alters or drops.

## Claude Code - IMPORTANT

Each Bash command runs in a **separate shell session**.

```bash
# WORKS: --profile flag
databricks apps list --profile my-workspace

# WORKS: chained with &&
export DATABRICKS_CONFIG_PROFILE=my-workspace && databricks apps list

# DOES NOT WORK: separate commands
export DATABRICKS_CONFIG_PROFILE=my-workspace
databricks apps list  # profile not set!
```

## Data Exploration: Use AI Tools

**Use these instead of manually navigating catalogs/schemas/tables:**

```bash
# discover table structure (columns, types, sample data, stats)
databricks experimental aitools tools discover-schema catalog.schema.table --profile <PROFILE>

# run ad-hoc SQL queries
databricks experimental aitools tools query "SELECT * FROM table LIMIT 10" --profile <PROFILE>

# find the default warehouse
databricks experimental aitools tools get-default-warehouse --profile <PROFILE>
```

See [Data Exploration](data-exploration.md) for details.

## Quick Reference

**⚠️ CRITICAL: Some commands use positional arguments, not flags**

```bash
# current user
databricks current-user me --profile <PROFILE>

# list resources
databricks apps list --profile <PROFILE>
databricks jobs list --profile <PROFILE>
databricks clusters list --profile <PROFILE>
databricks warehouses list --profile <PROFILE>
databricks pipelines list --profile <PROFILE>
databricks serving-endpoints list --profile <PROFILE>

# ⚠️ Unity Catalog: POSITIONAL arguments (NOT flags!)
databricks catalogs list --profile <PROFILE>

# ✅ CORRECT: positional args
databricks schemas list <CATALOG> --profile <PROFILE>
databricks tables list <CATALOG> <SCHEMA> --profile <PROFILE>
databricks tables get <CATALOG>.<SCHEMA>.<TABLE> --profile <PROFILE>

# ❌ WRONG: these flags/commands DON'T EXIST
# databricks schemas list --catalog-name <CATALOG>    ← WILL FAIL
# databricks tables list --catalog <CATALOG>           ← WILL FAIL
# databricks sql-warehouses list                       ← doesn't exist, use `warehouses list`
# databricks execute-statement                         ← doesn't exist, use `experimental aitools tools query`
# databricks sql execute                               ← doesn't exist, use `experimental aitools tools query`

# When in doubt, check help:
# databricks schemas list --help

# get details
databricks apps get <NAME> --profile <PROFILE>
databricks jobs get --job-id <ID> --profile <PROFILE>
databricks clusters get --cluster-id <ID> --profile <PROFILE>

# bundles
databricks bundle init --profile <PROFILE>
databricks bundle validate --profile <PROFILE>
databricks bundle deploy -t <TARGET> --profile <PROFILE>
databricks bundle run <RESOURCE> -t <TARGET> --profile <PROFILE>
```

## Troubleshooting

| Error                                  | Solution                                   |
| -------------------------------------- | ------------------------------------------ |
| `cannot configure default credentials` | Use `--profile` flag or authenticate first |
| `PERMISSION_DENIED`                    | Check workspace/UC permissions             |
| `RESOURCE_DOES_NOT_EXIST`              | Verify resource name/id and profile        |

## Required Reading by Task

| Task                        | READ BEFORE proceeding                       |
| --------------------------- | -------------------------------------------- |
| Auth issues / new workspace | [CLI Authentication](databricks-cli-auth.md) |
| Exploring tables/schemas    | [Data Exploration](data-exploration.md)      |

## Reference Guides

- [CLI Authentication](databricks-cli-auth.md)
- [Data Exploration](data-exploration.md)
