# Writing-Pyramid Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire the writing skill to dispatch its outline phase to the pyramid skill for analytical formats (memo, briefing, announcement), so that `/writing --format memo` produces a Minto-pyramid-structured piece end-to-end. Pyramid skill remains standalone-invokable.

**Architecture:** Format-driven branching inside the writing orchestrator. For analytical formats, writing's Phase 1 (interview) is skipped, Phase 2 (outline) is replaced by pyramid's Phases 2 through 5 (construct, audit, opener, render), Phase 3 (throughline) reads the apex from `pyramid.md`, and Phase 4 (draft) uses a new `draft-analytical-prompt.md` that drafts directive prose from the pyramid. Phases 5 and 6 (panel, finishing) are unchanged. The pyramid skill's SKILL.md needs no structural changes: writing's SKILL.md instructs the orchestrator (Claude at runtime) on how to invoke pyramid in dispatched mode (skip domain-limits gate, pre-fill genre from format). State tracking continues to use artifact presence, so no schema changes.

**Tech Stack:** Markdown SKILL.md files, bash test harness (`run_claude`, `assert_contains`, `run_claude_logged`), grep-based content checks, skill-triggering test runner (`tests/skill-triggering/run-test.sh`).

---

## Scope and non-goals

**In scope:**
- Writing skill SKILL.md edits in steps 3 (format), 4 (artifact detection), 5 (task list), and Phases 1, 2, 3, 4
- New `draft-analytical-prompt.md` for memo/briefing/announcement drafting from `pyramid.md`
- Unit, skill-triggering, and integration tests for the new dispatch behavior
- Writing plugin version bump

**Out of scope:**
- Pyramid skill structural changes. The skill is invoked in dispatched mode via writing's instructions, not via pyramid SKILL.md edits.
- Format additions beyond memo, briefing, announcement. Newsletter and other formats keep current behavior.
- Sedaris voice pass adjustment for narrative formats. Sedaris is unchanged for essay/blog/talk/newsletter and is replaced by a sibling Analytical voice pass for memo/briefing/announcement (Task 9).
- Backward-compat shim. Existing in-flight writing projects with `--format memo` and an `outline.md` already produced are not migrated; users finish the in-flight piece on the old behavior or re-run.

## File structure

**Modified:**
- `plugins/writing/skills/writing/SKILL.md` — analytical-format branches in steps 3, 4, 5, and Phases 1, 2, 3, 4, 6; updated frontmatter description
- `plugins/writing/.claude-plugin/plugin.json` — version bump to 1.4.0; keywords expanded
- `tests/unit/test-writing-skill.sh` — new content-grep tests for analytical sections
- `README.md` (repo root) — note pyramid dispatch behavior under writing plugin entry

**Created:**
- `plugins/writing/skills/writing/draft-analytical-prompt.md` — memo/briefing/announcement draft prompt that reads `pyramid.md`
- `plugins/writing/skills/writing/finishing/analytical-voice.md` — finishing pass for analytical formats; replaces Sedaris in Phase 6 for memo/briefing/announcement
- `tests/skill-triggering/prompts/writing-memo-dispatch.txt` — verifies memo prompts trigger writing
- `tests/skill-triggering/prompts/writing-briefing-dispatch.txt` — verifies briefing prompts trigger writing
- `tests/integration/test-writing-pyramid-integration.sh` — end-to-end memo run via `/writing`

**Untouched:**
- `plugins/writing/skills/pyramid/*` — pyramid prompts and reference are reused in dispatched mode without modification

---

## Task 1: Update writing skill description and format list

**Files:**
- Modify: `plugins/writing/skills/writing/SKILL.md` (frontmatter description, Step 3)
- Test: `tests/unit/test-writing-skill.sh` (add Test 11 grep block)

- [ ] **Step 1: Add a failing grep test for the new description language**

Append to `tests/unit/test-writing-skill.sh`, just before the final `echo "=== writing skill tests complete ==="` line:

```bash
# Test 11: Pyramid dispatch in description
echo "Test 11: Pyramid dispatch in description and Step 3..."
SKILL_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)/plugins/writing/skills/writing"
WRITING_SKILL="$SKILL_DIR/SKILL.md"
if grep -qE 'pyramid|Minto' "$WRITING_SKILL"; then
    echo "  [PASS] writing SKILL.md mentions pyramid/Minto"
else
    echo "  [FAIL] writing SKILL.md does not mention pyramid dispatch"
fi
if grep -qE 'analytical formats?' "$WRITING_SKILL"; then
    echo "  [PASS] writing SKILL.md mentions analytical formats"
else
    echo "  [FAIL] writing SKILL.md does not mention analytical formats"
fi
echo ""
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `PLUGIN_DIR=plugins/writing bash tests/unit/test-writing-skill.sh 2>&1 | grep -E "Test 11|pyramid|analytical"`
Expected: two `[FAIL]` lines, no `[PASS]` lines for Test 11.

- [ ] **Step 3: Update writing SKILL.md frontmatter description**

In `plugins/writing/skills/writing/SKILL.md`, replace the existing `description:` line with:

```
description: Use when the user wants to draft a blog post, essay, talk, newsletter, memo, announcement, briefing, literature note, or any longer-form prose; or when they want to review, critique, or finish an existing draft. Orchestrates a multi-phase pipeline (interview, outline, throughline gate, draft, panel review, finishing) modeled on Katie Parrott's process. For analytical formats (memo, briefing, announcement), the outline phase dispatches to the pyramid skill for Minto-style structural construction (intake, construct, audit, opener, render) and the draft phase uses an analytical draft prompt. The format-gated Smart-Brevity panel critic runs for memo, newsletter, and announcement pieces. Triggers on writing intent (drafting, reviewing, polishing, voice work) and not on simple text generation tasks.
```

- [ ] **Step 4: Update Step 3 to define analytical formats**

In `plugins/writing/skills/writing/SKILL.md`, replace the existing Step 3 (lines starting with `### Step 3: Determine the piece format`) with:

```markdown
### Step 3: Determine the piece format

Panel composition and the outline / draft phases change based on format. The pipeline branches on whether the format is **analytical** (memo, briefing, announcement) or **narrative** (essay, blog, talk, newsletter).

Supported formats:
- Narrative: `essay` (default), `blog`, `talk`, `newsletter`
- Analytical: `memo`, `briefing`, `announcement`

Resolution order:
1. Explicit flag: `--format <format>`
2. State memory: the state file's recorded format for this project
3. Default silently to `essay` and surface the default in the first response with an inline change hint: "Format: essay (default). Pass `--format memo|briefing|announcement|newsletter|blog|talk` to change."

Ask via AskUserQuestion only when the working directory name or the interview synthesis strongly signals a different format than the recorded state (for example, a state-stored `essay` format but the working directory is `memos/q3-roadmap-2026-04-23/`). In ambiguous cases, surface both candidates and let the user pick. Otherwise, resolve silently.

Format gates:
- **Pyramid pipeline:** analytical formats (`memo`, `briefing`, `announcement`) skip writing's interview and outline phases entirely. Phase 1 dispatches the pyramid skill's intake; Phase 2 dispatches pyramid's construct, audit, opener, and render phases. The pyramid pipeline produces `pyramid.md`, which is then consumed by writing's throughline (Phase 3) and analytical draft (Phase 4) phases.
- **Smart-Brevity critic:** formats `memo`, `newsletter`, `announcement` add the Smart-Brevity critic to the panel fan-out. Other formats run the default seven-critic panel. Note: `briefing` does NOT add Smart-Brevity, because briefings are dense by construction and the Smart-Brevity lens has lower signal there.

Surface the active format in the first response alongside the style guide: "Format: {format}. Using style guide: {path}". Record the format in the state file under the project key.
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `PLUGIN_DIR=plugins/writing bash tests/unit/test-writing-skill.sh 2>&1 | grep -E "Test 11|pyramid|analytical"`
Expected: two `[PASS]` lines for Test 11.

- [ ] **Step 6: Commit**

```bash
git add plugins/writing/skills/writing/SKILL.md tests/unit/test-writing-skill.sh
git commit -m "feat(writing): add analytical-format pyramid dispatch to description and Step 3"
```

---

## Task 2: Update Step 4 (artifact detection) for pyramid artifacts

**Files:**
- Modify: `plugins/writing/skills/writing/SKILL.md` (Step 4)
- Test: `tests/unit/test-writing-skill.sh` (extend Test 11)

- [ ] **Step 1: Extend the failing test**

Append to the Test 11 block in `tests/unit/test-writing-skill.sh`:

```bash
if grep -qE 'pyramid\.md exists' "$WRITING_SKILL"; then
    echo "  [PASS] writing SKILL.md Step 4 mentions pyramid.md artifact"
else
    echo "  [FAIL] writing SKILL.md Step 4 does not mention pyramid.md artifact"
fi
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `PLUGIN_DIR=plugins/writing bash tests/unit/test-writing-skill.sh 2>&1 | grep "pyramid.md artifact"`
Expected: one `[FAIL]` line.

- [ ] **Step 3: Update Step 4 in writing SKILL.md**

Replace the artifact detection list in `### Step 4: Determine starting phase` with:

```markdown
Scan the working directory for existing artifacts. Two artifact families exist depending on format:

**Narrative format artifacts (essay, blog, talk, newsletter):**
- `interview-synthesis.md` exists → interview phase complete
- `outline.md` exists → outline phase complete
- `throughline.md` exists → throughline phase complete
- `draft.md` exists → draft phase complete
- `critique.md` exists → panel phase complete
- `finishing-notes.md` exists → finishing phase has started or completed

**Analytical format artifacts (memo, briefing, announcement):**
- `intake.md` exists → pyramid intake (Phase 1) complete
- `construction.md` exists → pyramid construct (Phase 2 substep) complete
- `audit-summary.md` exists → pyramid audit (Phase 2 substep) complete
- `opener.md` exists → pyramid opener (Phase 2 substep) complete
- `pyramid.md` exists → pyramid render (Phase 2) complete; outline equivalent ready for throughline
- `throughline.md` exists → throughline phase complete
- `draft.md` exists → draft phase complete
- `critique.md` exists → panel phase complete
- `finishing-notes.md` exists → finishing phase has started or completed
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `PLUGIN_DIR=plugins/writing bash tests/unit/test-writing-skill.sh 2>&1 | grep "pyramid.md artifact"`
Expected: one `[PASS]` line.

- [ ] **Step 5: Commit**

```bash
git add plugins/writing/skills/writing/SKILL.md tests/unit/test-writing-skill.sh
git commit -m "feat(writing): scan pyramid artifacts on resume for analytical formats"
```

---

## Task 3: Update Step 5 (task list) for analytical variant

**Files:**
- Modify: `plugins/writing/skills/writing/SKILL.md` (Step 5)
- Test: `tests/unit/test-writing-skill.sh` (extend Test 11)

- [ ] **Step 1: Extend the failing test**

Append to the Test 11 block:

```bash
if grep -qE 'Pyramid intake|Pyramid construct' "$WRITING_SKILL"; then
    echo "  [PASS] writing SKILL.md Step 5 has analytical task list variant"
else
    echo "  [FAIL] writing SKILL.md Step 5 missing analytical task list variant"
fi
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `PLUGIN_DIR=plugins/writing bash tests/unit/test-writing-skill.sh 2>&1 | grep "analytical task list"`
Expected: one `[FAIL]` line.

- [ ] **Step 3: Add the analytical task list variant**

In `plugins/writing/skills/writing/SKILL.md`, replace the existing task list example in `### Step 5: Create task list` with two variants:

```markdown
Use TaskCreate to add one task per phase that will run, plus sub-tasks for the panel and finishing phases. Two task list shapes exist depending on format.

**Narrative format task list** (essay, blog, talk, newsletter):

```
1. Phase 1: Interview the author
2. Phase 2: Negotiate outline
3. Phase 3: Throughline check (≤10-word gate)
4. Phase 4: Draft sections
5. Phase 5: Run panel review
   ├── Critic: Hemingway
   ├── Critic: Hitchcock
   ├── Critic: Mom reader
   ├── Critic: Asshole reader
   ├── Critic: Clarity
   ├── Critic: Usage
   ├── Critic: Steel-man
   └── Critic: Smart-Brevity (only for newsletter)
6. Phase 6: Finishing pass
   ├── AI-pattern detector
   ├── Style enforcer
   ├── Line editor
   └── Sedaris
```

**Analytical format task list** (memo, briefing, announcement):

```
1. Phase 1: Pyramid intake (mode, audience, reader question)
2. Phase 2: Pyramid construct + audit + opener + render
   ├── Construct
   ├── Audit panel (MECE, So-What, Q-A Alignment, Inductive-Deductive)
   ├── Opener (SCQA)
   └── Render pyramid.md
3. Phase 3: Throughline check (≤10-word gate on apex)
4. Phase 4: Analytical draft
5. Phase 5: Run panel review
   ├── Critic: Hemingway
   ├── Critic: Hitchcock
   ├── Critic: Mom reader
   ├── Critic: Asshole reader
   ├── Critic: Clarity
   ├── Critic: Usage
   ├── Critic: Steel-man
   └── Critic: Smart-Brevity (only for memo, announcement)
6. Phase 6: Finishing pass
   ├── AI-pattern detector
   ├── Style enforcer
   ├── Line editor
   └── Analytical voice
```

For phase-selectable runs, only the requested phases get tasks.

Mark each task as `in_progress` when starting, `completed` when the artifact is verified.
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `PLUGIN_DIR=plugins/writing bash tests/unit/test-writing-skill.sh 2>&1 | grep "analytical task list"`
Expected: one `[PASS]` line.

- [ ] **Step 5: Commit**

```bash
git add plugins/writing/skills/writing/SKILL.md tests/unit/test-writing-skill.sh
git commit -m "feat(writing): add analytical task list variant in Step 5"
```

---

## Task 4: Add Phase 1 analytical branch (skip interview, run pyramid intake)

**Files:**
- Modify: `plugins/writing/skills/writing/SKILL.md` (Phase 1)
- Test: `tests/unit/test-writing-skill.sh` (extend Test 11)

- [ ] **Step 1: Extend the failing test**

Append to the Test 11 block:

```bash
if grep -qE 'Phase 1.*[Aa]nalytical|Analytical format.*intake' "$WRITING_SKILL"; then
    echo "  [PASS] writing SKILL.md Phase 1 has analytical branch"
else
    echo "  [FAIL] writing SKILL.md Phase 1 missing analytical branch"
fi
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `PLUGIN_DIR=plugins/writing bash tests/unit/test-writing-skill.sh 2>&1 | grep "Phase 1.*analytical branch"`
Expected: one `[FAIL]` line.

- [ ] **Step 3: Update Phase 1 in writing SKILL.md**

In `plugins/writing/skills/writing/SKILL.md`, replace the entire `#### Phase 1: Interview` section with:

```markdown
#### Phase 1: Interview (narrative formats) or Pyramid intake (analytical formats)

**Narrative formats** (essay, blog, talk, newsletter):

1. Read `interview-prompt.md` from this skill directory
2. Inject: topic, output path, style guide path, empty reviewer feedback
3. Dispatch via Agent tool. The agent will conduct an interactive interview with the user.
4. Verify `interview.md` and `interview-synthesis.md` exist
5. Mark task completed

**Analytical formats** (memo, briefing, announcement):

Skip writing's interview entirely. Run the pyramid skill's Phase 1 (intake) in **dispatched mode** as documented in `plugins/writing/skills/pyramid/SKILL.md`, with these adjustments:

1. **Mode (step 1 of pyramid intake):** ask via AskUserQuestion as normal. Note: Mode B (Restructure) is rare in this dispatched path because writing skill is forward-building; the writer typically picks Greenfield or Socratic.
2. **Genre (step 2 of pyramid intake):** pre-fill from the writing skill's resolved format. `memo` → genre `Memo`. `briefing` → genre `Briefing`. `announcement` → genre `Announcement`. Do NOT ask the user; surface the pre-fill in a one-line confirmation: "Genre: {genre} (from format)."
3. **Domain-limits gate (step 3 of pyramid intake):** SKIP. The writing skill's format gating already validated the genre is analytical-compatible; surfacing the gate would be redundant.
4. **Mode-specific inputs (steps 4, 5, 6 of pyramid intake):** ask as normal.
5. **Write intake.md (step 7 of pyramid intake):** as normal, but add field `dispatched_from: writing` so future runs know the entry point.
6. **Mark Phase 1 task completed** when `intake.md` exists.

The orchestrator (Claude at runtime) reads pyramid SKILL.md sections at dispatch time. No code or prompt files are duplicated; the dispatched mode is an instruction overlay applied to pyramid's standalone Phase 1.
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `PLUGIN_DIR=plugins/writing bash tests/unit/test-writing-skill.sh 2>&1 | grep "Phase 1.*analytical branch"`
Expected: one `[PASS]` line.

- [ ] **Step 5: Commit**

```bash
git add plugins/writing/skills/writing/SKILL.md tests/unit/test-writing-skill.sh
git commit -m "feat(writing): replace Phase 1 with pyramid intake for analytical formats"
```

---

## Task 5: Add Phase 2 analytical branch (run pyramid construct, audit, opener, render)

**Files:**
- Modify: `plugins/writing/skills/writing/SKILL.md` (Phase 2)
- Test: `tests/unit/test-writing-skill.sh` (extend Test 11)

- [ ] **Step 1: Extend the failing test**

Append to the Test 11 block:

```bash
if grep -qE 'Phase 2.*[Aa]nalytical|pyramid.md.*outline equivalent' "$WRITING_SKILL"; then
    echo "  [PASS] writing SKILL.md Phase 2 has pyramid pipeline dispatch"
else
    echo "  [FAIL] writing SKILL.md Phase 2 missing pyramid pipeline dispatch"
fi
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `PLUGIN_DIR=plugins/writing bash tests/unit/test-writing-skill.sh 2>&1 | grep "pyramid pipeline dispatch"`
Expected: one `[FAIL]` line.

- [ ] **Step 3: Update Phase 2 in writing SKILL.md**

In `plugins/writing/skills/writing/SKILL.md`, replace the entire `#### Phase 2: Outline` section with:

```markdown
#### Phase 2: Outline (narrative formats) or Pyramid pipeline (analytical formats)

**Narrative formats** (essay, blog, talk, newsletter):

1. Read `outline-prompt.md`
2. Inject: output path, style guide path, empty reviewer feedback
3. Dispatch via Agent tool
4. Verify `outline.md` exists
5. Surface the outline to the user. Accept revisions via AskUserQuestion ("Outline as proposed, or revisions before draft?"). On revisions, re-dispatch with feedback injected.
6. Mark task completed when user accepts.

**Analytical formats** (memo, briefing, announcement):

Run pyramid skill's Phases 2 through 5 (construct, audit, opener, render) inline as documented in `plugins/writing/skills/pyramid/SKILL.md`. The pyramid pipeline is reused unchanged; the orchestrator follows pyramid SKILL.md's instructions for each phase.

1. **Pyramid Phase 2 (Construct):** dispatch the construct agent per `pyramid/SKILL.md`. Mode-branched (greenfield, restructure, socratic) based on the mode collected in Phase 1. Verify `construction.md` exists.
2. **Pyramid Phase 3 (Audit panel):** fan out four audit agents in parallel per `pyramid/SKILL.md`. Consolidate into `audit-summary.md`. Apply pyramid's CRITICAL re-dispatch logic (up to 2 iterations) verbatim.
3. **Pyramid Phase 4 (Opener):** dispatch the opener agent per `pyramid/SKILL.md`. Apply pyramid's MISMATCH handling verbatim.
4. **Pyramid Phase 5 (Render):** assemble `pyramid.md` per `pyramid/SKILL.md`'s render template. The pyramid is the outline equivalent for the analytical pipeline.
5. Surface `pyramid.md` to the user. Accept revisions via AskUserQuestion ("Pyramid as proposed, or revisions before draft?"). On revisions, re-dispatch the construct agent (pyramid Phase 2) with the feedback injected, then re-run audit, opener, and render.
6. Mark task completed when user accepts.

After Phase 2 completes, the working directory contains `intake.md`, `construction.md`, `audit-summary.md`, `opener.md`, and `pyramid.md`. The throughline phase reads `pyramid.md`'s apex line; the analytical draft phase reads `pyramid.md` whole.
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `PLUGIN_DIR=plugins/writing bash tests/unit/test-writing-skill.sh 2>&1 | grep "pyramid pipeline dispatch"`
Expected: one `[PASS]` line.

- [ ] **Step 5: Commit**

```bash
git add plugins/writing/skills/writing/SKILL.md tests/unit/test-writing-skill.sh
git commit -m "feat(writing): replace Phase 2 with pyramid pipeline for analytical formats"
```

---

## Task 6: Update Phase 3 (throughline) to read apex from pyramid.md

**Files:**
- Modify: `plugins/writing/skills/writing/SKILL.md` (Phase 3)
- Test: `tests/unit/test-writing-skill.sh` (extend Test 11)

- [ ] **Step 1: Extend the failing test**

Append to the Test 11 block:

```bash
if grep -qE 'apex.*pyramid\.md|pyramid\.md.*apex' "$WRITING_SKILL"; then
    echo "  [PASS] writing SKILL.md Phase 3 reads apex from pyramid.md"
else
    echo "  [FAIL] writing SKILL.md Phase 3 missing apex from pyramid.md"
fi
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `PLUGIN_DIR=plugins/writing bash tests/unit/test-writing-skill.sh 2>&1 | grep "apex from pyramid"`
Expected: one `[FAIL]` line.

- [ ] **Step 3: Update Phase 3 in writing SKILL.md**

Replace the existing `#### Phase 3: Throughline` section with:

```markdown
#### Phase 3: Throughline

Orchestrator-only synchronous gate. No agent dispatch. Happens after Phase 2 completes, before the draft agent is dispatched. If the writer cannot compress the piece into ten words, the piece is not ready to draft.

**Source of truth varies by format:**
- Narrative formats: read `{OUTPUT_PATH}/outline.md` and extract the `**Thesis (one sentence):**` line.
- Analytical formats: read `{OUTPUT_PATH}/pyramid.md` and extract the line under the `## Apex` header (the one-sentence governing thought rendered verbatim from `construction.md`).

1. Surface the source line to the user via AskUserQuestion: "Throughline check. Compress the piece to ≤10 words. Current {thesis|apex}: \"{line}\". What is the one thing you most want the reader to take away?"
2. Validate word count on the user's response by splitting on whitespace and ignoring empty strings. If more than 10 words, re-ask via AskUserQuestion: "That is N words. Cut it to 10 or fewer. If you cannot, the {outline|pyramid} may be wrong. Return to Phase 2."
3. Offer an explicit escape hatch: the user may answer the re-ask with "RETURN TO OUTLINE" (narrative) or "RETURN TO PYRAMID" (analytical) to resume Phase 2 with their attempted throughline as reviewer feedback injected into the outline / construct prompt.
4. On acceptance, write `{OUTPUT_PATH}/throughline.md` as a single-line file containing only the accepted throughline (no markdown headers, no decoration).
5. Mark task completed.

**Edge case for analytical formats:** if `pyramid.md` lacks a `## Apex` header (e.g., a degraded MISMATCH render), fall back to reading `construction.md` and extracting the apex node directly. If neither is parseable, ask the user for the apex sentence directly before running the gate.
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `PLUGIN_DIR=plugins/writing bash tests/unit/test-writing-skill.sh 2>&1 | grep "apex from pyramid"`
Expected: one `[PASS]` line.

- [ ] **Step 5: Commit**

```bash
git add plugins/writing/skills/writing/SKILL.md tests/unit/test-writing-skill.sh
git commit -m "feat(writing): throughline gate reads apex from pyramid.md for analytical"
```

---

## Task 7: Create draft-analytical-prompt.md

**Files:**
- Create: `plugins/writing/skills/writing/draft-analytical-prompt.md`
- Test: `tests/unit/test-writing-skill.sh` (extend Test 11)

- [ ] **Step 1: Extend the failing test**

Append to the Test 11 block:

```bash
DRAFT_ANALYTICAL_PROMPT="$SKILL_DIR/draft-analytical-prompt.md"
if [ -f "$DRAFT_ANALYTICAL_PROMPT" ]; then
    echo "  [PASS] draft-analytical-prompt.md exists"
    if grep -qF 'pyramid.md' "$DRAFT_ANALYTICAL_PROMPT"; then
        echo "  [PASS] draft-analytical-prompt.md reads pyramid.md"
    else
        echo "  [FAIL] draft-analytical-prompt.md does not read pyramid.md"
    fi
    if grep -qE 'apex|SCQA' "$DRAFT_ANALYTICAL_PROMPT"; then
        echo "  [PASS] draft-analytical-prompt.md references apex/SCQA"
    else
        echo "  [FAIL] draft-analytical-prompt.md missing apex/SCQA references"
    fi
else
    echo "  [FAIL] draft-analytical-prompt.md not found"
fi
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `PLUGIN_DIR=plugins/writing bash tests/unit/test-writing-skill.sh 2>&1 | grep "draft-analytical-prompt"`
Expected: one `[FAIL]` line ("not found").

- [ ] **Step 3: Create the prompt file**

Create `plugins/writing/skills/writing/draft-analytical-prompt.md` with this content:

````markdown
# Analytical Draft Agent Prompt Template

**Purpose:** Write the directive prose draft of an analytical piece (memo, briefing, announcement) from a Minto pyramid. Skeleton, not final. Downstream phases tighten.

**Dispatch:** Fourth agent in the writing pipeline for analytical formats. Reads `pyramid.md`, `intake.md`, `throughline.md` (if present), `audit-summary.md` (for MINOR flags worth respecting), and the active style guide. Writes `draft.md`.

```
Agent tool (general-purpose):
  description: "Draft the analytical piece"
  prompt: |
    You are an analytical draft agent. You turn an approved Minto pyramid into directive
    prose for a memo, briefing, or announcement. You are NOT writing the finished piece.
    The finishing passes will tighten and humanise. Your job is the structural draft that
    expresses every node of the pyramid in prose.

    ## Configuration

    - **Output path:** {OUTPUT_PATH}
    - **Active style guide:** {STYLE_GUIDE_PATH}

    ## Setup

    1. Read `{OUTPUT_PATH}/pyramid.md` (authoritative structure: SCQA opener, apex,
       supporting findings, evidence, audit notes)
    2. Read `{OUTPUT_PATH}/intake.md` (audience, reader question, mode, genre)
    3. Read `{OUTPUT_PATH}/throughline.md` if it exists (the ten-word compression
       of the piece; the single thing the reader must take away — should match the apex)
    4. Read `{OUTPUT_PATH}/audit-summary.md` (MINOR flags worth respecting in prose)
    5. Read the active style guide (voice rules, anti-patterns, signature moves)

    ## Drafting rules

    - **Opening: lead with the SCQA opener.** Render Situation, Complication, Question,
      Answer in roughly that order. The apex (Answer) must appear within the first 100
      words. A reader who stops after the first paragraph already knows what you are
      asking, recommending, or announcing.
    - **Body: one section per top-level pyramid node.** The supporting findings from
      `pyramid.md` become the section structure. Each section opens with the finding
      stated as a complete sentence, then unfolds the evidence as prose.
    - **Hierarchy is preserved.** If pyramid.md has nested sub-groupings under a
      finding, render them as sub-sections or paragraph clusters, not as buried bullet
      points. Keep the logical structure visible.
    - **Voice for analytical formats.** Directive over narrative. Concrete over abstract.
      No throat-clearing. The reader should never wonder why they are being told this;
      every paragraph either supports the apex or sets up the next supporting finding.
    - **Short sentences. Active voice. Cut adjectives.** Memos and briefings reward
      density. The line editor will tighten further; you should already be tight.
    - **Apply the active style guide's anti-patterns as hard constraints** (never use
      blacklisted patterns).
    - **Apply the signature moves** where they fit naturally.
    - **Cite receipts with inline links** where the pyramid's evidence nodes mark them.
    - **Engage MINOR flags from audit-summary.md** in the prose. If the audit flagged
      a So-What gap on Finding 2, address it in Finding 2's section explicitly. If
      MECE flagged blurry boundaries between Findings 1 and 3, sharpen the
      transitions. Do not silently ignore MINOR flags; the reader will notice.
    - **Word target:** memos 600 to 1200 words; briefings 1200 to 2500 words;
      announcements 200 to 500 words. Hit the target within plus or minus 20%.

    ## Output

    Write `{OUTPUT_PATH}/draft.md`:

    ```markdown
    # <title inferred from apex, or provided at intake>

    *Draft v1, {YYYY-MM-DD}*

    <SCQA opener as a single tight paragraph: Situation, Complication, Question, Apex>

    ## <Finding 1 stated as a sentence>

    <prose unfolding evidence from pyramid.md, with inline links>

    ## <Finding 2 stated as a sentence>

    <prose>

    ## <Finding 3 stated as a sentence>

    <prose>

    <optional: closing paragraph reinforcing the apex if the genre calls for it
    (announcements often end here; memos often end with an explicit ask)>

    ---

    ## Drafting notes
    - **Word count:** <approximate>
    - **Receipts used:** <bullet list with URLs>
    - **Pyramid coverage:** <confirm every top-level finding has its own section>
    - **MINOR flags addressed:** <bullet list mapping each MINOR flag to where it was
      addressed>
    - **Open verifications:** <any claim that should be fact-checked before publishing>
    ```

    ## What this draft is NOT

    - Not the final voice. AI-shaped smoothness is expected at this stage. The
      finishing pipeline scrubs it.
    - Not a polished memo. Hit the structural beats; let the line editor and the
      analytical voice pass handle rhythm and crispness.
    - Not the place to add new findings. If the pyramid does not include it, do not
      smuggle it in. Return to Phase 2 if you find a gap.

    ## Reviewer Feedback

    {REVIEWER_FEEDBACK}

    If reviewer feedback is provided above, read the existing draft at
    `{OUTPUT_PATH}/draft.md`, address the specific issues raised, and update the
    file in place.
```
````

- [ ] **Step 4: Run the test to verify it passes**

Run: `PLUGIN_DIR=plugins/writing bash tests/unit/test-writing-skill.sh 2>&1 | grep "draft-analytical-prompt"`
Expected: three `[PASS]` lines (exists, reads pyramid.md, references apex/SCQA).

- [ ] **Step 5: Commit**

```bash
git add plugins/writing/skills/writing/draft-analytical-prompt.md tests/unit/test-writing-skill.sh
git commit -m "feat(writing): add draft-analytical-prompt for memo/briefing/announcement"
```

---

## Task 8: Update Phase 4 (draft) to dispatch analytical-draft for analytical formats

**Files:**
- Modify: `plugins/writing/skills/writing/SKILL.md` (Phase 4)
- Test: `tests/unit/test-writing-skill.sh` (extend Test 11)

- [ ] **Step 1: Extend the failing test**

Append to the Test 11 block:

```bash
if grep -qE 'draft-analytical-prompt' "$WRITING_SKILL"; then
    echo "  [PASS] writing SKILL.md Phase 4 references draft-analytical-prompt"
else
    echo "  [FAIL] writing SKILL.md Phase 4 missing draft-analytical-prompt reference"
fi
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `PLUGIN_DIR=plugins/writing bash tests/unit/test-writing-skill.sh 2>&1 | grep "draft-analytical-prompt reference"`
Expected: one `[FAIL]` line.

- [ ] **Step 3: Update Phase 4 in writing SKILL.md**

Replace the existing `#### Phase 4: Draft` section with:

```markdown
#### Phase 4: Draft

**Narrative formats** (essay, blog, talk, newsletter):

1. Read `draft-prompt.md`
2. Inject: output path, style guide path, empty reviewer feedback
3. Dispatch via Agent tool
4. Verify `draft.md` exists
5. Mark task completed

**Analytical formats** (memo, briefing, announcement):

1. Read `draft-analytical-prompt.md`
2. Inject: output path, style guide path, empty reviewer feedback
3. Dispatch via Agent tool. The agent reads `pyramid.md`, `intake.md`, `throughline.md` (if present), and `audit-summary.md`.
4. Verify `draft.md` exists
5. Mark task completed
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `PLUGIN_DIR=plugins/writing bash tests/unit/test-writing-skill.sh 2>&1 | grep "draft-analytical-prompt reference"`
Expected: one `[PASS]` line.

- [ ] **Step 5: Commit**

```bash
git add plugins/writing/skills/writing/SKILL.md tests/unit/test-writing-skill.sh
git commit -m "feat(writing): Phase 4 dispatches analytical draft prompt for analytical formats"
```

---

## Task 9: Add analytical voice finishing pass

**Files:**
- Create: `plugins/writing/skills/writing/finishing/analytical-voice.md`
- Modify: `plugins/writing/skills/writing/SKILL.md` (Phase 6)
- Test: `tests/unit/test-writing-skill.sh` (extend Test 11)

Sedaris reads `interview-synthesis.md` to calibrate voice; analytical formats skip the interview phase, so Sedaris would either fail to read its calibration input or freelance literary voice into a memo. The fix is a sibling finishing pass that calibrates from `intake.md` (audience, reader question, genre) and sharpens executive voice instead of literary voice.

- [ ] **Step 1: Extend the failing test**

Append to the Test 11 block in `tests/unit/test-writing-skill.sh`:

```bash
ANALYTICAL_VOICE_PROMPT="$SKILL_DIR/finishing/analytical-voice.md"
if [ -f "$ANALYTICAL_VOICE_PROMPT" ]; then
    echo "  [PASS] finishing/analytical-voice.md exists"
    if grep -qF 'intake.md' "$ANALYTICAL_VOICE_PROMPT"; then
        echo "  [PASS] analytical-voice.md calibrates from intake.md"
    else
        echo "  [FAIL] analytical-voice.md does not read intake.md"
    fi
    if grep -qiE 'throat.clearing|hedging|directive|apex' "$ANALYTICAL_VOICE_PROMPT"; then
        echo "  [PASS] analytical-voice.md targets analytical voice issues"
    else
        echo "  [FAIL] analytical-voice.md missing analytical voice targets"
    fi
else
    echo "  [FAIL] finishing/analytical-voice.md not found"
fi
if grep -qE 'analytical-voice|analytical voice pass' "$WRITING_SKILL"; then
    echo "  [PASS] writing SKILL.md Phase 6 references analytical voice pass"
else
    echo "  [FAIL] writing SKILL.md Phase 6 missing analytical voice pass reference"
fi
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `PLUGIN_DIR=plugins/writing bash tests/unit/test-writing-skill.sh 2>&1 | grep -E "analytical-voice|analytical voice"`
Expected: at least two `[FAIL]` lines (file not found, SKILL.md missing reference).

- [ ] **Step 3: Create the analytical-voice prompt file**

Create `plugins/writing/skills/writing/finishing/analytical-voice.md` with this content:

````markdown
# Analytical Voice Finishing Pass Prompt Template

**Purpose:** Sharpen the directive voice of an analytical draft (memo, briefing, announcement). Cut throat-clearing. Make the ask unmistakable. Replace passive constructions with active. Tighten the opener so the apex hits within the first paragraph.

**Dispatch:** Fourth and final finishing pass for analytical formats. Replaces the Sedaris pass for memo/briefing/announcement formats. Reads `draft.md`, `intake.md` (audience, reader question, genre), `pyramid.md` (apex and SCQA opener for cross-check), `audit-summary.md` (any MINOR flags worth resurfacing), and the active style guide. Updates `draft.md` in place. Appends to `finishing-notes.md`.

```
Agent tool (general-purpose):
  description: "Analytical voice pass"
  prompt: |
    You are an analytical voice editor. Your job is to make the directive voice of
    a memo, briefing, or announcement crisper. You are NOT adding humor, narrative,
    or literary flourish. You are tightening the executive register so the reader
    knows what you are asking and why within the first paragraph.

    ## Configuration

    - **Output path:** {OUTPUT_PATH}
    - **Active style guide:** {STYLE_GUIDE_PATH}

    ## Setup

    1. Read `{OUTPUT_PATH}/draft.md`
    2. Read `{OUTPUT_PATH}/intake.md` for audience, reader question, and genre.
       Calibrate voice register to the audience: a board briefing is more formal
       than an engineering memo; a public announcement is plainer than either.
    3. Read `{OUTPUT_PATH}/pyramid.md` for the apex and SCQA opener. Cross-check
       that the draft's first paragraph still makes the apex unavoidable; if it
       has drifted, sharpen.
    4. Read `{OUTPUT_PATH}/audit-summary.md` for any MINOR flags. If the audit
       flagged a So-What gap on a finding and the draft addressed it weakly,
       sharpen the relevant section.
    5. Read the active style guide

    ## What to do

    Find:
    - Throat-clearing openings ("It is worth noting that...", "I would like to...",
      "Before we begin, ...")
    - Passive constructions where active would be more directive
    - Apex-burying: the apex / ask / recommendation does not appear in the first
      paragraph or is hedged when it does
    - Hedging language that weakens an argument the audit panel already validated
      ("perhaps", "it might be worth considering", "in some cases", "arguably")
    - Vague modifiers that drain executive register ("very", "really", "quite",
      "fairly")
    - Section openings that bury the finding in a build-up sentence rather than
      stating the finding directly

    Make targeted edits, not rewrites. Each edit either deletes throat-clearing,
    converts passive to active, surfaces the apex earlier, removes hedging, or
    sharpens a section opener. Nothing else.

    ## What NOT to do

    - Do not add narrative, anecdotes, or humor. The draft is directive, not
      literary.
    - Do not add new arguments or findings. The pyramid is the source of truth.
    - Do not soften strong claims the audit panel validated.
    - Do not lengthen sentences. The line editor pass tightened them; do not undo.
    - Do not enforce style mechanics (the style enforcer pass did that).
    - Do not remove AI voice tics (the AI-pattern detector pass did that).
    - Do not adjust tone toward warmth or familiarity if the audience does not
      warrant it. A board briefing should sound like a board briefing.

    ## Output

    Apply small changes to `{OUTPUT_PATH}/draft.md`. Append to
    `{OUTPUT_PATH}/finishing-notes.md`:

    ```markdown
    ## Analytical Voice Pass ({YYYY-MM-DD})

    | Line | Before | After | Move |
    |------|--------|-------|------|
    | 3 | "It is worth noting that the legacy pipeline has caused considerable friction." | "The legacy pipeline has caused considerable friction." | Throat-clearing cut |
    | 14 | "It might be worth considering a migration." | "We should migrate." | Hedging removed; ask sharpened |
    | 22 | "The argument can be made that..." | "We argue that..." | Passive to active |

    **Edits applied:** N
    **Apex placement:** <one sentence: did the apex appear in the first paragraph
    before the pass? After? Did this pass move it earlier?>
    **Sections sharpened:** §1, §3
    **Sections left alone:** §2 (already crisp)
    **Audience calibration:** <one sentence on register match: board / executive /
    engineering / public>
    **Notes:** <anything notable, like an audit MINOR flag re-addressed in prose>
    ```

    ## Reviewer Feedback

    {REVIEWER_FEEDBACK}
```
````

- [ ] **Step 4: Update Phase 6 in writing SKILL.md**

Replace the existing `#### Phase 6: Finishing` section in `plugins/writing/skills/writing/SKILL.md` with:

```markdown
#### Phase 6: Finishing

Sequential, NOT parallel. Each pass updates the draft in place; later passes need the earlier passes' changes.

**Narrative formats** (essay, blog, talk, newsletter): run the four passes in this order:

1. `finishing/ai-pattern-detector.md`
2. `finishing/style-enforcer.md`
3. `finishing/line-editor.md`
4. `finishing/sedaris.md` (literary voice; reads `interview-synthesis.md` for tone calibration)

**Analytical formats** (memo, briefing, announcement): run the four passes in this order:

1. `finishing/ai-pattern-detector.md`
2. `finishing/style-enforcer.md`
3. `finishing/line-editor.md`
4. `finishing/analytical-voice.md` (executive voice; reads `intake.md` for audience calibration; replaces Sedaris because analytical formats do not run the interview phase that Sedaris depends on)

For each pass in order:
1. Read the prompt file
2. Inject: output path, style guide path, empty reviewer feedback
3. Dispatch via Agent tool
4. Verify the agent appended its log section to `finishing-notes.md`
5. Mark sub-task completed

After all four passes, present `draft.md` and `finishing-notes.md` to the user. The piece is now ready for the writer's manual voice pass per the user feedback memory (drafted prose is a skeleton, the writer rewrites in own voice).
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `PLUGIN_DIR=plugins/writing bash tests/unit/test-writing-skill.sh 2>&1 | grep -E "analytical-voice|analytical voice"`
Expected: four `[PASS]` lines (file exists, calibrates from intake.md, targets voice issues, SKILL.md references it).

- [ ] **Step 6: Commit**

```bash
git add plugins/writing/skills/writing/finishing/analytical-voice.md plugins/writing/skills/writing/SKILL.md tests/unit/test-writing-skill.sh
git commit -m "feat(writing): add analytical voice finishing pass for memo/briefing/announcement"
```

---

## Task 10: Update Edge Cases and Phase Identifier sections

**Files:**
- Modify: `plugins/writing/skills/writing/SKILL.md` (Edge Cases section)

- [ ] **Step 1: Update Edge Cases section**

In `plugins/writing/skills/writing/SKILL.md`, replace the existing `## Edge Cases` section with the following extended version (additions are the analytical-format edge cases at the bottom):

```markdown
## Edge Cases

- **Working dir does not exist**: create with `mkdir -p`
- **Style guide not found at any level**: fall back to default and warn "Using default style guide"
- **Phase artifact missing on resume**: re-run that phase
- **Agent dispatch fails**: retry once, then surface error and pause
- **Critic returns malformed output**: log, continue with the remaining critics, mark that sub-task as failed
- **User cancels mid-pipeline**: state file records the last completed phase; next invocation resumes
- **Critique gate fails twice**: present remaining critical issues, ask whether to proceed or intervene manually
- **Multiple style guide candidates** with no state record: ask once, record choice
- **Missing prerequisite artifact on phase jump (narrative)**: Outline reads `interview-synthesis.md`; Throughline reads `outline.md`; Sedaris reads `interview-synthesis.md`; Draft reads `outline.md` and `throughline.md` if present; Panel and Finishing read `draft.md`. If the user invokes `--phase X` on a directory missing the upstream artifact, ask via AskUserQuestion whether to (a) run the missing upstream phase first, (b) accept a degraded run where the agent works without that input (only safe for Sedaris reading the synthesis, or Draft reading a missing throughline), or (c) cancel and let the user produce the artifact manually
- **Missing prerequisite artifact on phase jump (analytical)**: pyramid Phase 2 reads `intake.md`; Throughline reads `pyramid.md` (or `construction.md` as fallback); Analytical Draft reads `pyramid.md`, `intake.md`, optionally `throughline.md` and `audit-summary.md`; Panel and Finishing read `draft.md`. Apply the same three options on phase-jump with missing upstream.
- **Throughline thesis or apex line missing**: if the source file does not contain the expected line (e.g., user hand-wrote an outline, or a degraded MISMATCH render produced a partial pyramid.md), ask the user for the throughline directly before running the gate rather than failing silently
- **Unknown format value**: if `--format` or the state file contains an unrecognised value, warn once, fall back to `essay`, and ask the user to confirm
- **Format mismatch on resume**: state file recorded format `essay` but the working directory contains `pyramid.md`, or recorded `memo` but contains `outline.md`. Ask via AskUserQuestion which format applies; record the corrected value.
- **Pyramid CRITICAL audit gate fails twice during dispatched run**: pyramid's standard handling applies (present remaining critical issues, ask whether to continue to opener with known issues, pause for manual intervention, or cancel). The writing skill does NOT add a second layer of gate handling on top.
- **Pyramid MISMATCH on opener**: pyramid's standard handling applies. If the user accepts the degraded opener (S and A only), the analytical draft prompt still works because it reads `pyramid.md` and the partial opener renders correctly.
```

- [ ] **Step 2: Verify the test still passes**

Run: `PLUGIN_DIR=plugins/writing bash tests/unit/test-writing-skill.sh 2>&1 | tail -20`
Expected: all Test 11 lines `[PASS]`.

- [ ] **Step 3: Commit**

```bash
git add plugins/writing/skills/writing/SKILL.md
git commit -m "feat(writing): document analytical-format edge cases"
```

---

## Task 11: Add skill-triggering tests for analytical dispatch

**Files:**
- Create: `tests/skill-triggering/prompts/writing-memo-dispatch.txt`
- Create: `tests/skill-triggering/prompts/writing-briefing-dispatch.txt`

- [ ] **Step 1: Write the memo prompt**

Create `tests/skill-triggering/prompts/writing-memo-dispatch.txt` with:

```
I need to draft a memo for my engineering org explaining why we are sunsetting the legacy data pipeline and what the migration plan is. Use --format memo. Run the full writing pipeline.
```

- [ ] **Step 2: Write the briefing prompt**

Create `tests/skill-triggering/prompts/writing-briefing-dispatch.txt` with:

```
Draft a briefing document for our board summarising the Q3 product strategy decisions. Use --format briefing.
```

- [ ] **Step 3: Run the triggering tests**

Run: `PLUGIN_DIR=plugins/writing bash tests/skill-triggering/run-test.sh writing tests/skill-triggering/prompts/writing-memo-dispatch.txt`
Expected: triggers writing skill (the dispatch happens internally; user-facing skill is `writing`).

Run: `PLUGIN_DIR=plugins/writing bash tests/skill-triggering/run-test.sh writing tests/skill-triggering/prompts/writing-briefing-dispatch.txt`
Expected: triggers writing skill.

- [ ] **Step 4: Verify pyramid still routes correctly for explicit pyramid prompts**

Run: `PLUGIN_DIR=plugins/writing bash tests/skill-triggering/run-test.sh pyramid tests/skill-triggering/prompts/pyramid-greenfield-memo.txt`
Expected: still triggers pyramid (regression check).

- [ ] **Step 5: Commit**

```bash
git add tests/skill-triggering/prompts/writing-memo-dispatch.txt tests/skill-triggering/prompts/writing-briefing-dispatch.txt
git commit -m "test(writing): skill-triggering prompts for memo/briefing dispatch"
```

---

## Task 12: Add integration test (end-to-end memo via /writing)

**Files:**
- Create: `tests/integration/test-writing-pyramid-integration.sh`

- [ ] **Step 1: Write the integration test**

Create `tests/integration/test-writing-pyramid-integration.sh`:

```bash
#!/usr/bin/env bash
# Integration test: writing skill dispatches to pyramid for analytical formats
# Verifies end-to-end memo flow: intake.md, pyramid.md, throughline.md, draft.md
# NOTE: dispatches multiple agents (intake interactive + construct + audit panel + opener +
# render + analytical draft); expect 8-15 minutes runtime
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../test-helpers.sh"

echo "=== Integration Test: writing skill dispatches to pyramid for memo ==="
echo ""

TEST_DIR=$(mktemp -d)
LOG_FILE=$(mktemp)
trap 'rm -rf "$TEST_DIR" "$LOG_FILE"' EXIT

echo "Test 1: Memo run via /writing produces pyramid artifacts and draft..."
echo "  Working dir: $TEST_DIR"

output=$(run_claude_logged \
    "Run the writing skill in --format memo mode on the topic 'Why we should standardise on PostgreSQL across services' for an audience of platform engineering leads. Use --dir $TEST_DIR. Pick Greenfield mode when asked. The reader question is 'Should we standardise our database choice?'. Answer pyramid intake questions sensibly so the pipeline can proceed. Run through Phase 4 (analytical draft) and stop before panel review." \
    "$LOG_FILE" \
    900)

echo ""
echo "Test 2: Pyramid artifacts exist..."
for artifact in intake.md construction.md audit-summary.md opener.md pyramid.md; do
    if [ -f "$TEST_DIR/$artifact" ]; then
        echo "  [PASS] $artifact created"
    else
        echo "  [FAIL] $artifact not found"
    fi
done

echo ""
echo "Test 3: Throughline gate fired and produced throughline.md..."
if [ -f "$TEST_DIR/throughline.md" ]; then
    word_count=$(wc -w < "$TEST_DIR/throughline.md")
    if [ "$word_count" -le 10 ]; then
        echo "  [PASS] throughline.md exists with ≤10 words ($word_count)"
    else
        echo "  [FAIL] throughline.md has $word_count words, expected ≤10"
    fi
else
    echo "  [FAIL] throughline.md not found"
fi

echo ""
echo "Test 4: Analytical draft.md exists and has expected structure..."
if [ -f "$TEST_DIR/draft.md" ]; then
    echo "  [PASS] draft.md created"
    if grep -qE 'Drafting notes' "$TEST_DIR/draft.md"; then
        echo "  [PASS] draft.md has Drafting notes section"
    else
        echo "  [FAIL] draft.md missing Drafting notes section"
    fi
    if grep -qE 'Pyramid coverage' "$TEST_DIR/draft.md"; then
        echo "  [PASS] draft.md mentions Pyramid coverage (analytical-draft signature)"
    else
        echo "  [FAIL] draft.md missing Pyramid coverage notes (likely used wrong draft prompt)"
    fi
else
    echo "  [FAIL] draft.md not found"
fi

echo ""
echo "Test 5: No outline.md created (analytical path skipped narrative outline)..."
if [ -f "$TEST_DIR/outline.md" ]; then
    echo "  [FAIL] outline.md unexpectedly created (analytical path should skip narrative outline)"
else
    echo "  [PASS] outline.md correctly absent"
fi

echo ""
echo "=== writing-pyramid integration test complete ==="
echo "Working dir preserved at $TEST_DIR (cleaned by trap on exit)"
echo "Tool log: $LOG_FILE"
echo ""
show_tools_used "$LOG_FILE"
```

- [ ] **Step 2: Make it executable**

Run: `chmod +x tests/integration/test-writing-pyramid-integration.sh`

- [ ] **Step 3: Manual sanity check (do NOT run in CI)**

The integration test takes 8 to 15 minutes and uses interactive AskUserQuestion. Run manually only:

Run: `PLUGIN_DIR=plugins/writing bash tests/integration/test-writing-pyramid-integration.sh`
Expected: at least four `[PASS]` lines on Tests 2 and 4 if the skill works end-to-end. Test 3 may fail if the writer types a long throughline; that is correct gate behavior, not a bug.

- [ ] **Step 4: Commit**

```bash
git add tests/integration/test-writing-pyramid-integration.sh
git commit -m "test(writing): integration test for writing-pyramid memo dispatch"
```

---

## Task 13: Bump plugin version and update keywords

**Files:**
- Modify: `plugins/writing/.claude-plugin/plugin.json`

- [ ] **Step 1: Read the current plugin.json**

Run: `cat plugins/writing/.claude-plugin/plugin.json`

- [ ] **Step 2: Update the version and keywords**

In `plugins/writing/.claude-plugin/plugin.json`, change `"version"` to `"1.4.0"` and ensure `keywords` includes `"memo"`, `"briefing"`, `"announcement"`. Example final fields:

```json
{
  "name": "writing",
  "version": "1.4.0",
  ...
  "keywords": [
    "writing", "drafting", "essay", "blog", "memo",
    "newsletter", "briefing", "announcement",
    "pyramid", "minto", "mece", "scqa",
    "panel-review", "critic", "finishing"
  ]
}
```

(Adjust to match the existing field order; the version bump and keyword additions are the actual change.)

- [ ] **Step 3: Run the unit tests one more time to confirm green**

Run: `PLUGIN_DIR=plugins/writing bash tests/unit/test-writing-skill.sh`
Expected: all Test 11 lines `[PASS]`. Earlier tests (1 through 10) unchanged.

Run: `PLUGIN_DIR=plugins/writing bash tests/unit/test-pyramid-skill.sh`
Expected: all 10 tests pass (regression check that pyramid skill is unchanged in standalone behavior).

- [ ] **Step 4: Commit**

```bash
git add plugins/writing/.claude-plugin/plugin.json
git commit -m "chore(writing): bump to 1.4.0 with pyramid dispatch"
```

---

## Task 14: Update README.md

**Files:**
- Modify: `README.md` (repo root)

- [ ] **Step 1: Read the relevant section**

Run: `grep -n -A 3 "writing" README.md | head -40`

- [ ] **Step 2: Update the writing plugin entry**

In `README.md`, find the writing plugin entry in the Plugins table and update it. Example new row text:

```
| `writing` | 1.4.0 | `writing`, `pyramid` (writing dispatches to pyramid for memo / briefing / announcement formats) |
```

If the README uses a different shape (e.g., bullet list per plugin), update consistently. Keep the change minimal.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: note writing-pyramid dispatch in plugin overview"
```

---

## Self-Review

Read this section after completing all tasks. Run the checks against the spec from the prior turn.

**1. Spec coverage:**
- Phase 1 dispatch to pyramid intake (Task 4): yes
- Phase 2 dispatch to pyramid construct/audit/opener/render (Task 5): yes
- Phase 3 throughline gate reading apex (Task 6): yes
- Phase 4 analytical draft from pyramid.md (Tasks 7, 8): yes
- Phase 5 panel unchanged (Smart-Brevity already gated): no task needed; documented as unchanged
- Phase 6 finishing analytical voice swap (Task 9): yes
- State tracking via artifacts (Task 2): yes
- Edge cases (Task 10): yes

**2. Placeholder scan:**
- No "TBD" / "TODO" / "implement later"
- No "fill in details"
- All bash and markdown blocks contain real content
- Test assertions reference grep patterns the implementer can run verbatim

**3. Type consistency:**
- File names match across tasks: `draft-analytical-prompt.md`, `pyramid.md`, `intake.md`, `audit-summary.md`, `construction.md`, `opener.md`, `throughline.md`, `outline.md`, `draft.md`, `critique.md`, `finishing-notes.md`
- Format names consistent: analytical = {memo, briefing, announcement}; narrative = {essay, blog, talk, newsletter}
- Smart-Brevity is gated on {memo, newsletter, announcement} per Task 1 (briefing excluded by design)
- Task 5 says pyramid Phase 2 through Phase 5 (matches pyramid SKILL.md's actual phase numbers: Construct=Phase 2, Audit=Phase 3, Opener=Phase 4, Render=Phase 5)
- Task 1 description language and Task 4 "dispatched mode" language are consistent

**4. Open question for the implementer:**
- The integration test (Task 12) uses interactive AskUserQuestion through `run_claude_logged`. If `run_claude_logged` does not handle interactive prompts cleanly, the implementer should switch to a non-interactive variant (e.g., pre-supply mode and inputs in the prompt so AskUserQuestion can short-circuit) before relying on the test in CI. The PR can be merged with the test marked manual-only, matching the existing pattern in pyramid integration tests.

---

## Risks and notes

- **Pyramid SKILL.md cross-reference brittleness.** Tasks 4 and 5 instruct the orchestrator to follow pyramid SKILL.md sections at runtime. If pyramid SKILL.md changes its phase numbers or section headers, the writing dispatch could silently break. Mitigation: reference pyramid SKILL.md by phase name (Construct, Audit panel, Opener, Render) rather than number. Consider adding a SKILL.md grep test that asserts pyramid still has those named phases.
- **Analytical voice pass is unproven.** Task 9 introduces a new finishing pass without prior memo runs to validate it. The first real memo runs may surface that some edits over-correct (e.g., stripping qualifiers that were intentional). Mitigation: the prompt is conservative ("targeted edits, not rewrites") and the finishing-notes.md log records every change, so the writer can revert.
- **No backward-compatibility shim.** In-flight projects with `--format memo` and an existing `outline.md` will not auto-migrate. Documented in Task 10 edge cases ("Format mismatch on resume").
- **Mode B (Restructure) in dispatched mode.** Pyramid's restructure mode reads an existing draft. Writing skill in analytical format does not naturally have a draft yet. The dispatch path leaves Mode B available but unusual; users wanting restructure should invoke `/pyramid` directly with their draft.
