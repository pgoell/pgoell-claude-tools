# Writing Great Skills

Adapted from Matt Pocock's [writing-great-skills](https://github.com/mattpocock/skills/tree/main/skills/productivity/writing-great-skills) skill (mattpocock/skills at commit `391a2701`, MIT License, Copyright (c) 2026 Matt Pocock).

A skill exists to wrangle determinism out of a stochastic system. **Predictability** is the root virtue: the agent takes the same _process_ every run, not the same output. A brainstorming skill should predictably diverge; its tokens vary, its behaviour doesn't. Every lever below serves predictability, and cost and maintainability are symptoms of it, not rivals.

## Invocation

How a skill is reached, and the two loads you pay for the choice.

- A **model-invoked** skill keeps a `description`, so the agent can fire it autonomously and other skills can reach it. The human can normally type its name too. It pays **context load**: the description sits in the context window every turn, spending tokens and attention. Mechanics: omit `disable-model-invocation` and write a model-facing description with the trigger phrasing the agent should match.
- A **user-invoked** skill strips the description from the agent's reach. Only the human, typing its name, can invoke it, and no other skill can. Zero context load, but it spends **cognitive load**: the human is the index that must remember the skill exists. That cost is not something to minimise away; it is the price of human agency, spent where human judgement matters. Mechanics: set `disable-model-invocation: true`; the description becomes human-facing, a one-line summary with trigger lists stripped.

A third state exists in Claude Code: `user-invocable: false` keeps model invocation but removes the human's menu entry. Same context load, zero human reach, zero cognitive load, because there is nothing for the human to remember. Use it for background knowledge that is not actionable as a command (mechanics and the full state table: platform-mechanics.md).

Default to model invocation, and pay for it with a short description. A user-invoked skill is out of reach for the agent, for other skills and for a successor session that takes over the work, which tends to show only when a hand-off needs it. Make a skill user-invoked only when the user asks for it.

When user-invoked skills multiply past what the human can remember, the cure is a **router skill**: one user-invoked skill that names the others and when to reach for each. It can only hint, never fire them, since user-invoked skills have no description for anything but the human to reach.

## Writing the description

A model-invoked **description** does two jobs: state what the skill is, and list the **branches** that should trigger it. Every word increases context load, so a description earns even harder pruning than the body:

- **Front-load the skill's leading word.** The description is where it does its invocation work, and when the same word lives in your prompts, docs, and codebase, the agent links that shared language to the skill and fires it more reliably.
- **One trigger per branch.** Synonyms that rename a single branch are duplication ("build features using TDD ... asks for test-first development" is one branch written twice). Collapse them; keep only genuinely distinct branches.
- **Cut identity that's already in the body.** Keep the description to triggers, plus any "when another skill needs..." reach clause.

## Information hierarchy

A skill is built from two content types that mix freely:

- **Steps**: the ordered actions the agent performs. When present, they are the primary tier, the part that earns its place in SKILL.md. Every step ends on a completion criterion.
- **Reference**: material consulted on demand (definitions, facts, parameters, examples, conditional instructions). A skill can be all steps, all reference, or both. A legitimately flat peer-set, such as every rule of a review on one rung, is a fine arrangement, not a smell.

The **information hierarchy** ranks content by how immediately the agent needs it:

1. In-skill steps, in SKILL.md.
2. In-skill reference, in SKILL.md.
3. Disclosed reference, pushed into a separate file and reached through a context pointer, loaded only when the pointer fires. This rung spans sibling files inside the skill folder through fully **external reference** that lives outside the skill system, which any skill can point at (and the only shared home two user-invoked skills can use, since neither can fire the other).

Push too little down and the top bloats; push too much and you hide material the agent actually needs. That tension is the whole decision. When a skill has steps, in-file reference that should have been disclosed buries them and turns attending to them into a coin flip: a variance lever, not just a legibility one.

**Progressive disclosure** is the move down the ladder, out of SKILL.md into a linked file, so the top stays legible. It is licensed by **branching**: each distinct way a skill gets used is a branch, and different runs take different paths. Inline what every branch needs; push behind a pointer what only some branches reach.

A **context pointer** is a reference held in context that names out-of-context material and encodes the condition for reaching it. The description is the top-level context pointer; pointers to disclosed files are the same object one level down. The pointer's wording, not its target, decides when the agent reaches the material and how reliably. A must-have target behind a weakly worded pointer is a variance bug: sharpen the wording first, and inline the material only if that fails.

**Co-location** decides what sits beside a piece once the ladder decides how far down it sits: keep a concept's definition, rules, and caveats under one heading rather than scattered, so reading one part brings its neighbours with it. A skill should read like documentation written for the agent; grouped material reads that way, scattered material does not.

## Completion criteria and legwork

A **completion criterion** is the condition that tells the agent a unit of work is done. Two properties make it a lever:

- **Clarity**: can the agent tell done from not-done? A vague bound ("understanding reached") lets the agent declare done and slip to the next step.
- **Demand**: how much it requires. "Every modified model accounted for" forces thorough work where "produce a change list" does not. Demand is not step-bound; it binds flat reference too ("every rule applied"), which is how a skill with no steps still carries an exhaustiveness bar.

The strongest criteria are both checkable and exhaustive.

**Legwork** is the digging the agent does within a single step: reading files, exploring the codebase, hunting down what it needs rather than offloading to the user. It is never written as its own step; it is latent in the wording. Raise it with a leading word (_relentless_) or a demanding completion criterion. It goes thin when that demand is missing or when premature completion cuts the step short.

## When to split

**Granularity** is how finely you divide skills, and each cut spends one of the two loads, so split only when the cut earns it:

- **By invocation**: split off a model-invoked skill when you have a distinct leading word that should trigger it on its own, or another skill must reach it. You pay context load for the new always-loaded description, so that independent reach has to be worth it.
- **By sequence**: split a run of steps when the steps still ahead (a step's **post-completion steps**) tempt the agent to rush the one in front of it. Keeping them out of view encourages more legwork on the current task. Hiding only works across a real context boundary (a user-invoked hand-off or a subagent dispatch); an inline call leaves the later steps in context and clears nothing. Beware the reverse: merging sequences exposes each step's post-completion steps to what follows.

## Leading words

A **leading word** is a compact concept already living in the model's pretraining that the agent thinks with while running the skill (examples: _lesson_, _fog of war_, _tracer bullets_). Repeated as a token, never as a sentence, it accumulates a distributed definition and anchors a whole region of behaviour in the fewest tokens, by recruiting priors the model already holds. Coining your own word works if you define it clearly, but a made-up word recruits no priors; you pay in definition tokens what a pretrained word gives free.

It serves predictability twice. In the body it anchors execution: the agent reaches for the same behaviour every time the word appears. In the description it anchors invocation.

Hunt for opportunities to refactor skills onto leading words. A triad spelled out at three sites, or a description spending a sentence to gesture at one idea, is a passage begging to collapse into a single token:

- "fast, deterministic, low-overhead" collapses into _tight_ (a tight loop).
- "a loop you believe in" collapses into _red_ (the loop goes red on the bug, or it doesn't), converting a fuzzy gate into a binary observable state.

You win twice: fewer tokens, and a sharper hook for the agent to hang its thinking on. Assume every skill is carrying restatements that leading words retire.

## Pruning

- **Single source of truth**: each meaning lives in exactly one authoritative place, so changing the skill's behaviour is a one-place edit.
- **Relevance**: does the line still bear on what the skill does? A line loses relevance by never bearing on the task (mere exposition, or a branch that should be disclosed) or by going stale. Shorter skills are easier to keep relevant, because each line is cheaper to check.
- **The no-op test**: hunt no-ops sentence by sentence, not just line by line. For each sentence in isolation, ask whether it changes behaviour versus the model's default. When one fails, delete the whole sentence rather than trim words from it. Be aggressive; most prose that fails should go, not be rewritten. The test is model-relative: two people disagreeing about whether a line is a no-op disagree about the default, and settle it by running the skill, not by debate.

## Failure modes

Use these to diagnose issues with a skill.

- **Premature completion**: ending the current step before it is genuinely done, attention slipping to being done rather than to the work. A tug-of-war between visible post-completion steps (the pull forward) and the completion criterion's clarity (the resistance). Defence, in order: sharpen the completion criterion first (cheap, local); only if it is irreducibly fuzzy and you actually observe the rush, hide the later steps by splitting the sequence.
- **Duplication**: the same meaning in more than one place. Costs maintenance and tokens, and inflates a meaning's prominence past its real rank. The accidental inverse of a leading word, which repeats a token on purpose, never the meaning.
- **Sediment**: stale layers that settle because adding feels safe and removing feels risky. The default fate of any skill without a pruning discipline.
- **Sprawl**: a skill simply too long, even when every line is live and unique. Costs readability, maintainability, and tokens. The cure is the ladder: disclose reference behind pointers, and split by branch or sequence so each path carries only what it needs.
- **No-op**: a line the model already obeys by default, so you pay load to say nothing. A weak leading word (_be thorough_ when the agent is already thorough-ish) is a no-op; the fix is a stronger word (_relentless_), not a different technique.
- **Negation**: steering by prohibition backfires. "Don't think of an elephant" names the elephant and makes it more available, not less; the ban half-reads as an instruction to do the thing. Prompt the positive: state the target behaviour ("write one-line comments") so the banned one is never spoken. A prohibition earns its place only as a hard guardrail on behaviour you cannot phrase positively, and even then pair it with the positive target. Discipline-enforcing skills are the exception: when an agent knows a rule and skips it under pressure, explicit prohibitions, rationalization tables, and red flags are the correct form (see bulletproofing.md).
