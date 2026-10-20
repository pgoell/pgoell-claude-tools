---
name: perfecting-presentations
description: Deprecated, superseded by presentations:creating-presentations, which folds this review loop in as an opt-in phase. Formerly used to review, audit, polish, or perfect an existing HTML slide deck through a strict convergence loop.
---

# Perfecting Presentations

> **Deprecated.** Superseded by `presentations:creating-presentations`, which carries this convergence loop as its "Perfecting the deck" phase. This copy is archived and no longer maintained.

A strict reviewer for HTML decks that does not stop at "looks good". The deck is done when fresh reviewers can no longer find anything that survives adversarial scrutiny against an explicit standard. This skill defines that standard (the constitution), the deterministic checks (hard gates), the review loop (judge, verify, fix), and the termination rule (dry rounds).

## When to use this skill

Reach for `perfecting-presentations` when a deck already exists and the user wants it reviewed, audited, polished, or "perfected". It pairs with `deprecated:crafting-presentations` decks (a `<deck-stage>` element with `<section>` slides) but the loop works for any HTML deck once you identify the slide container. It is not for designing content (use `deprecated:presentations`) or for first-pass rendering (use `deprecated:crafting-presentations`).

## Perfection as convergence

A single reviewer verdict is worthless as a termination condition: a self-graded loop collapses into early self-approval, and a "be very strict" reviewer never terminates and oscillates (round 3 undoes round 2). So this skill never asks "is the deck perfect?". It asks "did this round find anything new that survives verification?" and stops only when:

1. every hard gate passes, and
2. two consecutive review rounds produce zero verified findings at or above the severity threshold, and
3. the round cap (default 5) has not been hit. If it is hit, stop and report the remaining open findings honestly instead of looping forever.

Three rules keep the loop convergent rather than oscillating:

- **Judges cite the constitution, never taste.** A finding without a rule citation is not a finding.
- **Fresh judges every round.** A judge subagent is never reused and never told which round it is. The fixer (the main session) never judges; judges never fix.
- **The ledger ratchets.** Findings rejected by verification are recorded; an identical finding in a later round is auto-dismissed without re-judging. The finding space only shrinks.

## The constitution

Resolution order for the standards document:

1. `.workbench/deck-standards.md` in the project, if present.
2. Otherwise copy the bundled default `references/deck-standards-default.md` to `.workbench/deck-standards.md`, tell the user you did so, and invite them to edit it. The copy, not the bundled file, is what judges receive, so project edits stick.

Before the first round, fill in the constitution's `## Deck brief` section for this specific deck (audience, goal, time budget, constraints). Ask the user if you cannot infer it; a deck cannot be judged "right for the audience" without naming the audience.

## The loop

Working directory for a run: `.workbench/reviews/<deck-slug>/` (screenshots per round, `ledger.json`, `report.md`).

0. **Setup.** Resolve the constitution, fill the deck brief, locate the deck HTML, serve it over HTTP.
1. **Measure (hard gates).** Run the deterministic probes from `references/hard-gates.md`: overflow, overlap, broken images, console errors, banned characters, contrast, font loading. Capture one screenshot per slide. No LLM judgment is involved; a hard-gate failure is a fix item by definition.
2. **Review.** Dispatch one fresh judge subagent per soft dimension (narrative, clarity, visual, delivery). Each judge gets the constitution, the deck source, the slide screenshots, and nothing else. Judges return structured findings: rule ID, slide, evidence, severity. See `references/review-loop.md` for the prompts and schema.
3. **Verify.** Every finding faces an adversarial verifier prompted to refute it against the constitution and the screenshot evidence. Refuted findings die and enter the ledger as rejected. Blockers, and all findings in strict mode, get a three-verifier majority instead of a single verifier.
4. **Fix.** The main session applies the smallest change that resolves each confirmed finding, hard-gate failures first. Never batch a speculative redesign into a fix round.
5. **Re-measure and repeat.** Back to step 1. Terminate per the convergence rule above.

## Severity and strictness

`blocker` (deck cannot be presented: broken layout, wrong facts, unreadable text), `major` (audience-visible flaw: cramped slide, headline that buries the takeaway), `minor` (polish: inconsistent spacing, weak phrasing), `nit` (taste within the rules). The default threshold is `minor`: nits are reported in the final summary but do not block convergence. In strict mode (user says "perfect in all senses", "strict", "no nits") the threshold drops to `nit` and verification uses three-verifier majorities throughout.

## Orchestration

The loop driver is the main session; judging and verifying fan out to subagents. With the Workflow tool available, run one Workflow invocation per round using the script template in `references/review-loop.md` (judges in parallel, each finding piped straight into verification, ledger passed via `args`). Without it, dispatch judge and verifier subagents with the Agent tool, judges in parallel, then verifiers. Either way the mandatory property is context isolation: no judge or verifier ever sees the conversation, prior rounds, or the fixer's reasoning.

## Report

`report.md` in the run directory, updated every round: a per-round table (findings raised, verified, rejected by panel, auto-dismissed by ledger, fixed), the hard-gate status, and the final verdict with the evidence for it ("rounds 4 and 5 dry, all gates green" or "round cap hit, 2 open majors listed below"). Surface the report path and the verdict to the user; never claim the deck is done without the dry-round evidence.

## Cross-references

- `deprecated:crafting-presentations` renders the deck this skill perfects and documents the `<deck-stage>` engine and slide-type catalog.
- `deprecated:presentations` designs the content; if review keeps finding narrative blockers, the deck likely needs a content pass there, not more polish rounds.
- `deprecated:crafting-design-systems` owns brand theming; constitution rules about brand assets should defer to the active design system.
- `deprecated:verification-before-completion` applies to the final claim: the dry-round evidence is the verification.

## Caveats

- Screenshot judges need vision via the Read tool on PNG files; capture screenshots to disk first, then pass paths.
- Decks that load webfonts or icons from CDNs render differently offline; run hard gates online, or vendor the assets first, otherwise font fallbacks produce false overflow findings.
- The loop edits the deck; commit or stash before round 1 so every round is diffable and reversible.
