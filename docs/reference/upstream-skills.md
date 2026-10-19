---
type: Reference
title: Upstream skills at a glance
description: Every skill from the upstream plugins the marketplace points at by git URL, with its invocation, its plugin, and one line on what it does.
tags: [skills, plugins, upstream, index]
status: stable
---

# Upstream skills at a glance

Every skill from the four plugins the marketplace points at by git URL (ponytail, emil, taste-skill and vercel), in marketplace order. Their authors maintain them upstream; the skills of this repo's own plugins are in [Skills at a glance](/reference/skills.md). Invoke a skill with its full name, `/<plugin>:<skill>`. The names are Claude Code's; Codex names most taste-skill skills differently, and [taste-skill](/reference/plugins/taste-skill.md) lists both.

| Skill                                      | Plugin                                           | What it does                                                                                     |
| ------------------------------------------ | ------------------------------------------------ | ------------------------------------------------------------------------------------------------ |
| `/ponytail:ponytail`                       | [ponytail](/reference/plugins/ponytail.md)       | Force the simplest solution that works: YAGNI, standard library first, one line over fifty.      |
| `/ponytail:ponytail-review`                | [ponytail](/reference/plugins/ponytail.md)       | Review a diff for over-engineering only.                                                         |
| `/ponytail:ponytail-audit`                 | [ponytail](/reference/plugins/ponytail.md)       | Rank a whole repo's over-engineering by what to delete, simplify or replace.                     |
| `/ponytail:ponytail-debt`                  | [ponytail](/reference/plugins/ponytail.md)       | Collect `ponytail:` shortcut comments into a debt ledger.                                        |
| `/ponytail:ponytail-gain`                  | [ponytail](/reference/plugins/ponytail.md)       | Show ponytail's measured benchmark impact.                                                       |
| `/ponytail:ponytail-help`                  | [ponytail](/reference/plugins/ponytail.md)       | Quick-reference card for ponytail's modes, skills and commands.                                  |
| `/emil:emil-design-eng`                    | [emil](/reference/plugins/emil.md)               | Emil Kowalski's design engineering philosophy: UI polish, component design, animation decisions. |
| `/emil:animate`                            | [emil](/reference/plugins/emil.md)               | Build a web animation from scratch.                                                              |
| `/emil:animate-expo`                       | [emil](/reference/plugins/emil.md)               | Build an animation in React Native and Expo.                                                     |
| `/emil:animation-performance`              | [emil](/reference/plugins/emil.md)               | Keep web animations inside the frame budget and find why one drops frames.                       |
| `/emil:animation-vocabulary`               | [emil](/reference/plugins/emil.md)               | Name the motion effect you mean.                                                                 |
| `/emil:apple-design`                       | [emil](/reference/plugins/emil.md)               | Apple-style interface design and fluid motion, for the web.                                      |
| `/emil:review-animations`                  | [emil](/reference/plugins/emil.md)               | Review motion code against a high craft bar (slash command only).                                |
| `/emil:improve-animations`                 | [emil](/reference/plugins/emil.md)               | Audit a codebase's animations into a ranked plan.                                                |
| `/emil:find-animation-opportunities`       | [emil](/reference/plugins/emil.md)               | Find where motion belongs and where it does not.                                                 |
| `/emil:prototype`                          | [emil](/reference/plugins/emil.md)               | Build several versions of a UI piece behind a live picker (slash command only).                  |
| `/emil:break-ui`                           | [emil](/reference/plugins/emil.md)               | Test UI with worst-case data.                                                                    |
| `/emil:mobile-native`                      | [emil](/reference/plugins/emil.md)               | Make a web app feel native on a phone.                                                           |
| `/emil:pick-ui-library`                    | [emil](/reference/plugins/emil.md)               | Pick a frontend library from a curated list (slash command only).                                |
| `/emil:ask-sonner`                         | [emil](/reference/plugins/emil.md)               | Guide to the Sonner toast library.                                                               |
| `/emil:write-swift`                        | [emil](/reference/plugins/emil.md)               | Write modern Swift.                                                                              |
| `/taste-skill:taste-skill`                 | [taste-skill](/reference/plugins/taste-skill.md) | Infer a design direction from the brief and ship pages that do not look templated.               |
| `/taste-skill:taste-skill-v1`              | [taste-skill](/reference/plugins/taste-skill.md) | The frozen v1 of taste-skill.                                                                    |
| `/taste-skill:taste-skill-v2-experimental` | [taste-skill](/reference/plugins/taste-skill.md) | The earlier experimental v2, kept for projects that depend on it.                                |
| `/taste-skill:gpt-tasteskill`              | [taste-skill](/reference/plugins/taste-skill.md) | A variant tuned for GPT and Codex models.                                                        |
| `/taste-skill:redesign-skill`              | [taste-skill](/reference/plugins/taste-skill.md) | Audit an existing site or app for generic patterns and upgrade it without breaking behavior.     |
| `/taste-skill:output-skill`                | [taste-skill](/reference/plugins/taste-skill.md) | Ban placeholders and truncation; force complete code.                                            |
| `/taste-skill:minimalist-skill`            | [taste-skill](/reference/plugins/taste-skill.md) | Style variant: editorial minimalist.                                                             |
| `/taste-skill:soft-skill`                  | [taste-skill](/reference/plugins/taste-skill.md) | Style variant: soft premium agency.                                                              |
| `/taste-skill:brutalist-skill`             | [taste-skill](/reference/plugins/taste-skill.md) | Style variant: Swiss brutalist.                                                                  |
| `/taste-skill:image-to-code-skill`         | [taste-skill](/reference/plugins/taste-skill.md) | Generate a design reference image, then build from it.                                           |
| `/taste-skill:imagegen-frontend-web`       | [taste-skill](/reference/plugins/taste-skill.md) | Generate web design reference images.                                                            |
| `/taste-skill:imagegen-frontend-mobile`    | [taste-skill](/reference/plugins/taste-skill.md) | Generate mobile design reference images.                                                         |
| `/taste-skill:brandkit`                    | [taste-skill](/reference/plugins/taste-skill.md) | Generate a brand kit as reference images.                                                        |
| `/taste-skill:stitch-skill`                | [taste-skill](/reference/plugins/taste-skill.md) | Write a Google Stitch compatible `DESIGN.md`.                                                    |
| `/vercel:react-best-practices`             | [vercel](/reference/plugins/vercel.md)           | React and Next.js performance rules.                                                             |
| `/vercel:composition-patterns`             | [vercel](/reference/plugins/vercel.md)           | Component APIs that scale.                                                                       |
| `/vercel:react-view-transitions`           | [vercel](/reference/plugins/vercel.md)           | Animations with React's View Transition API.                                                     |
| `/vercel:react-native-skills`              | [vercel](/reference/plugins/vercel.md)           | React Native and Expo performance and native modules.                                            |
| `/vercel:web-design-guidelines`            | [vercel](/reference/plugins/vercel.md)           | Review UI code against Vercel's Web Interface Guidelines.                                        |
| `/vercel:writing-guidelines`               | [vercel](/reference/plugins/vercel.md)           | Review docs and prose against Vercel's Writing Guidelines.                                       |
| `/vercel:deploy-to-vercel`                 | [vercel](/reference/plugins/vercel.md)           | Deploy an app to Vercel.                                                                         |
| `/vercel:vercel-cli-with-tokens`           | [vercel](/reference/plugins/vercel.md)           | Drive the Vercel CLI with access tokens.                                                         |
| `/vercel:vercel-optimize`                  | [vercel](/reference/plugins/vercel.md)           | Tune cost and performance of deployed Vercel projects.                                           |
