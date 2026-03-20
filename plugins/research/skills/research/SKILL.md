---
name: research
description: Use when the user wants to research a topic, investigate something, conduct a deep dive, find sources and citations, write a research report, or craft an optimized research prompt for external AI tools like OpenAI or Gemini. Triggers on research intent — not simple factual questions Claude can answer directly.
---

# Research Skill

Universal entry point for all research requests. Refines the user's intent, then either orchestrates a multi-agent research pipeline or generates an optimized prompt for external tools.

---

## Auth Approach

No authentication required. Uses WebSearch and WebFetch (no credentials needed) and writes to the local filesystem.

## Tool Preference

1. **Agent tool** — to dispatch pipeline agents (planner, researcher, writer) and reviewers
2. **Read** — to load prompt templates before dispatch
3. **Bash** — for directory creation and date generation
4. **Write** — for saving prompts to file when requested
5. **WebSearch/WebFetch** — fallback only if agent dispatch fails

## Workflow

### Step 1: Clarify

Ask scoping questions one at a time or in small batches:
- Main research questions / what specifically to explore
- Timeframe (last 2 years? historical?)
- Geographic scope (if relevant)
- Audience (who will read this?)
- Purpose (what decisions will this inform?)
- Source preferences (academic, industry, news, docs)
- Specific angles, perspectives, or controversies to explore

If the request is already clearly scoped (e.g. "research the impact of tariffs on EU automotive exports since 2024"), skip redundant questions — just confirm scope and proceed.

### Step 2: Route

Once intent is clear, ask: "Should I run this research now, or generate an optimized prompt you can use in another tool (OpenAI, Gemini, etc.)?"

- **Run now** → proceed to Step 3 (configure) then Step 4 (execute pipeline)
- **Generate prompt** → proceed to Prompt Output section below

### Step 3: Configure

Before dispatching, allow overrides:
- **Output path** — default: `reports/{topic-slug}-{YYYY-MM-DD}/`
- **Mode** — deep (default) or quick
- **Creative** — true or false (default: false)

Default to deep mode unless the user signals quick: "quick look at", "brief overview of", "what's the deal with".

Create the output directory and a `research/` subdirectory inside it using Bash before starting the pipeline.

### Step 4: Execute Pipeline

Run the multi-agent pipeline. Each agent communicates through files in the output directory.

#### 4.1: Plan

1. Read `planner-prompt.md` from this skill directory
2. Inject into the template: research brief, mode, creative flag, output path
3. Dispatch via **Agent tool** → wait for completion
4. Verify `{output-path}/research/plan.md` exists and contains sub-questions

#### 4.2: Research

1. Read `researcher-prompt.md` from this skill directory
2. Inject into the template: research brief, mode, output path, path to `research-recipes.md`
3. Dispatch via **Agent tool** → wait for completion
4. Verify `{output-path}/research/sources.md` and `{output-path}/research/notes.md` exist

#### 4.3: Source Review Gate

1. Read `source-reviewer-prompt.md` from this skill directory
2. Inject into the template: mode, output path
3. Dispatch via **Agent tool** → wait for completion
4. Parse verdict from agent response
5. If **FAIL** with CRITICAL issues:
   - Re-read `researcher-prompt.md`, inject original context + reviewer's CRITICAL issues into `{REVIEWER_FEEDBACK}`
   - Re-dispatch researcher → wait → re-dispatch source reviewer
   - Repeat up to **3 times**. If still failing, present remaining issues to the user and ask whether to proceed or manually intervene
6. If **PASS**: continue to 4.4

#### 4.4: Write

1. Read `writer-prompt.md` from this skill directory
2. Inject into the template: research brief, mode, creative flag, output path, path to `report-template.md`
3. Dispatch via **Agent tool** → wait for completion
4. Verify `{output-path}/report.md` exists

#### 4.5: Report Review Gate

1. Read `report-reviewer-prompt.md` from this skill directory
2. Inject into the template: mode, creative flag, output path, path to `report-template.md`
3. Dispatch via **Agent tool** → wait for completion
4. Parse verdict from agent response
5. If **FAIL** with CRITICAL issues:
   - Re-read `writer-prompt.md`, inject original context + reviewer's CRITICAL issues into `{REVIEWER_FEEDBACK}`
   - Re-dispatch writer → wait → re-dispatch report reviewer
   - Repeat up to **3 times**. If still failing, present remaining issues to the user and ask whether to proceed or manually intervene
6. If **PASS**: continue to 4.6

#### 4.6: Present

Report the output path and a brief summary to the user.

## Prompt Output

When the user wants a prompt for external tools, generate a structured prompt:

```
### TASK
[Clear, specific research objective]

### CONTEXT/BACKGROUND
[Why this matters and how it will be used]

### SPECIFIC QUESTIONS OR SUBTASKS
1. [First specific question]
2. [Second specific question]
...

### KEYWORDS
[Relevant search terms and concepts]

### CONSTRAINTS
- Timeframe: [specified timeframe]
- Geography: [specified scope]
- Source Types: [preferred sources]

### OUTPUT FORMAT
[Preferred format with specific requirements]

### FINAL INSTRUCTIONS
Remain concise, reference sources accurately, and provide evidence-based analysis.
```

Output directly in conversation. Optionally save to a file if the user requests it.

## Self-Healing

- **Agent dispatch fails for any step:** Fall back to running that step inline (in the main conversation). Warn the user about context usage.
- **Review loop exhausted (3 iterations):** Present the reviewer's remaining issues to the user and ask whether to proceed or manually intervene.
- **Artifact file missing after agent completes:** Re-dispatch the agent once. If still missing, report the error and which file is absent.
- **Output directory not writable:** Check permissions, suggest an alternative path, or ask the user where to save.

## Behavioral Guidelines

- Trigger on research intent (investigate, deep dive, report, sources) — not simple factual questions Claude can answer from training data
- When in doubt: "Would you like me to do a thorough research investigation, or just answer from what I know?"
- If the user asks for both a research run AND a prompt, do both — run the pipeline and also output the prompt
- Each prompt template has a `{REVIEWER_FEEDBACK}` placeholder. On first dispatch, leave it empty. On fix-mode re-dispatch, inject the reviewer's CRITICAL issues.
- Never pass session history to agents. Construct each dispatch prompt fresh from the template + injected values.
- See `report-template.md` for report structure and `research-recipes.md` for search patterns
