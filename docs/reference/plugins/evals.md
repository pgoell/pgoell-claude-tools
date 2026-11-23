---
type: Reference
title: The evals plugin
description: Shreya Shankar and Hamel Husain's skills for building product evals, tracked from upstream.
tags: [plugin, evals, upstream, llm, evaluation]
status: stable
---

# evals

Skills that guide a coding agent through product evals for an LLM application: read traces and group what fails, write checks and judges for those failures, and test each judge against human labels. They are for evals of your own product, not for model benchmarks. Start with `/evals:evals-start`, which routes to the skill that fits. See the upstream [README](https://github.com/ai-evals-course/evals-skills#readme).

**Runtimes:** Claude Code, Codex

Not in Cursor: this marketplace's Cursor manifests are generated from local plugin directories, and evals has none here. See [Runtimes](/reference/runtimes.md).

**Source:** upstream, not vendored: tracks [ai-evals-course/evals-skills](https://github.com/ai-evals-course/evals-skills) `main` unpinned (Apache 2.0, by Shreya Shankar and Hamel Husain). Versions and release cadence are the upstream authors'.

**Setup:** None beyond install.

## Skills

| Invocation                       | What it does                                                                                                                |
| -------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `/evals:evals-start`             | Entry point. Routes an evals request to the skill that fits.                                                                |
| `/evals:eval-audit`              | Audits an existing eval pipeline and ranks its problems.                                                                    |
| `/evals:error-discovery`         | Builds a review app, picks varied traces, and groups your notes into failure modes.                                         |
| `/evals:generate-synthetic-data` | Creates varied synthetic test inputs from dimension tuples.                                                                 |
| `/evals:write-code-eval`         | Writes code checks for failure modes with objective rules.                                                                  |
| `/evals:write-judge-prompt`      | Designs an LLM judge for a criterion code cannot check.                                                                     |
| `/evals:validate-evaluator`      | Calibrates an LLM judge against human labels, with data splits, true positive and true negative rates, and bias correction. |
| `/evals:evaluate-rag`            | Evaluates retrieval and generation quality in a RAG pipeline.                                                               |
| `/evals:build-review-interface`  | Builds a browser interface for reviewing and labelling traces.                                                              |

The skill names are the same in Codex. The upstream README says the skills cover eval work that carries across projects, and leaves production monitoring, regression suites and cost out.
