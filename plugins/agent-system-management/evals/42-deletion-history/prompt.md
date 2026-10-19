---
tags: [core, deletion]
max_turns: 8
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

Here is a skill of mine. This one SKILL.md file is the whole skill, with no references or scripts, and there is no copy on disk for you to read.

```markdown
---
name: preview-env-cleanup
description: Use when the user wants stale preview environments in the staging cluster found and removed, for example "clean up old previews" or "which preview environments can go".
---

# Preview environment cleanup

Preview environments are namespaces named `preview-<pr-number>` in the staging cluster.

## Find stale previews

1. List the namespaces whose name starts with `preview-`.
2. Look up each pull request by its number. A preview is stale when its pull request is merged or closed.
3. Keep any namespace labelled `keep=true`, whatever the state of its pull request.

## Delete

- Show the user the exact names of the namespaces you will delete, and delete only after the user confirms that list. Never delete by a name pattern or wildcard.
- Kubernetes namespaces group pods, services and other resources inside a cluster.
- This skill took over from a nightly cleanup cron job, which the platform team retired in March 2025.

## Report

Tell the user which namespaces you deleted and which you kept, with the reason for each one you kept.
```

Please cut this skill down to what it actually needs. Make the cut yourself rather than only listing candidates. You cannot write files here, so paste the full cut SKILL.md back in your reply.
