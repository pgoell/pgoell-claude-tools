---
tags: [core]
max_turns: 6
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

Our AGENTS.md has grown way too long and the agent seems to ignore half of it. Here it is:

```markdown
# Project guide

## About

This project is a web app. It is written in TypeScript. TypeScript is a typed superset of JavaScript.
We care a lot about quality and we want all contributors to care about quality too.

## Commands

- Install: `pnpm install`
- Test: `pnpm test`
- Lint: `pnpm lint`
- Build: `pnpm build`
- To install dependencies, run `pnpm install`.
- To run the tests, run `pnpm test`.

## Style

- Write clean, readable code.
- Use meaningful variable names.
- Code should be easy to read.
- Prefer readability over cleverness.
- Use Prettier (config in `.prettierrc`).

## History

In 2023 we moved from Jest to Vitest. Before that we used Mocha. The move took two sprints.
We also tried Bun for a month but went back to pnpm.

## Misc

- Be helpful.
- Be careful.
- Think before you act.
```

Please cut it down and trim it to what actually matters. Shorten it as much as you can without losing anything the agent needs.
