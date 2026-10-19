---
name: running-research
description: Use after research:research has written brief.md and the user approved it, to run the research. Plans question clusters, dispatches researcher subagents, synthesizes the findings under review, writes and reviews the report, and presents it. With no approved brief.md, stop and use research:research first.
---

# Running Research Skill

Orchestrator-driven deep research from an approved brief. The skill plans the work itself, spawns parallel deep-research subagents per topic cluster, synthesizes findings under unbounded review, and produces a polished report.

---

## Auth Approach

No authentication required. Uses the host agent's web search and fetch or browse capability, and writes to the local filesystem.

## Tool Preference

1. **Subagent dispatch when available and permitted**: dispatch researcher, synthesis, writer, and reviewer agents.
2. **File read tools**: load the brief and prompt templates before dispatch.
3. **Shell**: directory creation, file globbing, the `grep -x` check of Step 1, the `sha256sum` and `grep -c` checks of Step 3, the `sha256sum` and `head -1` check of Step 4, and the `mv` and render checks of Step 10.
4. **Progress list**: live loop bookkeeping.
5. **Web search and fetch or browse tools**: researchers and the synthesis reviewer use them; the orchestrator uses them only if subagent dispatch fails.

## Platform Adaptation

Use the host platform's equivalent tools without changing the workflow:

| Capability        | Claude Code                      | Codex                                                                            |
| ----------------- | -------------------------------- | -------------------------------------------------------------------------------- |
| Subagent dispatch | Agent tool                       | `spawn_agent` only when available and permitted. Otherwise run the phase inline. |
| Progress list     | TaskCreate, TaskUpdate, TaskList | `update_plan`                                                                    |
| Web research      | WebSearch, WebFetch              | `web.run` search and open calls, or the host browser/search tools                |
| File reads        | Read                             | shell reads such as `sed`, `rg`, or equivalent file read tools                   |
| Shell             | Bash                             | shell command tool                                                               |

Cursor: dispatch subagents with the `Task` tool; to run agents in parallel, send several `Task` calls in one message.

When a platform cannot dispatch subagents for the current request, keep the same artifact boundaries and run each phase inline in the orchestrator. Tell the user when this changes runtime or context cost.

## Workflow

### Step 1: Read the approved brief

Find `brief.md`: the path the user gave, or the one `research:research` named when it handed over. If neither names one, ask the user for the path. Never search for a brief and never write one yourself.

Check it: `grep -x 'Status: approved' {path}/brief.md` must print the line. If the file is missing or the check prints nothing, stop. Tell the user the brief is missing or not approved, and recommend `/research:research` to write and approve one. Do not guess a brief.

Then set:

- `OUTPUT_PATH`: the folder that holds `brief.md` (its `Output path:` line names the same folder).
- `BRIEF`: the full text of `brief.md`, injected into every dispatch below.

Create the research folder:

```bash
mkdir -p {OUTPUT_PATH}/research
```

### Step 2: Plan (orchestrator-internal)

YOU plan, not an agent. Decompose the brief into sub-questions and cluster them into coherent topics. As many clusters as the brief demands; each cluster should be deep enough to warrant a dedicated researcher. Cluster slugs must be unique and avoid colliding with reserved names (`synthesis`, `gap-N-*`, `*-review-*`). A slug must not start with `report`, `summary`, `findings` or `analysis` (see File Layout).

A brief field that reads `open (user skipped)` is yours to choose. Pick what serves the rest of the brief, and list each choice under `## Open fields` in plan.md, so the user sees it. From here on, BRIEF holds the text of brief.md followed by that list.

Write `{OUTPUT_PATH}/plan.md`:

```markdown
# Research Plan

## Brief

Topic: <topic>
Scope: <scope>
Audience: <audience>
Purpose: <purpose>
Deliverable: <deliverable>
Deadline: <deadline>

## Open fields

- <field>: <your choice> (user skipped)

## Clusters

### Cluster: <cluster-slug-1>

Title: <human-readable title>
Sub-questions:

- SQ1: <sub-question>
  - Search angles: <angle1>, <angle2>, <angle3>
  - Source types: <academic, industry, etc.>
- SQ2: ...

### Cluster: <cluster-slug-2>

...
```

Use the progress list to seed: "Spawn researchers", "Synthesize", "Review synthesis", "Write report", "Review report". Mark tasks completed as the pipeline progresses.

### Step 3: Spawn parallel researchers

Each researcher does iterative deep search on its cluster (round-by-round breadth, depth, adversarial, then iterative deepening) until two consecutive rounds add no new evidence (saturation). The researcher produces one self-contained markdown with notes and inline sources (no separate sources or notes files). For each cluster in plan.md:

1. Read `researcher-prompt.md` from this skill directory.
2. Inject: BRIEF, OUTPUT_PATH, RECIPES_PATH (path to research-recipes.md), CLUSTER_SLUG, OUTPUT_FILE (`{OUTPUT_PATH}/research/{cluster-slug}.md`), TARGETED_GAP (empty).
3. Dispatch via the host subagent tool. Send all clusters in parallel when supported.
4. Wait for all to complete. Check each output file yourself; do not trust the report:
   - The last line of the response must be `ARTIFACT-VERIFIED <sha256>`.
   - Compare that hash with your own: `sha256sum {OUTPUT_FILE} | cut -d' ' -f1`
   - Count source lines that were read: `grep '\[source:' {OUTPUT_FILE} | grep -vc '\[inaccessible\]'`. The floor is 2 per sub-question in the cluster's plan.md block, which `sed -n '/^### Cluster: {CLUSTER_SLUG}$/,/^### Cluster: /p' {OUTPUT_PATH}/plan.md | grep -c '^- SQ'` counts. If that prints 0, the plan.md block does not match the Step 2 format: fix plan.md, do not pass the file. A gap-fill file's floor is 2.

A check fails on `ARTIFACT-MISSING`, a hash mismatch, a missing or unparseable last line, or a count under the floor. Re-dispatch that researcher once; if it fails again, surface it to the user (often a bad cluster boundary). When you ran the researcher inline, there is no marker to parse; the count still runs.

### Step 4: Synthesize (iteration N, starting at 1)

1. Read `synthesis-prompt.md`.
2. Inject: BRIEF, OUTPUT_PATH, ITERATION, REVIEWER_FEEDBACK (empty on first pass; populated on re-dispatch).
3. Record the hash of the old file: `sha256sum {OUTPUT_PATH}/research/synthesis.md 2>/dev/null | cut -d' ' -f1` (prints nothing on iteration 1, when the file does not exist yet). Dispatch via the host subagent tool. Wait for completion.
4. Check the file yourself; do not trust the report. `test -f {OUTPUT_PATH}/research/synthesis.md` must pass, `sha256sum {OUTPUT_PATH}/research/synthesis.md | cut -d' ' -f1` must differ from the hash you recorded, and `head -1 {OUTPUT_PATH}/research/synthesis.md` must print `# Synthesis (Iteration N)`, with N the ITERATION you injected.

A check fails on a missing file, an unchanged hash, or a wrong first line. Re-dispatch synthesis once with the same inputs and run item 4 again against the hash from before the first dispatch (do not record a new one); if it fails again, tell the user which check failed and ask how to go on. Never go on to Step 5 with the old file.

### Step 5: Review synthesis (iteration N)

1. Read `synthesis-reviewer-prompt.md`.
2. Inject: BRIEF, OUTPUT_PATH, ITERATION, REVIEWER_FEEDBACK (empty for normal flow; populated only when re-dispatched from cross-loop branch in Step 9).
3. Dispatch via the host subagent tool. Wait for completion. In its sixth check, the reviewer fetches again up to 5 cited URLs (first any URL the prior round left `rejected` or `unresolved`, then numbers, then thesis pillars) and records each mark in the file's `REFETCH:` block.
4. Read the verdict from agent response, or from `{OUTPUT_PATH}/research/synthesis-review-{N}.md` if response is unparseable.

If verdict is PASS: continue to Step 7.

If verdict is ISSUES with critical issues: classify and proceed to Step 6.

### Step 6: Address synthesis-review issues

Classify each critical issue:

- `evidence-gap`, `coverage`, `source-quality` → spawn gap-fill researcher per issue (or per coherent group of related issues). A `rejected` refetch claim (id `refetch-<claim-slug>`) is a `source-quality` issue.
- `logic`, `structure` → no researcher; item 3 takes them.

For each gap-fill issue:

1. Read `researcher-prompt.md`. Inject: BRIEF, OUTPUT_PATH, RECIPES_PATH, CLUSTER_SLUG=<best-fit existing cluster>, OUTPUT_FILE=`{OUTPUT_PATH}/research/gap-{N}-{issue-slug}.md`, TARGETED_GAP=<full issue description with location pointer>.
2. Dispatch in parallel for all gap-fill issues when supported. Wait for completion. Run the Step 3 check on each gap-fill file (floor 2).

Then, once per round, not once per gap-fill: every round with a critical issue writes the synthesis again, whatever the mix of issues. A gap-fill file reaches the review only through synthesis.md, so never skip item 3:

3. When every gap-fill file has passed its Step 3 check (or the user, asked after a second failure, said to go on without it), re-dispatch synthesis (Step 4 with ITERATION=N+1) once per round (the retry on a failed Step 4 check still applies), with REVIEWER_FEEDBACK holding every critical issue of this round:
   - each gap-fill issue, with its gap-fill file path;
   - each rejected refetch claim, with the claim, the page quote from the `REFETCH:` block and the gap-fill file path, so the wrong claim leaves synthesis.md;
   - each `logic` or `structure` issue.

   Wait for completion.
4. Return to Step 5 with iteration N+1.

### Loop safeguards (Steps 5-6)

**Stall detection.** After writing `synthesis-review-{N}.md`, compare its issue id set to `synthesis-review-{N-1}.md`. If identical, surface to user immediately.

**Check-in.** After synthesis-review iterations 3, 6, 9, ..., pause and surface:

- Open issue ids and one-line descriptions
- What was attempted (which gap-fills ran)
- What's been narrowed (issues closed since iteration 1)
- Options: `continue`, `ship as-is`, `intervene`

Update the progress list at every step so the user can inspect live status through the host platform.

### Step 7: Write (iteration M, starting at 1)

1. Read `writer-prompt.md`.
2. Inject: BRIEF, OUTPUT_PATH, TEMPLATE_PATH (path to report-template.md), REVIEWER_FEEDBACK (empty on first pass; populated on re-dispatch).
3. Dispatch via the host subagent tool. Wait for completion.
4. Verify `{OUTPUT_PATH}/draft.md` exists.

BRIEF carries the `Deliverable:` line. The writer fits form, length and language to it, and the writer reviewer checks that fit.

### Step 8: Review report (iteration M)

1. Read `writer-reviewer-prompt.md`.
2. Inject: BRIEF, OUTPUT_PATH, TEMPLATE_PATH, ITERATION=M.
3. Dispatch via the host subagent tool. Wait for completion.
4. Read verdict.

If PASS: continue to Step 10.

If ISSUES with critical issues: classify and proceed to Step 9.

### Step 9: Address writer-review issues

Classify each critical issue:

- `prose`, `flow`, `accuracy`, `format` → batch into a single re-write with all such issues as feedback.
- `content-gap-suspected` → re-run synthesis-reviewer with this hypothesis (cross-loop).

For batched prose/flow/accuracy/format issues:

1. Re-dispatch writer with REVIEWER_FEEDBACK populated. Wait. Return to Step 8 with iteration M+1.

For any `content-gap-suspected` issues:

2. Re-dispatch synthesis-reviewer (Step 5) with REVIEWER_FEEDBACK populated with the writer-reviewer's content-gap-suspected issue list. The next synthesis-review file is `synthesis-review-{prior-N+1}.md` (synthesis loop counter resumes monotonically).
3. Branch on synthesis-reviewer verdict:
   - PASS → re-dispatch writer with prose-only feedback (drop the content-gap notes from the writer-reviewer's issue list). Return to Step 8.
   - ISSUES → return to Step 6's classification logic (`evidence-gap` / `coverage` / `source-quality` route to gap-fill research; `logic` / `structure` route to re-synthesize; a rejected refetch claim takes both routes, as Step 6 says). When the synthesis loop closes again, re-dispatch writer with the original prose feedback (if any) plus a fresh writer review. Return to Step 8.

### Loop safeguards (Steps 8-9)

Same as synthesis loop. Stall detection on consecutive identical id sets in `draft-review-{M}.md` and `draft-review-{M-1}.md`. Check-in every 3 iterations of writer-review. Same options.

### Step 10: Present

1. Resolve the format once, by the order in Output Format: prompt override, then the brief's `Format:` line, then html.
2. Rename the passed draft with the shell: `mv {OUTPUT_PATH}/draft.md {OUTPUT_PATH}/report.md`. For markdown, that is the report.
3. For html, you (never a subagent) render `{OUTPUT_PATH}/report.html` from `report.md`: read `references/rendering-the-report.md` and follow it, checks and failure path included. `report.md` stays as the reviewed source.
4. Surface a brief summary: total iterations of each loop, the final paths (`report.html` and `report.md`; `report.md` alone for markdown or a failed render), any minor (non-blocking) issues from the final reviews.

## File Layout (output directory)

```
{output-path}/
├── brief.md                      (written and approved in research:research)
├── plan.md
├── research/
│   ├── {cluster-slug}.md         (one per cluster, notes + inline sources)
│   ├── gap-{n}-{slug}.md         (gap-fill research)
│   ├── synthesis.md              (overwritten each iteration)
│   └── synthesis-review-{n}.md
├── draft.md                      (overwritten each iteration; renamed report.md in Step 10)
├── draft-review-{n}.md
├── report.md                     (the reviewed report; the deliverable for markdown, the source for html)
└── report.html                   (html only: rendered from report.md in Step 10, the deliverable)
```

Subagents never write a file named `report*`, `summary*`, `findings*` or `analysis*` with a `.md` extension: Claude Code refuses those writes from a subagent ("Subagents should return findings as text, not write report files"). That is why the writer writes `draft.md` and only the orchestrator, in Step 10, names it `report.md`.

## Verdicts and Markers

Read `references/verdicts-and-markers.md` to parse a verdict (Steps 5, 8) or a researcher's last line (Step 3). Its words are fixed: every prompt uses those spellings and no others.

## Self-Healing

- No `brief.md`, or no `Status: approved` line in it: stop and recommend `/research:research`. Never write the brief here.
- Agent dispatch fails: fall back to running that step inline. Warn user about context cost.
- Artifact file missing: re-dispatch once. Surface if still missing.
- Verdict unparseable: re-dispatch reviewer once with format reminder.
- Researcher fails the Step 3 check (`ARTIFACT-MISSING`, hash mismatch, missing or unparseable last line, source count under the floor): re-dispatch once. Surface if it fails again (likely bad cluster boundary).
- Refetched URL dead, moved, paywalled or refused: the reviewer marks it `unresolved` and goes on. Never retry it yourself.
- Stall detected: surface to user immediately. Don't auto-retry.
- Check-in interval reached: pause, present status, await user choice.
- Output dir not writable: suggest alternative path, ask user.
- HTML template unreadable, or the render fails its check (fewer links than report.md, template sample text left): keep `report.md`, leave no partial `report.html`, tell the user (see `references/rendering-the-report.md`).

## Behavioral Guidelines

- Never pass session history to agents. Construct each dispatch fresh from the template + injected values.
- Each prompt template has placeholders; the "Inject" item of its step (3, 4, 5, 7, 8) names every one.
- Credentials/secrets never appear in templates or injected values.
- See `report-template.md` for report structure (use Deep Mode section) and `research-recipes.md` for search patterns.

## Output Format

Default for this artifact: **html**.

Override resolution order, highest precedence first:

1. Per-invocation override in the user prompt. Recognize phrases like `"a markdown research report"`, `"in HTML"`, `"as a markdown report"`, and equivalents.
2. The `Format:` line of the approved `brief.md`.
3. Per-skill hard-coded default (html).

For format and path, `research:running-research` ignores `.workbench/config.md` (another plugin's file): only the override, the brief or the default decide them. Design system selection is the exception: the section below honors `.workbench/config.md` `## Design system`, so a project-wide pin themes research reports too.

Path: `{OUTPUT_PATH}/report.<ext>`, where `OUTPUT_PATH` is the brief's folder (default `reports/<topic-slug>-<YYYY-MM-DD>/`) and `<ext>` resolves from format. html keeps `report.md` beside `report.html` as its source.

When emitting HTML, follow `references/research-report-template.html` in this skill's directory, as Step 10 and `references/rendering-the-report.md` say. Read the template lazily. Do not introduce U+2014 or U+2013 codepoints in body copy; HTML entity forms are permitted.

For other HTML artifact types not covered by a workbench or research skill, see `workbench:crafting-html`.

### Applying a design system

Before emitting HTML, check whether a design system is set: a per-prompt override (e.g., "render with the `brand-2026` design system"), else `.workbench/config.md` `## Design system` `Name:`. This is the one axis on which research honors `.workbench/config.md`; format and path ignore it, per the disclaimer above. If none is set, emit with the template's defaults.

If one is set, read `references/applying-a-design-system.md` in the folder of the workbench plugin's `crafting-design-systems` skill, and follow it. That folder holds the skill's `SKILL.md`: on Claude Code, `<installPath>/skills/crafting-design-systems/`, with `installPath` taken from the `workbench@pgoell-claude-tools` entry in `~/.claude/plugins/installed_plugins.json`; on Codex and Cursor, the path their skill list shows for `crafting-design-systems`. If the workbench plugin is not installed, or its folder has no `references/applying-a-design-system.md` (workbench older than 1.2.2), tell the user the design system needs a current workbench plugin, and emit with the template's defaults.

To create or edit a design system, see `workbench:crafting-design-systems`.
