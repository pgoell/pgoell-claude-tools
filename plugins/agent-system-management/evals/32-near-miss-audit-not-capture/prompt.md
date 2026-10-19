---
tags: [core]
max_turns: 6
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

This is our AGENTS.md:

```markdown
# Agents

- Use Node 16 (see .nvmrc).
- Deploy with `./deploy.sh staging` (the script was replaced by GitHub Actions last year).
- Keep things clean.
- Ask before doing anything big.
- Tests live in `spec/`.
- Prefer small PRs when possible.
```

Nothing from this session, I want the existing file checked for outdated or vague rules and scored, with a list of what to fix.
