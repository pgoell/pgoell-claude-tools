---
type: Reference
title: The emil plugin
description: Emil Kowalski's design engineering skills for UI polish, animation and prototyping, tracked from upstream.
tags: [plugin, emil, upstream, design, animation]
status: stable
---

# emil

Emil Kowalski's design engineering skills: UI polish, animation craft, motion reviews, prototyping and opinionated library picks. See [emilkowal.ski/skill](https://emilkowal.ski/skill).

**Runtimes:** Claude Code

Not in Codex or Cursor: the upstream ships no plugin manifest at all, so the Claude Code entry sets `strict: false` and supplies the manifest itself. See [Runtimes](/reference/runtimes.md).

**Source:** upstream, not vendored: tracks [emilkowalski/skill](https://github.com/emilkowalski/skill) `main` unpinned (MIT).

**Setup:** None beyond install.

## Skills

Three skills set `disable-model-invocation: true`, so they run only when you type the slash command; the table marks them.

| Invocation                           | What it does                                                                                                                       |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| `/emil:emil-design-eng`              | Emil's design engineering philosophy: UI polish, component design, animation decisions, the details that make software feel right. |
| `/emil:animate`                      | Builds a web animation from scratch, deciding in order whether it should animate, which tool, which properties.                    |
| `/emil:animate-expo`                 | The same for React Native and Expo.                                                                                                |
| `/emil:animation-performance`        | Keeps web animations inside the frame budget and finds why an animation drops frames.                                              |
| `/emil:animation-vocabulary`         | Turns a vague description of a motion effect into its exact term.                                                                  |
| `/emil:apple-design`                 | Apple's interface and fluid-motion approach, translated for the web.                                                               |
| `/emil:review-animations`            | Reviews motion code against a high craft bar. Slash command only.                                                                  |
| `/emil:improve-animations`           | Audits a codebase's animation code into a ranked plan.                                                                             |
| `/emil:find-animation-opportunities` | Finds places that should animate and rejects the ones that should not. Read-only.                                                  |
| `/emil:prototype`                    | Builds several versions of a UI piece behind a live picker. Slash command only.                                                    |
| `/emil:break-ui`                     | Feeds UI worst-case data: long names, empty states, huge counts.                                                                   |
| `/emil:mobile-native`                | CSS and meta-tag fixes that make a web app feel native on a phone.                                                                 |
| `/emil:pick-ui-library`              | Picks a library for a frontend task from a curated list. Slash command only.                                                       |
| `/emil:ask-sonner`                   | Guide to the Sonner toast library.                                                                                                 |
| `/emil:write-swift`                  | Modern Swift: value types, Swift 6 concurrency.                                                                                    |

`emil` overlaps with [taste-skill](/reference/plugins/taste-skill.md); install both only to compare.
