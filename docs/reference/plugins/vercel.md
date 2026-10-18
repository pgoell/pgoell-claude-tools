---
type: Reference
title: The vercel plugin
description: Vercel's agent skills for React, Next.js and React Native, guideline reviews, and Vercel deploys, tracked from upstream.
tags: [plugin, vercel, upstream, react, nextjs]
status: stable
---

# vercel

Vercel's agent skills: React and Next.js performance rules, composition patterns, React Native, view transitions, guideline reviews for UI code and prose, and deploys to Vercel.

**Runtimes:** Claude Code

Not in Codex or Cursor: the upstream ships no plugin manifest, so the Claude Code entry sets `strict: false` and supplies one. See [Runtimes](/reference/runtimes.md).

**Source:** upstream, not vendored: tracks [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) `main` unpinned. The repo README declares MIT; the repo has no `LICENSE` file.

**Setup:** [Set up the vercel plugin](/how-to/set-up-vercel.md)

## Skills

| Invocation                       | What it does                                                                     |
| -------------------------------- | -------------------------------------------------------------------------------- |
| `/vercel:react-best-practices`   | React and Next.js performance rules for writing, reviewing or refactoring code.  |
| `/vercel:composition-patterns`   | Component APIs that scale: compound components, render props, context providers. |
| `/vercel:react-view-transitions` | Animations with React's View Transition API.                                     |
| `/vercel:react-native-skills`    | React Native and Expo performance and native modules.                            |
| `/vercel:web-design-guidelines`  | Reviews UI code against Vercel's Web Interface Guidelines, fetched at runtime.   |
| `/vercel:writing-guidelines`     | Reviews docs and prose against Vercel's Writing Guidelines, fetched at runtime.  |
| `/vercel:deploy-to-vercel`       | Deploys an app to Vercel.                                                        |
| `/vercel:vercel-cli-with-tokens` | Drives the Vercel CLI with access tokens.                                        |
| `/vercel:vercel-optimize`        | Cost and performance tuning for deployed Vercel projects.                        |
