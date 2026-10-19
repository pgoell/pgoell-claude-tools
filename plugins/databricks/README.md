# databricks plugin

Skills for working with Databricks workspaces from a Claude Code, Codex or Cursor host agent.

## Skills

- **databricks-core**: CLI, authentication, profile management, and data exploration. Ported verbatim from [databricks/databricks-agent-skills](https://github.com/databricks/databricks-agent-skills) at commit `bf6d932f7e435faf95cb4c5193bdc153b95a90cc`, with port-time substitutions documented in `NOTICE`. Governed by the upstream Databricks License (vendored at `LICENSE-upstream`).

- **databricks-docs**: Live `docs.databricks.com` lookups for product-surface questions (Apps, DABs, Jobs, Lakebase, Model Serving, Pipelines, Unity Catalog, SQL Warehouses, MLflow, serverless, secrets, workflows). Original authorship, MIT licensed. Uses the host agent's WebFetch tool plus a curated URL index in `references/docs-index.md`.

## Setup

No setup required. `databricks-core` operates against your existing `databricks` CLI profiles (configure them with `databricks auth login` or by editing `~/.databrickscfg`). `databricks-docs` is read-only against the public docs site and needs no auth.

## License

- Original work in this directory (`databricks-docs`, plugin metadata, marketplace integration, `NOTICE`, this README): MIT, see `LICENSE`.
- Ported work in `skills/databricks-core/`: Databricks License, see `LICENSE-upstream`. Key restriction: use only in connection with Databricks Services.

See `NOTICE` for the per-file upstream mapping.

## Credits

- Upstream: [databricks/databricks-agent-skills](https://github.com/databricks/databricks-agent-skills), commit `bf6d932`. Copyright (2025) Databricks, Inc.
- Port + new skill authorship: Pascal Göllner, 2026.

## Historical Notes

`references/research/` preserves 12 MB of reverse-engineering notes from a prior Genie Code investigation (covering LakeAgent, Dashboard Authoring Agent, sub-agents, tool handlers, captured network traces). Those notes are out of scope for the current installable surface; they remain in the directory as a starting point for any future Genie Code skill. The Genie Code skill and its bundled MCP server are preserved in git history at commit `6e509a4` (PR #52).
