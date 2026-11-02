---
type: Reference
title: Upstream skills at a glance
description: Every skill from the upstream plugins the marketplace points at by git URL, with its invocation, its plugin, and one line on what it does.
tags: [skills, plugins, upstream, index]
status: stable
---

# Upstream skills at a glance

Every skill from the five plugins the marketplace points at by git URL (ponytail, emil, taste-skill, vercel and unslop), in marketplace order. Their authors maintain them upstream; the skills of this repo's own plugins are in [Skills at a glance](/reference/skills.md). Invoke a skill with its full name, `/<plugin>:<skill>`. The names are Claude Code's; Codex names the taste-skill skill differently, and [taste-skill](/reference/plugins/taste-skill.md) lists both.

| Skill                                | Plugin                                           | What it does                                                                                     |
| ------------------------------------ | ------------------------------------------------ | ------------------------------------------------------------------------------------------------ |
| `/ponytail:ponytail`                 | [ponytail](/reference/plugins/ponytail.md)       | Force the simplest solution that works: YAGNI, standard library first, one line over fifty.      |
| `/ponytail:ponytail-review`          | [ponytail](/reference/plugins/ponytail.md)       | Review a diff for over-engineering only.                                                         |
| `/ponytail:ponytail-audit`           | [ponytail](/reference/plugins/ponytail.md)       | Rank a whole repo's over-engineering by what to delete, simplify or replace.                     |
| `/ponytail:ponytail-debt`            | [ponytail](/reference/plugins/ponytail.md)       | Collect `ponytail:` shortcut comments into a debt ledger.                                        |
| `/ponytail:ponytail-gain`            | [ponytail](/reference/plugins/ponytail.md)       | Show ponytail's measured benchmark impact.                                                       |
| `/ponytail:ponytail-help`            | [ponytail](/reference/plugins/ponytail.md)       | Quick-reference card for ponytail's modes, skills and commands.                                  |
| `/emil:emil-design-eng`              | [emil](/reference/plugins/emil.md)               | Emil Kowalski's design engineering philosophy: UI polish, component design, animation decisions. |
| `/emil:animate`                      | [emil](/reference/plugins/emil.md)               | Build a web animation from scratch.                                                              |
| `/emil:animate-expo`                 | [emil](/reference/plugins/emil.md)               | Build an animation in React Native and Expo.                                                     |
| `/emil:animation-performance`        | [emil](/reference/plugins/emil.md)               | Keep web animations inside the frame budget and find why one drops frames.                       |
| `/emil:animation-vocabulary`         | [emil](/reference/plugins/emil.md)               | Name the motion effect you mean.                                                                 |
| `/emil:apple-design`                 | [emil](/reference/plugins/emil.md)               | Apple-style interface design and fluid motion, for the web.                                      |
| `/emil:review-animations`            | [emil](/reference/plugins/emil.md)               | Review motion code against a high craft bar (slash command only).                                |
| `/emil:improve-animations`           | [emil](/reference/plugins/emil.md)               | Audit a codebase's animations into a ranked plan.                                                |
| `/emil:find-animation-opportunities` | [emil](/reference/plugins/emil.md)               | Find where motion belongs and where it does not.                                                 |
| `/emil:prototype`                    | [emil](/reference/plugins/emil.md)               | Build several versions of a UI piece behind a live picker (slash command only).                  |
| `/emil:break-ui`                     | [emil](/reference/plugins/emil.md)               | Test UI with worst-case data.                                                                    |
| `/emil:mobile-native`                | [emil](/reference/plugins/emil.md)               | Make a web app feel native on a phone.                                                           |
| `/emil:pick-ui-library`              | [emil](/reference/plugins/emil.md)               | Pick a frontend library from a curated list (slash command only).                                |
| `/emil:ask-sonner`                   | [emil](/reference/plugins/emil.md)               | Guide to the Sonner toast library.                                                               |
| `/emil:write-swift`                  | [emil](/reference/plugins/emil.md)               | Write modern Swift.                                                                              |
| `/taste-skill:taste-skill`           | [taste-skill](/reference/plugins/taste-skill.md) | Build or redesign a page or app screen from a researched art direction, checked in a browser.    |
| `/vercel:react-best-practices`       | [vercel](/reference/plugins/vercel.md)           | React and Next.js performance rules.                                                             |
| `/vercel:composition-patterns`       | [vercel](/reference/plugins/vercel.md)           | Component APIs that scale.                                                                       |
| `/vercel:react-view-transitions`     | [vercel](/reference/plugins/vercel.md)           | Animations with React's View Transition API.                                                     |
| `/vercel:react-native-skills`        | [vercel](/reference/plugins/vercel.md)           | React Native and Expo performance and native modules.                                            |
| `/vercel:web-design-guidelines`      | [vercel](/reference/plugins/vercel.md)           | Review UI code against Vercel's Web Interface Guidelines.                                        |
| `/vercel:writing-guidelines`         | [vercel](/reference/plugins/vercel.md)           | Review docs and prose against Vercel's Writing Guidelines.                                       |
| `/vercel:deploy-to-vercel`           | [vercel](/reference/plugins/vercel.md)           | Deploy an app to Vercel.                                                                         |
| `/vercel:vercel-cli-with-tokens`     | [vercel](/reference/plugins/vercel.md)           | Drive the Vercel CLI with access tokens.                                                         |
| `/vercel:vercel-optimize`            | [vercel](/reference/plugins/vercel.md)           | Tune cost and performance of deployed Vercel projects.                                           |
| `/unslop:unslop`                     | [unslop](/reference/plugins/unslop.md)           | Audit an existing screen for the AI look, then polish it or rework it in nine ordered passes.    |
