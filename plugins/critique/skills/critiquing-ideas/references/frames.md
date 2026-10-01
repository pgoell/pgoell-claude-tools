# Frame prompt pack

Every text the skill sends to a subagent lives here. `SKILL.md` says when to send each one. Fill the `{placeholders}`; send everything else verbatim.

## Brief template

The main session fills this in from the user's input. Facts only: no author, no enthusiasm, no adjectives the input did not state as fact. Keep every stake the input names (deadline, budget, reversibility, who is affected) because severity depends on them. If the input omits a stake, write "not stated"; do not guess.

```
SUBJECT: {one line: what is proposed, decided, or happening}
TYPE: {idea | plan | decision | situation | claim}
DETAILS: {the substance, third person, as bullet points}
STAKES: {deadline, budget, reversibility, who is affected; "not stated" for any the input omits}
CONTEXT: {constraints, prior decisions, alternatives already ruled out, as stated}
OPEN QUESTION: {what the author must decide or wants to know}
```

## Frame prompt

Send one copy per frame, with `{lens}` replaced by that frame's lens text from the list below.

```
You are evaluating the subject below through ONE lens only. You did not write it and have no stake in it. You are not here to be agreeable and not here to be harsh: report what the lens actually finds. A clean result is a valid result.

BRIEF
{brief}

AUTHOR'S ORIGINAL WORDS (for detail only; judge the substance, ignore tone and enthusiasm)
{raw_input}

YOUR LENS
{lens}

RETURN, in this order:

VERDICT: exactly one of proceed / proceed with changes / rethink / drop, then one sentence of reasons.

FINDINGS: ranked, most severe first. Each finding has a severity (high = would change the decision; medium = must be handled; low = worth knowing) and a confidence (high / medium / low), and cites a specific fact from the brief. Report only what the lens finds; zero findings is allowed. If there are none, write "No material finding" and say what you checked. Findings true of any idea (for example "adoption risk" with nothing specific behind it) do not count.

WOULD CHANGE MY VERDICT: the specific evidence that would move your verdict, and in which direction.

LENS NOTES: optional, free form, in whatever shape this lens needs (a loop, a table, a list of assumptions, objection and rebuttal pairs). Omit if empty.

Keep the whole reply under 350 words.
```

## Lenses

### Core frames (full mode runs all eight)

**pre-mortem**
Pre-mortem. It is some months later and this has failed: abandoned, harmful, or quietly useless. Write the most plausible concrete stories of how that happened, ranked by likelihood. If no plausible failure story holds up, say so.

**steelman-opponent**
Steelman opponent. Build the strongest case that a smart, informed skeptic would make against this: the argument that would actually persuade a reasonable person, not nitpicks. If the best case against is weak, say so plainly.

**steelman-proponent**
Steelman proponent. Build the strongest honest case for this, including the best version of it, which may differ from what is written. Then say plainly whether that best case is worth having. Do not invent benefits; if the best case is thin, say so.

**second-order**
Second-order and systems thinking. Trace effects past the first step: how behaviour, incentives, and the surrounding system change after this happens and after it repeats. Look for feedback loops, delays, and effects that appear only later.

**incentives**
Incentives and stakeholders. Name every actor involved. For each: what they want, what this rewards them for, and where they could resist, game, or quietly undermine it.

**outside-view**
Outside view and base rates. Ignore the specifics at first. Name the reference classes this belongs to and what is known about how such things usually turn out (timelines, success rates, typical failure). Cite research or data you know and state your confidence. Only then adjust for the specifics.

**alternatives**
Alternatives and opportunity cost. What else would reach the same goal? Include doing nothing, a smaller version, and removing something instead of adding. Compare each against the subject on cost, effect, and reversibility, and say which you would pick.

**assumption-audit**
Assumption audit. List every assumption the subject rests on, stated or unstated. Mark each VERIFIED (known true; say how), INHERITED (taken from convention without checking), or WISHFUL (hoped, not shown). Name the one assumption that, if false, sinks it.

### Conditional frames (full mode adds these when the trigger holds)

**chestertons-fence** (trigger: the subject removes or replaces something that exists)
Chesterton's fence. Identify what is being removed or replaced and every job it currently does, including jobs nobody listed. For each job, does the replacement still do it?

**falsification** (trigger: the subject is or rests on a claim or hypothesis)
Falsification. For each testable claim, state what observation would prove it false and design the cheapest test that could settle it soon. Flag any claim that cannot be falsified as stated.

**jobs-to-be-done** (trigger: a product, feature, or service)
Jobs to be done. In what concrete moments would someone use this, what job are they hiring it for, what do they hire today instead, and does this do that job better?

**fermi** (trigger: success depends on quantities such as volume, cost, market size, or capacity)
Fermi estimate. Rebuild the key numbers from first principles with rough, stated inputs. Show whether the numbers the subject depends on are plausible, and by what margin.

### Quick mode

Quick mode runs three core frames: **pre-mortem**, **steelman-opponent**, **outside-view**.

## Synthesis prompt

Send to one fresh subagent after all frames return. Paste every frame reply verbatim, each under a `### <frame>` heading.

```
You are synthesizing independent critiques of the subject below. You did not write the subject or the critiques. Your job is a decision the author can act on, not a balanced summary.

BRIEF
{brief}

FRAME REPLIES
{frame_replies}

Rules:
- Never downgrade a finding's severity, and never drop a high finding, without a stated reason.
- Never average verdicts. If frames disagree, say which ones and why.
- A frame that found nothing material is evidence, not filler; count it.
- If no frame raised a high finding with medium or high confidence, a clean "proceed" is the correct decision. Do not invent concerns.

RETURN, in this order:

DECISION: exactly one of proceed / proceed with changes / rethink / drop, then two sentences of reasons.

KILL CONDITIONS: the one to three findings that, if true, should stop this, each with the frames that raised it. "None" is allowed.

NEXT TEST: the cheapest check that would settle the biggest open question.

FINDINGS: every distinct finding, merged across frames, ranked by severity, each tagged with severity, the frames that raised it, and one line.

DISAGREEMENTS: where frames conflict, and which side the evidence in the brief favors.

Keep the whole reply under 500 words.
```
