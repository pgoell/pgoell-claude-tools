# Perfecting the Deck

How each round of the perfecting loop runs. The skill's "Perfecting the deck" section says when the loop starts and when it stops; read this file before round 1. Paths are relative to the skill's directory.

## Convergence rules

Three rules keep the loop convergent rather than oscillating:

- **Judges cite the constitution, never taste.** A finding without a rule citation is not a finding.
- **Fresh judges every round.** A judge subagent is never reused and never told which round it is. The fixer (the main session) never judges; judges never fix.
- **The ledger ratchets.** Findings rejected by verification are recorded; an identical finding in a later round is auto-dismissed without re-judging. The finding space only shrinks.

## The constitution

The constitution is `deck-standards.md` next to the deck HTML. If it does not exist, copy the bundled default from `references/deck-standards-default.md` there, tell the user, and invite them to edit it; the copy, not the bundled file, is what judges receive. The active preset's `guidelines.md` and `language.md` join the constitution when present. Before round 1, fill the constitution's deck brief (audience, goal, time budget, constraints); ask the user if you cannot infer it. The loop edits the deck, so commit or stash first; one commit per round keeps every round diffable.

## One round

Each round, in a `.deck-review/` directory next to the deck:

1. **Measure.** Run hard gates H1 to H9 from `references/hard-gates.md` (clipped text, overlap, broken assets and fonts, console errors, banned characters, contrast, minimum type size, copy lint, layout geometry) and capture one full-size screenshot per slide. A hard-gate failure is a fix item by definition, no judging involved.
2. **Review.** Dispatch one fresh judge subagent per soft dimension (narrative, clarity, visual, delivery), each given the screenshots first, then the constitution (including the V rules and flaw taxonomy), the deck source, and the probe notes, nothing else. Judges answer one yes/no item per rule per slide and never score overall; when a fix must be compared with the version before it, use the pairwise prompt with the order swapped.
3. **Verify.** Every finding faces an adversarial verifier prompted to refute it. Refuted findings die into the ledger; blockers, and all findings in strict mode, get a three-verifier majority.
4. **Fix.** The main session applies the smallest change that resolves each confirmed finding, hard-gate failures first. Never batch a speculative redesign into a fix round.
5. **Repeat** from step 1 until the convergence rule terminates the loop.

Prompts, schemas, the ledger format, and a Workflow script template for one round live in `references/review-loop.md`; read it before dispatching judges. Severity runs blocker, major, minor, nit; the default threshold is minor (nits are reported but do not block convergence), and strict mode (the user says "strict" or "no nits") drops the threshold to nit with three-verifier majorities throughout.

## The report

Keep `report.md` in the run directory updated every round: findings raised, verified, rejected, auto-dismissed, fixed, plus hard-gate status and the final verdict with its evidence ("rounds 4 and 5 dry, all gates green"). Never claim the deck is done without the dry-round evidence.
