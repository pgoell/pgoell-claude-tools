---
name: databricks-docs
description: Use when the user asks a Databricks product question (Apps, DABs, Jobs, Lakebase, Model Serving, Pipelines, Unity Catalog, SQL Warehouses, MLflow, serverless, secrets, workflows) that databricks-core's CLI cheatsheet does not answer. Resolves a canonical URL from references/docs-index.md and fetches it with the host agent's WebFetch tool.
---

# Databricks Docs Skill

Live docs.databricks.com lookups for Databricks product questions.

## When to Use

Use this skill when the user asks about a Databricks product surface and the question is not about a CLI invocation. Examples:

- "How do I configure a serverless model serving endpoint?"
- "What's the DAB schema for a job?"
- "How does Lakebase Postgres autoscaling work?"
- "How do I grant a user access to a Unity Catalog schema?"

Do NOT use this skill when the user asks about CLI commands, profile management, auth, or data exploration. Those are owned by `databricks-core`.

## How to Use

1. Read `references/docs-index.md` to find the canonical entry URL for the topic the user is asking about.
2. Use the host agent's `WebFetch` tool to fetch the entry URL with a focused prompt describing the user's question.
3. If the answer is not on the entry page, follow in-page links via additional `WebFetch` calls.

## URL Pattern

Default to `docs.databricks.com/aws/en/...`. If the user has specified Azure or GCP, rewrite the `aws` segment to `azure` or `gcp` before fetching. The page structure and content are the same across all three.

## Limits

- Read-only. No auth, no MCP, no Databricks CLI required.
- Do not synthesize answers from training-data knowledge of Databricks. Always fetch.
- If a fetch fails, retry once, then try the docs root from `references/docs-index.md` or a web search limited to docs.databricks.com. If the site still cannot be reached, say so. Do not answer from memory as if it were the docs.

## Cross-Reference

For CLI commands, profile management, authentication, and data exploration, use the `databricks-core` skill. The two skills are complementary; this one handles "what" and "how" questions about Databricks product surfaces, while `databricks-core` handles "run this CLI command" questions.

## References

- [references/docs-index.md](references/docs-index.md): canonical entry URLs per topic.
