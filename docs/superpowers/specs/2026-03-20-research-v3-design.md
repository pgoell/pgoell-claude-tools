# Research Skill v3 — Multi-Agent Pipeline with Independent Review

*Date: 2026-03-20*

## Problem

The v2 research skill added analytical rigor rules (threshold integrity, bias consistency, source weight transparency, creative synthesis). A real research run on "Enterprise AI Value Measurement" revealed that **the single-agent architecture undermines these rules**: the same agent that cuts corners during research is asked to self-audit its own output. The critique identified ghost sources, missing `[author estimate]` tags, vendor data reused without caveats, and a missing executive summary — all things the self-audit checklist should have caught.

The core failure mode: **self-audit is the fox guarding the henhouse.** Rules exist but enforcement is not independent.

## Design

### Approach: Multi-Agent Pipeline with Independent Reviewers

Replace the single monolithic `deep-research.md` agent with 5 specialized agents orchestrated by the main session. Each agent reads/writes files in the output directory. Reviewers are independent — they never share context with the agents they review.

This follows the superpowers plugin pattern (from the `claude-plugins-official/superpowers` plugin): orchestrator dispatches workers, dispatches independent reviewers, gates progression on review, and re-dispatches workers with issues when review fails.

**Re-dispatch, not SendMessage:** Agents run to completion and exit. When a reviewer fails, the orchestrator dispatches a **fresh** worker agent with: (1) the original prompt context, (2) the existing artifact files, and (3) the reviewer's specific issues. The fresh agent reads the current files, applies the fixes, and updates them. This is a "fix mode" dispatch — the prompt template includes a section for injecting reviewer feedback that is empty on first run and populated on fix iterations.

### Pipeline Flow

```
User brief (clarified in main session)
  ↓
[Planner Agent] → writes plan.md
  ↓
[Researcher Agent] → reads plan.md → writes sources.md, notes.md
  ↓
[Source Reviewer Agent] → reads plan.md, sources.md, notes.md
  ├─ PASS → continue
  └─ FAIL → orchestrator re-dispatches Researcher with issues → re-review (max 3, then escalate to user)
  ↓
[Writer Agent] → reads plan.md, notes.md → writes report.md
  ↓
[Report Reviewer Agent] → reads report.md, sources.md, notes.md, report-template.md
  ├─ PASS → present to user
  └─ FAIL → orchestrator re-dispatches Writer with issues → re-review (max 3, then escalate to user)
```

### Agent Responsibilities

#### Planner Agent

Takes the research brief (topic, scope, audience, purpose, mode, creative flag) and produces `plan.md`.

**Writes:** `plan.md`
**Reads:** nothing (receives brief in prompt)

Output contains:
- Echoed brief (topic, scope, audience, purpose)
- 3-5 sub-questions that decompose the topic
- 2-3 search angles per sub-question (3 in deep mode, 2 in quick mode)
- Source types to prioritize per sub-question
- Perspective list with what each stakeholder cares about (deep mode only)

Perspectives (previously a separate `perspectives.md` file in v2) are now embedded in the "Perspectives" section of `plan.md`. The researcher reads them from there. The separate `perspectives.md` artifact is eliminated.

No reviewer for this agent — it's lightweight enough that the orchestrator sanity-checks it inline. Gaps surface naturally when the researcher executes.

#### Researcher Agent

The workhorse. Executes evidence gathering across all sub-questions.

**Reads:** `plan.md`, `research-recipes.md` (for search patterns)
**Writes:** `sources.md`, `notes.md`

Phases:
1. **Breadth pass** — WebSearch per sub-question × angle (× perspective in deep mode). Records all found sources in `sources.md` with URL, title, date, credibility tag, relevance assessment.
2. **Depth pass** — WebFetch on promising sources. Extracts data points, quotes, methodology, limitations into `notes.md`. Every numeric claim must have a citation. Any derived numbers labeled `[author estimate]` with reasoning.
3. **Adversarial pass** (deep mode only) — Searches for counterarguments, criticism, failure cases. Appends to `notes.md` under "Adversarial Findings."

The researcher does NOT synthesize, form a thesis, or write prose. Its job is honest, well-tagged evidence gathering.

#### Source Reviewer Agent

Independent reviewer that validates the researcher's output.

**Reads:** `plan.md`, `sources.md`, `notes.md`
**Writes:** nothing (returns verdict to orchestrator)

Checks:
- **Coverage** — every sub-question in plan.md has sources? Any gaps?
- **Credibility balance** — over-reliance on any single source or source type? 2+ independent sources per key area?
- **Tag consistency** — every vendor/consulting source tagged? Tags present on every reuse in notes?
- **Threshold integrity** — numeric claims have citations or `[author estimate]` with reasoning?
- **Ghost check** — anything referenced in notes that's not in sources.md?
- **Source count** — minimum 8 sources total (deep) or 5 (quick)?

Returns structured verdict:
```markdown
## Verdict: PASS | FAIL

## Issues (if FAIL)
1. [CRITICAL] <description> — <specific location/evidence>
2. [IMPORTANT] <description> — <specific location/evidence>

## Summary
<1-2 sentences>
```

Only CRITICAL issues trigger the fix loop. IMPORTANT issues are passed to the researcher but don't block.

#### Writer Agent

Synthesizes validated notes into the final report.

**Reads:** `plan.md`, `notes.md`, `report-template.md`
**Writes:** `report.md`

Responsibilities:
1. Formulate thesis — one sentence, an argued position, not a topic description
2. Structure report per `report-template.md` (executive summary, ToC, ranked findings, analysis, limitations, future outlook, conclusions, references)
3. Write with inline citations `[Source, Year](URL)` — every non-obvious claim linked
4. Credibility tags travel with data on every reuse (e.g., "McKinsey's 55% (consulting sample)")
5. Creative synthesis if enabled — generate 1-2 original frameworks, stress-test against 3 criteria, tag `[original analysis]`
6. Rank findings by importance (top 5-7 front, not a list of 30)
7. "Analysis & Insights" must be the strongest section
8. Include "Starting from zero" practical guidance

The writer does NOT do any web searching. Works only from validated notes.

#### Report Reviewer Agent

Independent reviewer that validates the final report.

**Reads:** `report.md`, `sources.md`, `notes.md`, `report-template.md`
**Writes:** nothing (returns verdict to orchestrator)

Checks:
- **Template compliance** — all required sections present? (Executive summary, ToC, methodology, etc.)
- **Citation integrity** — every claim has inline citation? Every citation traceable to sources.md?
- **Tag survival** — `[author estimate]`, `[original analysis]`, credibility tags all present where needed?
- **Thesis clarity** — clear one-sentence thesis in first paragraph of executive summary?
- **Vendor caveating** — vendor/consulting data caveated on every use, not just first mention?
- **Section quality** — "Analysis & Insights" is analytical not descriptive? No listicle advice sections?
- **Ghost sources** — report references anything not in sources.md?
- **Findings ranking** — top findings actually ranked by importance, not just listed?
- **Creative checks** (if enabled) — frameworks pass stress tests? Tagged `[original analysis]`?
- **Creative checks** (if disabled) — no original frameworks present? Gaps stated as observations only?

Returns same structured verdict format as source reviewer.

### Artifact Format Contracts

#### `plan.md`

```markdown
# Research Plan

## Brief
Topic: <topic>
Scope: <scope>
Audience: <audience>
Purpose: <purpose>
Mode: <deep|quick>
Creative: <true|false>

## Sub-Questions
1. <question>
   - Search angles: <angle1>, <angle2>, <angle3>
   - Source types: <academic, industry, practitioner, etc.>
2. ...

## Perspectives (deep mode only)
- <stakeholder>: <what they care about>
- ...
```

#### `sources.md`

```markdown
# Sources

## SQ1: <sub-question>
| # | Title | URL | Date | Credibility | Relevance |
|---|-------|-----|------|-------------|-----------|
| 1 | ...   | ... | ...  | [independent] | High — directly addresses... |
| 2 | ...   | ... | ...  | [vendor]      | Medium — useful data but... |

## SQ2: <sub-question>
...
```

#### `notes.md`

```markdown
# Research Notes

## SQ1: <sub-question>
### Source 1: <title> [credibility tag]
- Key data: ... [citation: Source 1]
- Quote: "..." [citation: Source 1]
- Methodology: ...
- Limitations: ...

### Source 2: <title> [credibility tag]
...

## Adversarial Findings (deep mode only)
### Counter to SQ1:
- <finding> [citation: Source N]
...
```

#### `report.md`

Follows `report-template.md` structure (unchanged from v2).

#### Reviewer output (not saved to file)

```markdown
## Verdict: PASS | FAIL

## Issues (if FAIL)
1. [CRITICAL] <description> — <specific location/evidence>
2. [IMPORTANT] <description> — <specific location/evidence>

## Summary
<1-2 sentences>
```

### Orchestrator Logic (SKILL.md)

The SKILL.md entry point changes from "configure and dispatch one agent" to "orchestrate the pipeline."

Steps 1-3 remain the same (Clarify, Route, Configure). Step 4 becomes:

**Step 4: Execute Pipeline**

```
1. Create output directory

2. Read planner-prompt.md, inject brief
   Dispatch planner agent → wait
   Verify plan.md exists and has sub-questions

3. Read researcher-prompt.md, inject brief + file paths + mode
   Dispatch researcher agent → wait
   Verify sources.md + notes.md exist

4. Read source-reviewer-prompt.md, inject file paths
   Dispatch source reviewer agent → wait
   If FAIL:
     for i in 1..3:
       Re-dispatch researcher with: original prompt + file paths + reviewer's CRITICAL issues
       Wait for researcher to update files
       Re-dispatch source reviewer
       If PASS: break
     If still FAIL: present issues to user, ask how to proceed

5. Read writer-prompt.md, inject brief + file paths + creative flag
   Dispatch writer agent → wait
   Verify report.md exists

6. Read report-reviewer-prompt.md, inject file paths
   Dispatch report reviewer agent → wait
   If FAIL:
     for i in 1..3:
       Re-dispatch writer with: original prompt + file paths + reviewer's CRITICAL issues
       Wait for writer to update report.md
       Re-dispatch report reviewer
       If PASS: break
     If still FAIL: present issues to user, ask how to proceed

7. Present report.md path to user
```

**Quick mode differences:**
- Planner produces 2 angles per sub-question instead of 3, no perspectives
- Researcher skips adversarial pass and perspective combinations
- Review gates still run — same quality bar

### What Changes

| File | Action |
|------|--------|
| `plugins/research/agents/deep-research.md` | DELETE — replaced by prompt templates |
| `plugins/research/skills/research/SKILL.md` | REWRITE — becomes pipeline orchestrator |
| `plugins/research/skills/research/planner-prompt.md` | NEW — planner agent prompt template |
| `plugins/research/skills/research/researcher-prompt.md` | NEW — researcher agent prompt template |
| `plugins/research/skills/research/source-reviewer-prompt.md` | NEW — source reviewer prompt template |
| `plugins/research/skills/research/writer-prompt.md` | NEW — writer agent prompt template |
| `plugins/research/skills/research/report-reviewer-prompt.md` | NEW — report reviewer prompt template |
| `plugins/research/skills/research/report-template.md` | KEEP — unchanged, referenced by writer and report reviewer |
| `plugins/research/skills/research/research-recipes.md` | MODIFY — remove self-audit checklist (moved to reviewers), keep search patterns and query recipes |
| `plugins/research/.claude-plugin/plugin.json` | UPDATE — version bump to 1.3.0 |
| `.claude-plugin/marketplace.json` | UPDATE — version bump |

### What Stays the Same

- The report template and its structure
- Search patterns and query recipes in research-recipes.md
- The SKILL.md clarification flow (Steps 1-3)
- The "generate prompt for external tool" route
- Creative synthesis logic (now lives in writer-prompt.md instead of deep-research.md)
- All v2 rules (threshold integrity, bias consistency, source weight, credibility tags) — they move from the monolithic agent to the appropriate specialized agents

### Design Decisions

1. **Prompt templates, not agent definitions.** Following the superpowers pattern — prompt templates live alongside the skill, orchestrator reads and injects context before dispatching. More flexible than agent definitions in `agents/`.

2. **No reviewer for the planner.** The planner output is lightweight and gaps surface naturally when the researcher can't find sources for a sub-question. Adding a reviewer here would slow the pipeline for minimal gain.

3. **Only CRITICAL issues gate progression.** IMPORTANT issues are communicated to the worker but don't trigger a fix loop. This prevents infinite nitpicking loops while ensuring real problems get fixed.

4. **Max 3 review iterations, then escalate.** Same pattern as superpowers. Prevents infinite loops — if 3 rounds of fixes don't resolve it, a human should look.

5. **Researcher and writer never share context.** The writer starts fresh from validated files. This is intentional — it prevents the writer from inheriting the researcher's blind spots and biases.

6. **Files as the artifact layer.** Agents communicate through files in the output directory, not inline prompt content. This makes artifacts inspectable by the user, auditable after the fact, and provides natural handoff boundaries.
