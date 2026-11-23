---
type: Reference
title: Upstream skills at a glance
description: Every skill from the upstream plugins the marketplace points at by git URL, with its invocation, its plugin, and one line on what it does.
tags: [skills, plugins, upstream, index]
status: stable
---

# Upstream skills at a glance

Every skill from the six plugins the marketplace points at by git URL (ponytail, emil, taste-skill, vercel, unslop and evals) and from pstack, which it mirrors, in marketplace order. Their authors maintain them upstream; the skills of this repo's own plugins are in [Skills at a glance](/reference/skills.md). Invoke a skill with its full name, `/<plugin>:<skill>`. Most pstack skills run only as slash commands. The names are Claude Code's; Codex names the taste-skill skill differently, and [taste-skill](/reference/plugins/taste-skill.md) lists both.

| Skill                                        | Plugin                                           | What it does                                                                                     |
| -------------------------------------------- | ------------------------------------------------ | ------------------------------------------------------------------------------------------------ |
| `/ponytail:ponytail`                         | [ponytail](/reference/plugins/ponytail.md)       | Force the simplest solution that works: YAGNI, standard library first, one line over fifty.      |
| `/ponytail:ponytail-review`                  | [ponytail](/reference/plugins/ponytail.md)       | Review a diff for over-engineering only.                                                         |
| `/ponytail:ponytail-audit`                   | [ponytail](/reference/plugins/ponytail.md)       | Rank a whole repo's over-engineering by what to delete, simplify or replace.                     |
| `/ponytail:ponytail-debt`                    | [ponytail](/reference/plugins/ponytail.md)       | Collect `ponytail:` shortcut comments into a debt ledger.                                        |
| `/ponytail:ponytail-gain`                    | [ponytail](/reference/plugins/ponytail.md)       | Show ponytail's measured benchmark impact.                                                       |
| `/ponytail:ponytail-help`                    | [ponytail](/reference/plugins/ponytail.md)       | Quick-reference card for ponytail's modes, skills and commands.                                  |
| `/emil:emil-design-eng`                      | [emil](/reference/plugins/emil.md)               | Emil Kowalski's design engineering philosophy: UI polish, component design, animation decisions. |
| `/emil:animate`                              | [emil](/reference/plugins/emil.md)               | Build a web animation from scratch.                                                              |
| `/emil:animate-expo`                         | [emil](/reference/plugins/emil.md)               | Build an animation in React Native and Expo.                                                     |
| `/emil:animation-performance`                | [emil](/reference/plugins/emil.md)               | Keep web animations inside the frame budget and find why one drops frames.                       |
| `/emil:animation-vocabulary`                 | [emil](/reference/plugins/emil.md)               | Name the motion effect you mean.                                                                 |
| `/emil:apple-design`                         | [emil](/reference/plugins/emil.md)               | Apple-style interface design and fluid motion, for the web.                                      |
| `/emil:review-animations`                    | [emil](/reference/plugins/emil.md)               | Review motion code against a high craft bar (slash command only).                                |
| `/emil:improve-animations`                   | [emil](/reference/plugins/emil.md)               | Audit a codebase's animations into a ranked plan.                                                |
| `/emil:find-animation-opportunities`         | [emil](/reference/plugins/emil.md)               | Find where motion belongs and where it does not.                                                 |
| `/emil:prototype`                            | [emil](/reference/plugins/emil.md)               | Build several versions of a UI piece behind a live picker (slash command only).                  |
| `/emil:break-ui`                             | [emil](/reference/plugins/emil.md)               | Test UI with worst-case data.                                                                    |
| `/emil:mobile-native`                        | [emil](/reference/plugins/emil.md)               | Make a web app feel native on a phone.                                                           |
| `/emil:pick-ui-library`                      | [emil](/reference/plugins/emil.md)               | Pick a frontend library from a curated list (slash command only).                                |
| `/emil:ask-sonner`                           | [emil](/reference/plugins/emil.md)               | Guide to the Sonner toast library.                                                               |
| `/emil:write-swift`                          | [emil](/reference/plugins/emil.md)               | Write modern Swift.                                                                              |
| `/taste-skill:taste-skill`                   | [taste-skill](/reference/plugins/taste-skill.md) | Build or redesign a page or app screen from a researched art direction, checked in a browser.    |
| `/vercel:react-best-practices`               | [vercel](/reference/plugins/vercel.md)           | React and Next.js performance rules.                                                             |
| `/vercel:composition-patterns`               | [vercel](/reference/plugins/vercel.md)           | Component APIs that scale.                                                                       |
| `/vercel:react-view-transitions`             | [vercel](/reference/plugins/vercel.md)           | Animations with React's View Transition API.                                                     |
| `/vercel:react-native-skills`                | [vercel](/reference/plugins/vercel.md)           | React Native and Expo performance and native modules.                                            |
| `/vercel:web-design-guidelines`              | [vercel](/reference/plugins/vercel.md)           | Review UI code against Vercel's Web Interface Guidelines.                                        |
| `/vercel:writing-guidelines`                 | [vercel](/reference/plugins/vercel.md)           | Review docs and prose against Vercel's Writing Guidelines.                                       |
| `/vercel:deploy-to-vercel`                   | [vercel](/reference/plugins/vercel.md)           | Deploy an app to Vercel.                                                                         |
| `/vercel:vercel-cli-with-tokens`             | [vercel](/reference/plugins/vercel.md)           | Drive the Vercel CLI with access tokens.                                                         |
| `/vercel:vercel-optimize`                    | [vercel](/reference/plugins/vercel.md)           | Tune cost and performance of deployed Vercel projects.                                           |
| `/unslop:unslop`                             | [unslop](/reference/plugins/unslop.md)           | Audit an existing screen for the AI look, then polish it or rework it in nine ordered passes.    |
| `/evals:evals-start`                         | [evals](/reference/plugins/evals.md)             | Entry point: route an evals request to the skill that fits.                                      |
| `/evals:eval-audit`                          | [evals](/reference/plugins/evals.md)             | Audit an eval pipeline and rank its problems.                                                    |
| `/evals:error-discovery`                     | [evals](/reference/plugins/evals.md)             | Review traces in a built review app and group the notes into failure modes.                      |
| `/evals:generate-synthetic-data`             | [evals](/reference/plugins/evals.md)             | Create varied synthetic test inputs from dimension tuples.                                       |
| `/evals:write-code-eval`                     | [evals](/reference/plugins/evals.md)             | Write code checks for failure modes with objective rules.                                        |
| `/evals:write-judge-prompt`                  | [evals](/reference/plugins/evals.md)             | Design an LLM judge for a criterion code cannot check.                                           |
| `/evals:validate-evaluator`                  | [evals](/reference/plugins/evals.md)             | Calibrate an LLM judge against human labels.                                                     |
| `/evals:evaluate-rag`                        | [evals](/reference/plugins/evals.md)             | Evaluate retrieval and generation quality in a RAG pipeline.                                     |
| `/evals:build-review-interface`              | [evals](/reference/plugins/evals.md)             | Build a browser interface for reviewing and labelling traces.                                    |
| `/pstack:poteto-mode`                        | [pstack](/reference/plugins/pstack.md)           | Pick a playbook for a non-trivial task and work in poteto's style.                               |
| `/pstack:poteto-help`                        | [pstack](/reference/plugins/pstack.md)           | Find the skill, playbook or principle for a task.                                                |
| `/pstack:in-your-own-words`                  | [pstack](/reference/plugins/pstack.md)           | Restate the user's goal and problem before work starts.                                          |
| `/pstack:sharpen`                            | [pstack](/reference/plugins/pstack.md)           | Make a task deeper, not bigger, then rewrite the prompt.                                         |
| `/pstack:how`                                | [pstack](/reference/plugins/pstack.md)           | Walk through how a subsystem works and where code should live.                                   |
| `/pstack:why`                                | [pstack](/reference/plugins/pstack.md)           | Explain why code works the way it does, from commits and PR history.                             |
| `/pstack:recall`                             | [pstack](/reference/plugins/pstack.md)           | Rebuild recent working context on a topic as a short brief.                                      |
| `/pstack:ketchup`                            | [pstack](/reference/plugins/pstack.md)           | Catch the user up on what changed since their last message.                                      |
| `/pstack:ketchup-video`                      | [pstack](/reference/plugins/pstack.md)           | The same as a short subtitled slide video.                                                       |
| `/pstack:blast-radius`                       | [pstack](/reference/plugins/pstack.md)           | Find what a change could break beyond the diff, and prove it safe.                               |
| `/pstack:architect`                          | [pstack](/reference/plugins/pstack.md)           | Sketch types, signatures and modules before code.                                                |
| `/pstack:arena`                              | [pstack](/reference/plugins/pstack.md)           | Run N attempts in parallel and graft the best parts into one.                                    |
| `/pstack:swarm`                              | [pstack](/reference/plugins/pstack.md)           | Fan out N parallel workers and return one report.                                                |
| `/pstack:interrogate`                        | [pstack](/reference/plugins/pstack.md)           | Have other models try to break a diff; keep only proven findings.                                |
| `/pstack:automate-me`                        | [pstack](/reference/plugins/pstack.md)           | Draft your own `-mode` skill from your transcripts.                                              |
| `/pstack:make-bot-ui`                        | [pstack](/reference/plugins/pstack.md)           | Build a dashboard whose buttons wake a bot over a webhook.                                       |
| `/pstack:setup-pstack`                       | [pstack](/reference/plugins/pstack.md)           | Set the model and reasoning budget for each role.                                                |
| `/pstack:reflect`                            | [pstack](/reference/plugins/pstack.md)           | Turn a long task's learnings into edits on existing skills.                                      |
| `/pstack:correct`                            | [pstack](/reference/plugins/pstack.md)           | Make a repeated agent mistake impossible: architecture, types, lint, test.                       |
| `/pstack:teach`                              | [pstack](/reference/plugins/pstack.md)           | Explain a body of work plainly, from `how` and `why`.                                            |
| `/pstack:tdd`                                | [pstack](/reference/plugins/pstack.md)           | Write a failing test first, then the fix.                                                        |
| `/pstack:benchmark-checklist`                | [pstack](/reference/plugins/pstack.md)           | Vet a performance number before reporting it.                                                    |
| `/pstack:no-comments`                        | [pstack](/reference/plugins/pstack.md)           | Run the Comment Sicko subagent over the diff and act on its findings.                            |
| `/pstack:typescript-best-practices`          | [pstack](/reference/plugins/pstack.md)           | TypeScript guidance for any `.ts` or `.tsx` edit.                                                |
| `/pstack:figure-it-out`                      | [pstack](/reference/plugins/pstack.md)           | Design an auditable playbook when no bundled one fits.                                           |
| `/pstack:show-me-your-work`                  | [pstack](/reference/plugins/pstack.md)           | Log each decision of long work to a TSV.                                                         |
| `/pstack:create-verification-skill`          | [pstack](/reference/plugins/pstack.md)           | Generate a project skill that drives the app as a user does.                                     |
| `/pstack:maintain-verification-skill`        | [pstack](/reference/plugins/pstack.md)           | Keep that verification skill in line with the app.                                               |
| `/pstack:create-formal-verification-skill`   | [pstack](/reference/plugins/pstack.md)           | Generate a project skill that formally verifies the riskiest code.                               |
| `/pstack:maintain-formal-verification-skill` | [pstack](/reference/plugins/pstack.md)           | Keep that formal verification in line with the code.                                             |
| `/pstack:statechart`                         | [pstack](/reference/plugins/pstack.md)           | Check a TLA+ model and draw it as a Mermaid statechart.                                          |
| `/pstack:unslop`                             | [pstack](/reference/plugins/pstack.md)           | Cut AI tells from writing.                                                                       |
| `/pstack:bro`                                | [pstack](/reference/plugins/pstack.md)           | Restate the last message in plain language.                                                      |
| `/pstack:technical-writing`                  | [pstack](/reference/plugins/pstack.md)           | Standard for docs, RFCs, READMEs and PR text.                                                    |
| `/pstack:principle-*`                        | [pstack](/reference/plugins/pstack.md)           | 24 one-rule skills, such as `principle-fix-root-causes` and `principle-subtract-before-you-add`. |
