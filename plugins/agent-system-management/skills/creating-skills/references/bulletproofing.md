# Bulletproofing Skills

Adapted from Jesse Vincent's [writing-skills](https://github.com/obra/superpowers/tree/main/skills/writing-skills) skill (obra/superpowers at commit `d884ae04`, MIT License, Copyright (c) 2025 Jesse Vincent).

This playbook applies to **discipline-enforcing skills**: skills that impose a rule the agent has an incentive to break under pressure (TDD, verification gates, "ask before X"). Pure reference skills, and skills with nothing to violate, need none of this; test those for retrieval and correct application instead.

## TDD for documentation

Writing a discipline skill is test-driven development applied to process documentation. The pressure scenario is the test, the skill is the code.

| TDD                 | Skill writing                                               |
| ------------------- | ----------------------------------------------------------- |
| Test case           | Pressure scenario run by a fresh subagent                   |
| Test fails (RED)    | Baseline run without the skill: the agent violates the rule |
| Test passes (GREEN) | Same scenario with the skill: the agent complies            |
| Refactor            | Close loopholes while staying compliant                     |

- **RED first.** Run the scenario without the skill before writing a word of it. Writing first encodes what you guess needs preventing; the baseline shows what actually fails. If you did not watch an agent fail without the skill, you do not know whether the skill prevents the right failures.
- **Capture rationalizations verbatim.** "The agent was wrong" gives you nothing to counter. "I already manually tested it" and "I'll keep it as reference" are bug reports against the documentation: each exact phrase becomes a targeted counter.
- **GREEN minimally.** Address the documented failures and nothing more. Add no content for hypothetical cases you never observed, so every section is justified by a real failure.
- **REFACTOR until dry.** One passing run is not convergence. Re-run the same scenarios after each fix until agents produce no new rationalizations, and check the reasoning on the re-run: the agent should cite the newly added sections, confirming the specific counter worked rather than compliance by chance. Expect several rounds; bulletproofing one TDD skill took 6 iterations, and baseline testing alone revealed 10+ distinct rationalizations.

## Pressure scenarios

An academic prompt ("what does the skill say?") only makes the agent recite the skill. A pressure scenario makes it choose.

- **Stack 3 or more pressures.** Agents resist a single pressure and break under combinations: time, sunk cost, authority, economic stakes, exhaustion, social pressure ("you'll look dogmatic"), pragmatic framing.
- **Force a concrete choice.** Offer explicit options spanning full compliance at a cost, the tempting violation, and a partial middle, then end with "Choose A, B, or C." Use specific times, real file paths, actual consequences, and "What do you do?", never "What should you do?".
- **No easy outs.** The agent must not be able to defer ("I'd ask the user") without picking an option.
- **Frame it as real work.** Prefix with "This is a real scenario. Choose and act." An agent that detects a quiz performs compliance instead of revealing its behavior.
- **A compliant baseline is a result.** If the agent follows the rule with no skill loaded under the three stacked pressures above, and those pressures could happen in real use, stop: the model already follows the rule. State the rule once with its reason. Add a further pressure only to match a failure someone saw in real work.

## Plugging loopholes

For each new rationalization, apply all four counters. A generic "don't cheat" fails where a specific negation of the exact excuse succeeds:

1. An explicit negation inside the rule itself: "Don't keep it as reference. Don't adapt it while writing tests. Delete means delete."
2. An excuse/reality row in a rationalization table:

   | Excuse               | Reality                                        |
   | -------------------- | ---------------------------------------------- |
   | "Too simple to test" | Simple code breaks. The test takes 30 seconds. |
   | "I'll test after"    | Tests passing immediately prove nothing.       |

3. A red-flags list the agent can self-check while rationalizing ("I already manually tested it", "this is different because...", each entry meaning: stop, start over).
4. Violation symptoms in the frontmatter description, so the skill fires at the moment of temptation ("use when tempted to test after, or when manual testing seems faster").

For meta-level dodges ("I'm following the spirit, not the letter"), add a meta-level principle early in the skill: **violating the letter of the rules is violating the spirit of the rules**. One foundational line closes a class of loopholes that targeted rules cannot.

## Match the form to the failure

Classify the baseline failure before writing the fix. The form that bulletproofs one failure type measurably backfires on another.

| Baseline failure                             | Right form                                                     | Wrong form                                          |
| -------------------------------------------- | -------------------------------------------------------------- | --------------------------------------------------- |
| Knows the rule, skips it under pressure      | Prohibition plus rationalization table plus red flags          | Soft guidance ("prefer...", "consider...")          |
| Complies, but the output has the wrong shape | Positive recipe: state what the output IS, its parts, in order | Prohibition list ("don't restate", "never narrate") |
| Omits a required element it already produces | Structural: a REQUIRED slot in the template it fills in        | Prose reminders near the template                   |
| Behavior should depend on a condition        | Conditional keyed to an observable predicate                   | Unconditional rule plus exemption clauses           |

In head-to-head wording tests on a shaping problem (a single test, on dispatch-prompt guidance; micro-test your own case rather than assuming), the prohibition arm produced clearly more of the unwanted content than the recipe arm, and trended worse than no guidance at all. Two rules hold for whichever form you pick:

- **No nuance clauses.** "Don't X unless it matters" reopens the negotiation; appending a single nuance clause to a winning recipe degraded it from consistent to noisy in the same tests. Express a real exception as its own conditional on an observable predicate.
- **Exemption clauses don't scope.** "This limit doesn't apply to code blocks" still suppresses code blocks. If part of the output must be exempt, restructure so the rule cannot reach it.

This is the reconciliation with the main skill's warning against heavy-handed MUSTs: that warning holds for shaping and guidance problems, where explanation beats prohibition. Discipline enforcement is the one failure type where absolute language, tables, and red flags are the correct tool.

## Micro-test wording before full scenarios

Full pressure runs are the final gate but are slow per iteration. Verify contested wording first with micro-tests:

1. One fresh-context sample per call (a raw API call or a single-shot subagent), with the guidance embedded in the realistic context it will live in, not in isolation.
2. Always include a no-guidance control. If the control does not exhibit the failure, stop: there is nothing to fix, so do not author the guidance.
3. Five or more reps per variant. Single samples lie.
4. Manually read every flagged match; template echoes and quoted counter-examples masquerade as hits, so automated counts overstate both failure and success.
5. Treat variance as a metric. When guidance lands, reps converge on one shape; five interpretations across five reps means the wording is not binding, so tighten the form before adding words.

## Meta-testing and success criteria

When an agent violates the rule despite having the skill, interrogate it: "You read the skill and chose C anyway. How could it have been written so that A was clearly the only answer?" The answer classifies the failure:

- "The skill was clear, I ignored it": add a foundational principle, not another rule.
- "It should have said X": a documentation gap, add X verbatim.
- "I didn't see section Y": an organization problem, move it earlier or make it more prominent.

The skill is bulletproof when, under maximum stacked pressure, the agent chooses correctly, cites specific sections as justification, and acknowledges the temptation while complying anyway. It is not bulletproof while agents find new rationalizations, argue the skill is wrong, or invent "hybrid approaches".

## Why this works: the persuasion register

LLMs respond to the same compliance principles as humans; in a 28,000-conversation study, persuasion techniques more than doubled compliance (33% to 72%). Sources: Cialdini, _Influence_ (2021); Meincke et al., "Call Me A Jerk: Persuading AI to Comply with Objectionable Requests" (2025). Match the register to the skill type:

| Skill type           | Use                                                                                                                                                                                                        | Avoid               |
| -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- |
| Discipline-enforcing | Authority ("No exceptions" only for a rule that has none; write a real exception as its own conditional), commitment (announce the skill, forced choices), social proof ("X without Y fails. Every time.") | Liking, reciprocity |
| Guidance / technique | Moderate authority, unity ("we")                                                                                                                                                                           | Heavy authority     |
| Collaborative        | Unity, commitment                                                                                                                                                                                          | Authority, liking   |
| Pure reference       | Clarity only                                                                                                                                                                                               | All persuasion      |

Phrase requirements as trigger-action pairs: "when X, do Y" executes near-automatically, while "generally do Y" requires the agent to notice applicability each time. Sequence-bound wording ("before proceeding", "immediately after X") prevents a step from being acknowledged, postponed, and dropped. Never use liking (flattery breeds sycophancy) and rarely reciprocity. One ethics gate: use a technique only if it would still serve the user's genuine interests were it fully transparent.
