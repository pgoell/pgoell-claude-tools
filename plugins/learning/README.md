# Learning

Skills that teach the human: Socratic teach-and-quiz loops that verify you deeply understand something, a pre-work blind-spot survey that maps what you do not know yet, and a rebuild-then-break loop for learning an idea from its origin.

## Skills

- `/learning:quizzing-the-session`: Build a problem/solution/impact checklist from the current session and recent git activity, then teach and quiz you to mastery. Also fits right before a PR or merge, to confirm you can represent the work in review.
- `/learning:quizzing-a-topic`: The same teaching engine pointed at any topic or theme you name.
- `/learning:surveying-blind-spots`: A pre-work blind-spot pass over a codebase area or field you do not know. Surfaces unknown unknowns, gotchas, and dead ends, then hands you rewritten prompts that bake in what it found. A briefing, not a quiz.
- `/learning:rebuilding-a-concept`: Learn a concept by rebuilding it from the problem that forced it, then breaking your version with counterexamples and repairing it. The textbook version comes last, as a comparison. Works for maths and for designs such as data models or architecture patterns.

The two quizzing skills have the assistant assess what you already know, fill the gaps, and quiz you item by item (multiple-choice via AskUserQuestion, with the correct option shuffled and hidden until you submit). The session never finishes until you have demonstrated you understand every item.

## Inspiration

These skills are an original adaptation, "stolen like an artist", of Thariq Shihipar's work: the two quizzing skills from his "Learn Quiz" gist (<https://gist.github.com/ThariqS/1389dcdff9eba4789887a2211370f06b>), and the blind-spot pass from the "find your unknowns" techniques in his AI Engineer talk on working with new model generations. No upstream text is vendored verbatim; the concepts are reimplemented in this repo's conventions.

`rebuilding-a-concept` draws on Otto Toeplitz's genetic method (1927) and Imre Lakatos's _Proofs and Refutations_ (1976), written in this repo's own words. Original work is MIT licensed.
