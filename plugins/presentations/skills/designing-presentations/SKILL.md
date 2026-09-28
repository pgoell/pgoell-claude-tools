---
name: designing-presentations
description: Use when the user wants to design the content of a slide presentation, from audience brief through critiqued storyboard, before any slide is rendered. Produces a markdown deck.md with structured per-slide front-matter. Triggers on requests to plan a deck's storyline, storyboard a presentation, work out key messages, or audit the content of an existing deck.md. For rendering a deck.md as a styled HTML deck, see the creating-presentations skill.
---

# Designing Presentations

End-to-end content design for slide decks. Five sequential phases produce: an audience brief, a message architecture, a storyboard chosen from competing storylines, per-slide drafts, and a critique report. The deliverable is a single `deck.md` file with YAML front-matter per slide. This skill stops at `deck.md`; rendering, styling, and presenting are the deck builder's job.

## When to Use

Use this skill when the user wants to plan or refine the _content_ of a slide deck: who the audience is, what message moves them, how to order the slides, what each slide should say and show, what speaker notes back it up, and whether the result will land. Content design pays for itself before rendering: a storyline problem caught here costs one markdown edit, the same problem caught in a rendered deck costs a review round.

Two entry modes:

- **Design mode** (default): runs all five phases against a fresh idea. Output dir contains five named artifacts.
- **Audit mode**: consumes an existing `deck.md` and runs only Phase 5 (heuristic audit plus three critic personas). Triggered when the user provides a path to an existing deck.

## Dependencies

Nothing to install: filesystem operations only. The skill reads templates from its own `references/` directory and writes phase artifacts to the working directory. No external services, no APIs, no rendering. The one capability worth checking before Phase 5 is subagent dispatch (the Agent tool) for the three critic personas; when subagents are unavailable, run each persona inline in sequence, loading its prompt from `references/critic-prompts.md` and appending its findings to `audit-report.md`.

## Workflow

Five phases, each writing its own artifact to the working directory. File presence determines state: a phase is complete iff its artifact file exists and is non-empty. The user may resume at any later phase if the upstream artifacts are present.

Working directory: a `<topic-slug>/` directory under the current project unless the user names one. The rendered HTML deck later lives in the same directory, so design artifacts and render stay together. The topic slug comes from the user's intake (Phase 1) and is kebab-cased.

### Step 1: Intake

**Goal:** establish who the audience is, what they must decide, and how the deck will be used.

**Inputs:** the user's request and material, `references/audience-brief-template.md`, `references/time-budget.md`.

**Process:** ask the user these questions one at a time, skipping any their material already answers:

1. Who is the audience? Role, seniority, prior knowledge, and their objections, strongest first.
2. What evidence would overcome the strongest objection?
3. What is at stake for them if they say no?
4. Genre and length: executive briefing, keynote, training, pitch, or technical talk; duration in minutes.
5. Deck mode: `presented`, `keynote`, `briefing`, or `reading`. It sets the word budget and notes density (`references/time-budget.md`).
6. Do you expect them to agree? This sets sequencing: direct (answer first) for agree or neutral, indirect (answer once the strongest objection is met) for skeptical or under-informed.
7. The governing idea: one sentence under 20 words, a point of view plus what is at stake.
8. The call to action: actor, action, timing, consequence of delay.
9. One emotional lever (hope, urgency, relief, adrenaline) and, optionally, a S.T.A.R. moment.

**Autonomous runs do not answer these from general knowledge.** Derive each field from the user's material only and mark it `sourced` or `assumed` (see the template). If the decision or the strongest objection is assumed, ask one question when a user is reachable; otherwise continue and list the assumptions on the title-only read-through in Step 3.

**Output:** `audience-brief.md`, filled in from the template. It doubles as the deck brief when the rendered deck later enters the perfecting loop, so the audience is named once and reused.

**Pass condition:** every field is populated and marked sourced or assumed, and the governing idea fits one sentence.

### Step 2: Message Architecture

**Goal:** turn the intake into an answer-first argument and a transformation arc.

**Inputs:** `audience-brief.md`, `references/message-architecture-template.md`.

**Process:**

1. Write the SCQA opener: Situation (stable context the audience already accepts), Complication (the tension), Question (the question the complication forces), Answer (the governing idea as resolution).
2. Build the answer-first pyramid: one governing idea, two to four MECE grouped reasons, evidence under each reason. Each reason must be a sentence that states a conclusion, not a topic noun.
3. Write the transformation arc: current state, insight, future state. The arc is what the audience moves from and to; without a delta, the deck is a report rather than a persuasion. The future state answers the stakes-if-no field; the insight is phrased for the emotional lever.
4. Restate the CTA from intake in operational terms: actor, action, timing, consequence.

**Output:** `message-architecture.md`.

**Pass condition:** the four artifacts (SCQA, pyramid, transformation arc, CTA) are present, the pyramid's reasons are stated as conclusions not topics, and every piece of evidence comes from the user's material. This file is the committed argument that Phase 5 judges critic findings against; the pyramid is the logic, not the slide order.

### Step 3: Storyboard

**Goal:** choose a storyline from competing candidates, then give each slide a slide_type, a sentence headline, and a visual brief naming its proof object.

**Inputs:** `audience-brief.md`, `message-architecture.md`, `references/storyboard-template.md`, `references/slide-type-catalog.md`, `references/time-budget.md`, the active preset's `language.md`.

**Process** (details and a worked example in `references/storyboard-template.md`):

1. Read the slide-count band for the genre and duration from `references/time-budget.md` (a `reading` deck has none).
2. Draft two or three competing storylines, titles only, each a different shape: answer-first, indirect, what is / what could be. Include the shape that matches the brief's sequencing. Build them from the audience brief (strongest objection, its evidence, stakes if no), not from the order of the source material.
3. Pick one. The user picks when present; in autonomous runs compare two at a time with the order swapped, and break a disagreement with the brief's sequencing. Record the choice.
4. Add structure slides only by length: no Agenda or SectionDivider under 15 body slides (tunable defaults in the template). A direct storyline may carry an exec summary at slide 2.
5. Check for a known preset. When the user names a preset or a specific layout, or exactly one preset is installed under `../../presets/` at the plugin root, list that preset's `slides/` gallery. A visual brief may pin a gallery layout by name; a pinned layout overrides the mapping in `references/slide-type-catalog.md`.
6. For each slide write: slide number, slide_type, the sentence headline, and a visual brief naming the proof object. Every content slide carries one (chart with insight, single number, highlighted bar, waterfall, table, process, 2x2, diagram, image, quote). Write headlines to the active preset's `language.md` (fall back to `../../presets/default/language.md`). Layouts that pair a short topic title with a subtitle render the headline as the subtitle.
7. Write the title-only read-through (three sentences) with the list of assumed fields, and show it to the user before Step 4.

**Output:** `storyboard.md`.

**Pass condition:** a choice record names the candidates and the pick; every slide has a sentence headline and a proof object; slide count falls within the band (or the user overrides); the body covers each reason from the pyramid; the read-through and assumptions list are written.

### Step 4: Slide Drafts

**Goal:** expand every slide in the storyboard to the full per-slide YAML front-matter schema plus an ASCII layout sketch.

**Inputs:** `storyboard.md`, `audience-brief.md`, `message-architecture.md`, `references/slide-brief-template.md`, `references/slide-type-catalog.md`, `references/time-budget.md`, the active preset's `language.md`.

**Process:** open `deck.md` with the deck header (`deck_mode`, `governing_idea`, `sequencing`, and the other optional keys in `references/slide-brief-template.md`). Then, for each slide in the storyboard, produce a `## Slide NN: <headline>` block followed by a fenced `yaml` block matching the schema in `references/slide-brief-template.md`. The schema's top-level keys are `slide_type`, an optional short `title` (the topic label, for layouts that pair a title with an action subtitle), `headline`, `visual`, `speaker_notes`, and optional `sources`. Below the YAML, include an ASCII layout sketch using only plain ASCII characters (`-`, `|`, `+`, no Unicode box drawing) so the storyboard reader sees the spatial intent without needing an HTML render.

Apply the assertion-evidence pattern: the slide states (headline) and shows (visual); the speaker explains (speaker_notes). Notes complement the slide and never repeat it: short cues for `presented`, `keynote`, and `briefing` decks (a few words, the key number, the transition), fuller prose only for `reading` decks, sized at about 130 spoken words a minute. Keep on-screen words inside the deck mode's budget. Never add a fact, figure, name, or arithmetic that is not in the user's material.

**Output:** `deck.md`.

**Pass condition:** every slide in the storyboard has a corresponding block in `deck.md`; every block contains all required YAML keys; ASCII layout sketches are present.

### Step 5: Checks and Critique

**Goal:** audit `deck.md` with checks that write their working down, then with critic personas bound to the committed argument, and either pass or surface remaining issues for user decision.

**Inputs:** all earlier artifacts, `references/audit-checklist.md`, `references/critic-prompts.md`.

**Process (in order):**

1. **Heuristic audit** (inline). Run every check in `references/audit-checklist.md`: form checks A to E, then written-output checks F to K (title-only read-through against the governing idea, specificity test on every headline, exec-summary mapping, recommendation position, document order when a source document was the input, and the copy lint by reference). Each written check puts its output in `audit-report.md` before it judges.

2. **Critic personas** (three subagents in parallel via the Agent tool; prompts in `references/critic-prompts.md`):
   - Audience critic: a sequential walkthrough as one audience member, noting where understanding breaks.
   - Argument critic: logical force, evidence sufficiency, objection preemption, close landing.
   - Visual critic: one focal point per slide, one chart one comparison, no read-aloud redundancy.

3. **Judge findings against `message-architecture.md`.** Accept a finding that serves the committed argument; reject one that would change the governing idea, drop a reason, or soften the CTA, and surface it to the user if it shows the architecture itself is wrong. Mark each finding accepted or rejected in `audit-report.md`.

4. **Gate.** If any accepted CRITICAL findings remain, fix and re-dispatch once more (two iterations total). After two iterations, present the remaining CRITICAL issues to the user and ask whether to mark the deck ready with known issues, pause for manual intervention, or cancel.

**Output:** `audit-report.md`.

**Pass condition:** zero accepted CRITICAL findings, or explicit user decision to proceed with known issues.

## Audit Mode

Triggered when the user provides a path to an existing `deck.md` instead of a fresh request. The skill skips Phases 1 to 4 and runs Phase 5 directly against the input deck. Output `audit-report.md` is written next to the input deck unless the user supplies an output path.

Audit mode reviews content in markdown, and that is its boundary: it judges what the deck says. What a rendered deck looks like (overflow, contrast, alignment, consistency across slides) is the deck builder's perfecting loop, which works from screenshots. Run content audit before rendering; run the perfecting loop after.

Audit mode is markdown-only. If the user asks to audit a PowerPoint, Keynote, or Google Slides export, ask them to paste or convert the content into a `deck.md` first. Binary slide-format import is out of scope.

Audit mode skips the upstream artifacts (`audience-brief.md`, `message-architecture.md`, `storyboard.md`) which the critic personas would normally read. In their absence, the critics work from `deck.md` alone and flag any missing context they need; the user may then provide a one-paragraph audience and intent summary and request a re-run. Without `message-architecture.md`, the checks and the findings judgement use the deck header's `governing_idea` (or, failing that, the Title slide's headline) as the committed claim. A `deck.md` without a header is treated as `deck_mode: presented`, and the report says so.

## State and Resume

File-presence rule: a phase is complete iff its named artifact file exists and is non-empty. The artifact file names are `audience-brief.md`, `message-architecture.md`, `storyboard.md`, `deck.md`, `audit-report.md`.

On re-invocation, scan the working directory and report the latest completed phase to the user. Offer two options:

- Resume at the next phase, treating earlier artifacts as authoritative.
- Restart a specific earlier phase (which invalidates all later artifacts and asks the user to delete them or move them to an archive subdir).

Never silently overwrite a later artifact when restarting an earlier phase.

## Output Format

Format: **markdown only**. There is no HTML output mode for this skill; rendering is the deck builder's job, and `deck.md` is the hand-off contract it consumes as the source brief. The full per-slide YAML schema is documented in `references/slide-brief-template.md`. The content-side `slide_type` enum is intentionally distinct from the deck builder's rendering-side slide-type catalog; the mapping is documented in `references/slide-type-catalog.md` as a recommendation, not a constraint.

## Edge Cases

- **Missing prerequisite artifact on phase jump.** If the user invokes Phase 4 and `storyboard.md` is missing, ask whether to (a) run Phase 3 first, (b) accept a degraded run where Phase 4 reads the message architecture directly without a storyboard, or (c) cancel.
- **Audit mode against a deck without YAML front-matter.** Real-world `deck.md` inputs are usually prose-outline markdown (one `## Slide N: <title>` per slide with bullet body) rather than the skill's per-slide YAML schema. When the input lacks the YAML schema, audit mode runs in **advisory mode**: the heuristic audit walks each check against the visible content as best it can (treating slide headings as `headline` values, bullets as implied body, and flagging the absence of every other required key as a structural finding), and the critic personas are **not** dispatched because they need the structural fields to operate reliably. The audit-report's "Recommended next steps" then prominently recommends reformatting the deck into the schema before a full Phase 5 dispatch. If the input _is_ in YAML schema but has missing required keys per slide, that is a true malformation: the heuristic audit reports the missing keys and stops before dispatching critics. The user fixes the structure and re-runs.
- **Critic gate fails twice.** Present remaining CRITICAL findings to the user; ask whether to mark ready with known issues, pause, or cancel.
- **Slide count band breached deliberately.** The audit checklist flags the breach; if the user accepts (for example a deliberately dense training deck), record the override in `audit-report.md` under a "User overrides" heading so reviewers can see the deviation is intentional.
- **Governing-idea sentence too long.** If the Phase 1 governing idea is longer than 20 words, ask the user to shorten before proceeding; long governing ideas almost always indicate the audience or scope is muddled.
- **Genre mismatch.** If genre and length combine implausibly (for example a 5-minute training session), surface the mismatch at Phase 1 and ask whether the user meant a pitch or a quick demo.
- **Dash discipline.** This skill body, the bundled references, and every artifact the skill writes contain no U+2014 (em-dash) or U+2013 (en-dash) characters; the deck builder's typography lint enforces the same rule on rendered decks, so copy written here survives rendering unchanged.

## Key Principles

- One message per slide. If a slide is making two points, split it into two slides.
- Nothing invented. Every fact, figure, name, and derived number on a slide or in the notes comes from the user's material; a gap is raised, not filled.
- Real audience inputs. Autonomous runs mark each intake field sourced or assumed, and show the assumptions before rendering.
- Sentence headlines, not topic nouns, and specific ones: a headline names a number, actor, or comparison from the material and would not fit an unrelated deck. "Churn rose after response times crossed 12 hours" beats "Churn trends". Layouts that pair a title with a subtitle put the short topic label in the title and the sentence, the action title, in the subtitle; the takeaway obligation does not disappear, it just has a surface.
- The slide states and shows; the speaker explains and connects. Reading slide text aloud wastes the spoken channel and increases cognitive load (Mayer redundancy principle).
- Audience first. The deck is a means to move someone from one state to another; if the audience or the desired delta is unclear, the deck cannot succeed.
- Transformation contrast. Show current state versus future state explicitly; without a delta, the deck is a report not a persuasion.
- Assertion-evidence over bullet dumps. Garner and Alley's experimental evidence is that sentence-headline plus visual evidence produces stronger comprehension and delayed recall than topic-heading plus bullet stacks.
- One chart, one point, one intended comparison. Tufte, Few, Cleveland and McGill all converge on the same rule from different angles.
- Specific calls to action. Actor, action, timing, consequence. "Any questions?" is not a call to action; it is a stage exit.
