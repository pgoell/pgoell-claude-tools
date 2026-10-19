---
type: llm
---

The user pastes three short study abstracts on vitamin D and sleep and asks for them to be ranked by the strength of their study design, in a few lines, using only the given text. The text is in the prompt, so this is a short judgment, not a literature review.
PASS if the response ranks B (randomized, double-blind, placebo-controlled trial) first, A (prospective cohort) second and C (case series) third, in a few lines, with at most a short reason per study. A brief note on a limit of each design also PASSES. FAIL if the response plans a multi-step investigation, looks for or cites other studies, writes or offers a long report, spawns subagents, asks clarifying questions about scope or audience instead of answering, or gives a different order.
