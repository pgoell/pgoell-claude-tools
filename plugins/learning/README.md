# Learning

Adaptive teaching, concept rebuilding and practice with durable evidence of what the learner can explain and use. Kasten is optional; all three runtimes share the same skills.

## Skills

- `/learning:quizzing-the-session`: Build a problem/solution/impact checklist from the current session and recent git activity, then teach and quiz you to mastery. Also fits right before a PR or merge, to confirm you can represent the work in review.
- `/learning:quizzing-a-topic`: The same teaching engine pointed at any topic or theme you name.
- `/learning:surveying-blind-spots`: A pre-work blind-spot pass over a codebase area or field you do not know. Surfaces unknown unknowns, gotchas, and dead ends, then hands you rewritten prompts that bake in what it found. A briefing, not a quiz.
- `/learning:rebuilding-a-concept`: Learn a concept by rebuilding it from the problem that forced it, then breaking your version with counterexamples and repairing it. The textbook version comes last, as a comparison. Works for maths and for designs such as data models or architecture patterns.

- `/learning:practicing-a-topic`: Revisit prior learning with one adaptive problem at a time, unfamiliar cues, minimal hints and dated evidence of independent or assisted performance.

The two quizzing skills have the assistant assess what you already know, fill the gaps, and quiz you item by item: multiple choice via AskUserQuestion for the early rungs, with the correct option shuffled and hidden until you submit, and a last check where you explain the item in your own words, with no options. When you get stuck, you get the smallest hint that could help, not the answer; a full re-teach comes only after three hints fail or when you ask. An explicit stop saves open gaps rather than declaring mastery. Predictions precede explanations, and later recall is assessed separately from immediate performance.

## Persistent learning records

Teaching, rebuilding and practice share a portable markdown record of source claims, learner models, reasoning steps and observed attempts. Hints, answer exposure and uncertainty survive checkpoints and resume. Local records default to `${XDG_DATA_HOME:-$HOME/.local/share}/pgoell-learning/`, outside project git history. A known Kasten vault uses its own filing and conditional-write conventions instead.

See [Learn and practice with Kasten](#learn-and-practice-with-kasten) below for the workflow, current graph limits and runtime setup boundary. Kasten UI changes and automatic reminders are not included.

## Inspiration

These skills are an original adaptation, "stolen like an artist", of Thariq Shihipar's work: the two quizzing skills from his "Learn Quiz" gist (<https://gist.github.com/ThariqS/1389dcdff9eba4789887a2211370f06b>), and the blind-spot pass from the "find your unknowns" techniques in his AI Engineer talk on working with new model generations. No upstream text is vendored verbatim; the concepts are reimplemented in this repo's conventions.

`rebuilding-a-concept` draws on Otto Toeplitz's genetic method (1927) and Imre Lakatos's _Proofs and Refutations_ (1976), written in this repo's own words. Original work is MIT licensed.

The adaptive prediction, practice and reasoning-record design also draws on [Agent Harness for Learning Things](https://www.youtube.com/watch?v=nfTDljFG2g0). This is an original integration, not a port of that application or a claim of measured learning effectiveness.

## Learn and practice with Kasten

Install the learning plugin in your agent runtime. Kasten is optional: a local
coding host without a vault saves records under
`${XDG_DATA_HOME:-$HOME/.local/share}/pgoell-learning/`. Records do not go into
the code repository by default. On a host with no durable writer the lesson can
continue in chat, with persistence explicitly unavailable.

### Start from a source

In a Kasten chat pane whose Claude Code can load this plugin, or in a connected
agent host with Kasten tools, send:

```text
/learning:quizzing-a-topic Teach me the adaptive learning workflow from this source note:
00 Inbox/Agent Harness for Learning Things.md.
Focus on diagnosis, practice and evidence. Keep the record in this vault.
```

You can instead name a paper, repository file or a bounded concept. The skill reads relevant material,
probes your current understanding and proposes a short dependency plan. Explain
your reasoning briefly as you answer; confidence is optional. Predict before the
tutor explains, then check the reasoning on a new question.

The plugin does not install the Kasten service or chat runner. The runtime needs
either Kasten tools or its mounted vault. A tool connected in one host is not
automatically connected in the others. Installing the plugin in a local terminal
also does not prove that Kasten's separate Claude Code process can load it.

### Read the record

The skill reports the path after creating the note. A new record has a unique
session name; without a named destination Kasten's current agent filing rule is
used. The skill reads the vault's guide and ontology before writing, and uses
conditional writes when working through Kasten tools.

The record separates:

- Source-supported claims and their precise source locators.
- Your explanations, wrong models and corrections.
- Problems and attempts tied to stable claim IDs, including hints, answer
  exposure, optional confidence and the reason for the assessment.
- A checkpoint with open gaps and the next action.

An immediate correct explanation is evidence for that session. It does not mean
you will recall it later. A successful retry after a hint stays assisted, and
stopping leaves pending work incomplete. Earlier attempts are not rewritten to
match the final answer.

### Practice and resume

Name the saved record:

```text
/learning:practicing-a-topic Practice the claims in <saved-record-path>.
Use unfamiliar examples and check whether I can explain the reasoning.
```

The skill creates a new practice record linked to the original, asks one problem
at a time and varies cue familiarity or the number of combined ideas. It reads
the actual reference solution before grading and gives minimal hints if needed.
It can also use problems you supply. Without an earlier record it starts with
one diagnostic problem and does not invent prior progress.

To resume rather than start another session, say:

```text
Continue the unfinished practice session in <practice-record-path>.
```

The saved checkpoint and prior hints survive the resume. For later recall you
can ask for flashcards or an exam; the agent reads Kasten's current format guide
and writes the existing format. A review suggestion is not a reminder or a
background schedule.

### What the graph shows

Existing links to source and concept notes appear in Kasten's existing graph.
Typed relations follow the vault's ontology; proposed canonical concept edits
are separate from your session history. The learning record keeps prerequisite
dependencies separate from reasoning steps and performance evidence. Where two
premises are required together, an explicit reasoning step records that fact.

Kasten's current graph has one node per note. A claim ID or heading does not
create a proposition node. This plugin adds no new graph layout, assessment
overlay, confidence control or learning database. Proposition-level views and
assessment overlays would be a separate Kasten app change, derived from the
records rather than becoming their only store.

### Related

- [Learning plugin](../../docs/reference/plugins/learning.md): all five entry points
- [Skills at a glance](../../docs/reference/skills.md): the full marketplace
