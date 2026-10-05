# Review: one round, reported to the owner

One round of notes on the draft. Every reviewer reports; none rewrites. The owner reads the notes and decides what to change.

Why no automatic redraft: model judges agree poorly with expert readers on prose, favor model-written text, and model revision pushes every writer's voice the same way even when told not to. The owner is the only reliable signal.

## Tell check (always, run it yourself)

Load `tells.md` and run its seven passes in order against the draft and your interview notes, the owner's documents, and the repository. The first three passes compare the draft with its sources, so run them yourself, not in a blind subagent. Flag; do not fix.

## Voice check (when a voice note exists)

Skip for PR text and reference docs, and when the voice note is empty. Read the voice note and list:

- **Matches:** up to three places where the draft follows a Keep entry, quoted.
- **Drift:** up to three places where it breaks a Keep or Avoid entry, quoted, with the entry they break.
- **Copied phrases:** any wording lifted from the owner's samples. Samples are evidence for the rules, not text to reuse.

Name the voice-note entries you checked against. Do not offer a rewrite.

## Optional reviewers

Offer these; run only the ones the owner wants. Run each in its own subagent where the host allows, and give it only the draft plus the prompt below. It must not see the interview, the outline, the voice note, or another reviewer's notes: blind review keeps the reviewers from converging on one opinion.

Each reviewer returns at most five points, each with the line it refers to and one sentence on why it matters. No verdicts, no scores, no rewritten passages.

### Asshole reader

> You are the sharpest hostile reader this piece will meet after it is published. Find every claim that is not earned: numbers without a source, one example generalized to "everyone", correlation presented as cause, vendor sources used without noting their interest, anecdote used as proof, the strongest objection left unanswered. Quote the line and write the exact pushback a reader would post. Do not flag claims the writer already hedged or framed as personal experience. Do not rewrite anything.

### Steel-man

> State the piece's thesis in one sentence. Then state the strongest opposing thesis, fairly, as someone who believes it would. Give the two or three best arguments for it, preferring ones that share the writer's evidence or values. For each, say whether the draft engages it, dismisses it without argument, or ignores it. Name the single most important unanswered counter and where in the draft it should be answered. Do not pad the list with weak objections. Do not rewrite anything.

### Clarity

> Ask of each paragraph: does this sentence say something specific, or does it only sound specific? Flag vague abstractions presented as substance ("many teams have found"), pronouns whose referent the reader must guess, abstract nouns standing in for the actual thing (ecosystem, landscape, framework), claims of size with no number ("a significant improvement"), passives that hide who did what, and adjective stacks that describe nothing. For each, say what is missing (which teams, what number, who acted). Do not supply the missing fact and do not rewrite.

### Fresh reader

> You know nothing about this topic beyond what the document says. Read it once as its intended reader: <reader, from the owner or the readers file entry>. Then answer: What is the main point, in one sentence? What should you do after reading? Where did you get lost or have to reread (quote the line)? What question did the document raise and never answer? Do not suggest wording.

Compare the fresh reader's one-sentence summary with the owner's throughline and show both to the owner. A mismatch is the most useful finding this step produces.

## Presenting the notes

Show the tell check first, then the voice check, then each reviewer's points under its name, unchanged. Then ask: "Which of these do you want to act on?" Apply only what the owner picks, in the way the owner describes. If the owner asks you to decide, give your recommendation and still wait for a yes.
