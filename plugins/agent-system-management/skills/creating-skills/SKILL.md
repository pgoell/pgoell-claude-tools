---
name: creating-skills
description: Create new skills, modify and improve existing skills, and measure skill performance. Use when users want to create a skill from scratch, edit, or optimize an existing skill, run evals to test a skill, benchmark skill performance with variance analysis, or optimize a skill's description for better triggering accuracy. Also use when the user asks to cut, trim, shorten, or de-slop a skill, or to make it trigger less eagerly.
---

# Skill Creator

A skill for creating new skills and iteratively improving them.

At a high level, the process of creating a skill goes like this:

- Decide what you want the skill to do and roughly how it should do it
- Write a draft of the skill
- Create a few test prompts and run claude-with-access-to-the-skill on them
- Help the user evaluate the results both qualitatively and quantitatively
  - While the runs happen in the background, draft some quantitative evals if there aren't any (if there are some, you can either use as is or modify if you feel something needs to change about them). Then explain them to the user (or if they already existed, explain the ones that already exist)
  - Use the `eval-viewer/generate_review.py` script to show the user the results for them to look at, and also let them look at the quantitative metrics
- Rewrite the skill based on feedback from the user's evaluation of the results (and also if there are any glaring flaws that become apparent from the quantitative benchmarks)
- Repeat until you're satisfied
- Expand the test set and try again at larger scale

Your job when using this skill is to figure out where the user is in this process and then jump in and help them progress through these stages. So for instance, maybe they're like "I want to make a skill for X". You can help narrow down what they mean, write a draft, write the test cases, figure out how they want to evaluate, run all the prompts, and repeat.

On the other hand, maybe they already have a draft of the skill. In this case you can go straight to the eval/iterate part of the loop.

Of course, you should always be flexible and if the user is like "I don't need to run a bunch of evaluations, just vibe with me", you can do that instead.

Then after the skill is done (but again, the order is flexible), you can also run the skill description improver, which we have a whole separate script for, to optimize the triggering of the skill.

On claude.ai or in Cowork, read `references/other-surfaces.md` before you start: it changes how you test, review, tune the description, and update an installed skill.

Cool? Cool.

## Communicating with the user

The skill creator is liable to be used by people across a wide range of familiarity with coding jargon. If you haven't heard (and how could you, it's only very recently that it started), there's a trend now where the power of Claude is inspiring plumbers to open up their terminals, parents and grandparents to google "how to install npm". On the other hand, the bulk of users are probably fairly computer-literate.

So please pay attention to context cues to understand how to phrase your communication! In the default case, just to give you some idea:

- "evaluation" and "benchmark" are borderline, but OK
- for "JSON" and "assertion" you want to see serious cues from the user that they know what those things are before using them without explaining them

It's OK to briefly explain terms if you're in doubt, and feel free to clarify terms with a short definition if you're unsure if the user will get it.

---

## Creating a skill

### Capture Intent

Start by understanding the user's intent. The current conversation might already contain a workflow the user wants to capture (e.g., they say "turn this into a skill"). If so, extract answers from the conversation history first: the tools used, the sequence of steps, corrections the user made, input/output formats observed. The user may need to fill the gaps, and should confirm before proceeding to the next step.

Also check that a skill is the right vehicle. A skill suits a procedure: instructions, checklists, multi-step workflows the user keeps re-explaining. A plain fact or preference belongs in CLAUDE.md (or memory) instead. The cost model decides: CLAUDE.md content loads every turn, a skill's body loads only when used, so long procedural material is nearly free as a skill and expensive as CLAUDE.md. If what the user describes is a fact, suggest CLAUDE.md and stop here.

1. What should this skill enable Claude to do?
2. When should this skill trigger? (what user phrases/contexts)
3. What's the expected output format?
4. Should we set up test cases to verify the skill works? Skills with objectively verifiable outputs (file transforms, data extraction, code generation, fixed workflow steps) benefit from test cases. Skills with subjective outputs (writing style, art) often don't need them. Suggest the appropriate default based on the skill type, but let the user decide.

### Interview and Research

Proactively ask questions about edge cases, input/output formats, example files, success criteria, and dependencies. Wait to write test prompts until you've got this part ironed out.

Check available MCPs - if useful for research (searching docs, finding similar skills, looking up best practices), research in parallel via subagents if available, otherwise inline. Come prepared with context to reduce burden on the user. Canonical sources worth consulting: the Agent Skills open standard at agentskills.io, Anthropic's skill authoring best practices (platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices), and the example skills at github.com/anthropics/skills/tree/b9e19e6f44773509fbdd7001d77ff41a49a486c1.

### Write the SKILL.md

Based on the user interview, fill in these components:

- **name**: Skill identifier. Prefer a verb-first gerund named for what the skill does or its core insight (processing-pdfs, condition-based-waiting), not vague nouns like helper, utils, or tools. In Claude Code the typed `/command` comes from the skill's directory name, not this field (which is a display label), so name the directory with the same care and keep the two identical.
- **description**: When to trigger, what it does. This is the primary triggering mechanism. It does two jobs: state what the skill is, and list the branches (genuinely distinct ways the skill gets used) that should trigger it. All "when to use" info goes here, not in the body. Every word of the description sits in the context window on every turn, so it earns even harder pruning than the body. Read "Writing the description" in `references/writing-great-skills.md` before you write one: it covers front-loading the leading word, one trigger per branch, and cutting identity the body already holds. Two rules it lacks:
  - Write it in the third person, and never summarize the skill's workflow in it. An agent that can see the process in the description follows that shortcut instead of reading the body: a description saying "code review between tasks" produced a single review where the body required two. For discipline-enforcing skills (those that impose a rule the agent is tempted to break under pressure), the triggers should include symptoms of imminent violation ("when tempted to test after").
  - Budget the length for the tightest platform the skill ships to: the spec's hard limit is 1024 characters, Claude Code truncates the combined `description` plus `when_to_use` at 1,536 characters in the skill listing (so the key use case must sit in the first sentence), and claude.ai uploads cap the description at 200 characters.
- **disable-model-invocation** (optional): Set to `true` when a skill should only ever fire by the user typing its name. The description then stops loading into the agent's context on every turn and becomes a human-facing one-line summary. It also blocks invocation through the Skill tool, subagent preloading, and scheduled-task use. Keep model invocation (the default) only when the agent must reach the skill on its own, or another skill must.
- **user-invocable** (optional): Set to `false` to hide a skill from the `/` menu while leaving Claude able to load it. For background knowledge that is not actionable as a command (mechanics in `references/platform-mechanics.md`).
- **compatibility** / **dependencies**: Environment requirements (optional, rarely needed). The agentskills.io spec field is `compatibility` (advisory); claude.ai documents `dependencies` (e.g. `python>=3.8`).
- Claude Code supports further fields: `allowed-tools` (an agentskills.io spec field, experimental, support varies by platform) plus its own extensions `disallowed-tools`, `context: fork` with `agent`, `model`, `effort`, `hooks`, `paths`, and argument declarations. See `references/platform-mechanics.md` for the full reference; the extensions are not portable to other Agent Skills platforms.
- **the rest of the skill :)**

### Skill Writing Guide

#### Anatomy of a Skill

```
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter (name + description; required for claude.ai upload, optional in Claude Code)
│   └── Markdown instructions
└── Bundled Resources (optional)
    ├── scripts/    - Executable code for deterministic/repetitive tasks
    ├── references/ - Docs loaded into context as needed
    └── assets/     - Files used in output (templates, icons, fonts)
```

#### Progressive Disclosure

Skills use a three-level loading system:

1. **Metadata** (name + description) - In context every turn for model-invoked skills (~100 words)
2. **SKILL.md body** - In context whenever skill triggers (<500 lines ideal)
3. **Bundled resources** - As needed (unlimited, scripts can execute without loading)

These word counts are approximate and you can feel free to go longer if needed.

**Key patterns:**

- Keep SKILL.md under 500 lines; if you're approaching this limit, split content into more sibling reference files, linked directly from SKILL.md with clear pointers about where the model using the skill should go next to follow up.
- Reference files clearly from SKILL.md with guidance on when to read them
- Keep references one level deep: link every reference file directly from SKILL.md. Agents preview nested files with partial reads (`head -100`), so material two hops away gets truncated or missed.
- For large reference files (>300 lines), include a table of contents
- To decide what goes behind a pointer, how to word the pointer, and what to keep together, read "Information hierarchy" in `references/writing-great-skills.md` (the branching test, pointer wording, co-location).

**Domain organization**: When a skill supports multiple domains/frameworks, organize by variant:

```
cloud-deploy/
├── SKILL.md (workflow + selection)
└── references/
    ├── aws.md
    ├── gcp.md
    └── azure.md
```

Claude reads only the relevant reference file.

#### Skills in plugin marketplace repos

When the skill lives in a repo that distributes plugins (a marketplace manifest at the repo root, a directory of plugins), writing SKILL.md is only half the job: the skill must be registered in the marketplace manifest, the plugin version bumped, index docs updated, and the repo's checks passed. Discover the host repo's conventions (author, license, commit style, version-tracking files) from its existing plugins rather than inventing values. `references/marketplace-integration.md` has the discovery checklist, wiring steps, version discipline, and drop-in test scaffolds.

#### Principle of Lack of Surprise

This goes without saying, but skills must not contain malware, exploit code, or any content that could compromise system security. A skill's contents should not surprise the user in their intent if described. Don't go along with requests to create misleading skills or skills designed to facilitate unauthorized access, data exfiltration, or other malicious activities. Things like a "roleplay as an XYZ" are OK though.

The same principle covers accidental hazards. Never hardcode secrets (API keys, tokens, passwords) into a skill or its scripts: a packaged skill is a shared artifact, and an embedded key travels with every copy. Route external service access through MCP connections rather than embedded credentials. And when asked to improve a skill someone else authored, read it fully before running anything in it.

#### Writing Patterns

Prefer using the imperative form in instructions.

**Defining output formats** - You can do it like this:

```markdown
## Report structure

ALWAYS use this exact template:

# [Title]

## Executive summary

## Key findings

## Recommendations
```

**Examples pattern** - It's useful to include examples. You can format them like this (but if "Input" and "Output" are in the examples you might want to deviate a little):

```markdown
## Commit message format

**Example 1:**
Input: Added user authentication with JWT tokens
Output: feat(auth): implement JWT-based authentication
```

**Arguments** - Skills accept arguments at invocation (`/fix-issue 123`), available in the body as `$ARGUMENTS` (or positionally as `$0`, `$1`, ...), with `argument-hint` documenting the expected shape. Use them to parameterize task skills instead of making the agent fish the parameter out of conversation. The full substitution table (named arguments, session variables) is in `references/platform-mechanics.md`.

**Dynamic context injection** (Claude Code only) - A `` !`command` `` line in the body runs at render time and is replaced by its output before Claude sees the skill, so live state (a git diff, PR data, environment info) arrives already inlined at zero agent turns. A policy setting can disable execution, so the skill should still read sensibly without the output. Mechanics and caveats in `references/platform-mechanics.md`.

**Wrapping CLIs and APIs**: for a skill that drives an external service, teach it to attempt the operation first and diagnose auth only on failure; upfront auth checks add a round trip to every run and still miss expired credentials. Never echo or log credential values, check presence with `test -n "$VAR"` only. Confirm with the user before destructive operations. And don't bundle wrapper scripts around a CLI the user already has: the agent can call the CLI directly, and a wrapper is a layer that drifts out of date. Bundled scripts earn their place for repeated multi-step work (see "Look for repeated work across test cases" below), not for renaming existing commands.

**Feedback loops**: a pattern that greatly improves output quality is run validator, fix, repeat until clean. The validator can be a script or a checklist document the agent compares its output against, and failure should loop back explicitly ("if verification fails, return to step 2"). For multi-step workflows, embed a literal checklist the agent copies into its response and ticks off, so skipped steps become visible.

### Writing Style

Try to explain to the model why things are important in lieu of heavy-handed musty MUSTs. Use theory of mind and try to make the skill general and not super-narrow to specific examples. Start by writing a draft and then look at it with fresh eyes and improve it.

Before you draft the body, and again when you review it, read `references/writing-great-skills.md` (adapted from Matt Pocock's writing-great-skills). Its sections "Leading words", "Completion criteria and legwork", "Pruning" (the no-op test) and "Failure modes" (negation, so prompt the positive) set how each sentence should steer.

Calibrate specificity to fragility: prose heuristics where many approaches work, a parameterized template where one pattern is preferred, an exact do-not-modify command where the operation breaks under variation. Pick one term per concept and use it throughout; mixing synonyms (URL, route, path) makes instructions harder to follow.

Match the form of a fix to the failure you observed (adapted from Jesse Vincent's writing-skills): classify the baseline failure before writing, because the form that bulletproofs one failure type backfires on another. An agent that knows a rule but skips it under pressure needs prohibition, a rationalization table, and red flags; an agent whose output has the wrong shape needs a positive recipe stating what the output is. `references/bulletproofing.md` has the full form-to-failure matrix, the head-to-head evidence, and the rules that hold for any form.

### Test Cases

After writing the skill draft, come up with 2-3 realistic test prompts, the kind of thing a real user would actually say. Share them with the user: [you don't have to use this exact language] "Here are a few test cases I'd like to try. Do these look right, or do you want to add more?" Then run them.

For a discipline-enforcing skill, invert the order: run the scenarios as baselines before writing the skill, and capture the agent's rationalizations verbatim. Those observed failures, not your guesses, define what the skill must say. Design the scenarios as forced choices under stacked pressure; `references/bulletproofing.md` has the method.

Save test cases to `evals/evals.json`. Don't write assertions yet, just the prompts. You'll draft assertions in the next step while the runs are in progress.

```json
{
  "skill_name": "example-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "User's task prompt",
      "expected_output": "Description of expected result",
      "files": []
    }
  ]
}
```

See `references/schemas.md` for the full schema (the assertions you'll add later live in its `expectations` field, which is what the grading pipeline and viewer call them).

## Running and evaluating test cases

If you have no subagents (Claude.ai), no browser or display (Cowork, a remote box), or a `present_files` tool, read `references/other-surfaces.md` first: it says which steps below change.

This section is one continuous sequence: don't stop partway through. Do NOT use `/skill-test` or any other testing skill.

Put results in `<skill-name>-workspace/` as a sibling to the skill directory. Within the workspace, organize results by iteration (`iteration-1/`, `iteration-2/`, etc.) and within that, each test case gets a directory `eval-<id>-<name>/`, where `<id>` is the test case's `id` in `evals/evals.json` (ids start at 1) and `<name>` is a short descriptive name (for example `eval-1-chart-axis-labels/`). Don't create all of this upfront, just create directories as you go.

### Step 1: Spawn all runs (with-skill AND baseline) in the same turn

For each test case, spawn two subagents in the same turn, one with the skill, one without. This is important: don't spawn the with-skill runs first and then come back for baselines later. Launch everything at once so it all finishes around the same time.

**With-skill run:**

```
Execute this task:
- Skill path: <path-to-skill>
- Task: <eval prompt>
- Input files: <eval files if any, or "none">
- Save outputs to: <workspace>/iteration-<N>/eval-<id>-<name>/with_skill/outputs/
- Outputs to save: <what the user cares about, e.g., "the .docx file", "the final CSV">
- Save a transcript of your plan, reasoning and tool calls to: <workspace>/iteration-<N>/eval-<id>-<name>/with_skill/outputs/transcript.md
```

**Baseline run** (same prompt, but the baseline depends on context):

- **Creating a new skill**: no skill at all. Same prompt, no skill path, save to `without_skill/outputs/`.
- **Improving an existing skill**: the old version. Before editing, snapshot the skill (`cp -r <skill-path> <workspace>/skill-snapshot/`), then point the baseline subagent at the snapshot. Save to `old_skill/outputs/`.
- **Discipline-enforcing skill whose baselines already ran before the skill was written** (the inverted path in Test Cases): reuse those captured runs as the baseline arm and spawn only the with-skill runs.

The run directory is `<eval-dir>/with_skill/` (or the baseline config dir, such as `without_skill/`) for one run, or `<eval-dir>/with_skill/run-<n>/` when you repeat a config; `outputs/`, `timing.json` and `grading.json` sit in the run directory.

Write an `eval_metadata.json` for each test case (assertions can be empty for now). Set `eval_id` to the test case's `id` in `evals/evals.json`, and give each eval a descriptive name (`eval_name`) based on what it's testing. The directory is `eval-<id>-<descriptive-name>`. If this iteration uses new or modified eval prompts, create these files for each new eval directory; don't assume they carry over from previous iterations.

```json
{
  "eval_id": 1,
  "eval_name": "descriptive-name-here",
  "prompt": "The user's task prompt",
  "assertions": []
}
```

### Step 2: While runs are in progress, draft assertions

Don't just wait for the runs to finish; you can use this time productively. Draft quantitative assertions for each test case and explain them to the user. If assertions already exist in `evals/evals.json`, review them and explain what they check.

Good assertions are objectively verifiable and have descriptive names: they should read clearly in the benchmark viewer so someone glancing at the results immediately understands what each one checks. Subjective skills (writing style, design quality) are better evaluated qualitatively; don't force assertions onto things that need human judgment.

Update the `eval_metadata.json` files and `evals/evals.json` with the assertions once drafted. Also explain to the user what they'll see in the viewer, both the qualitative outputs and the quantitative benchmark.

### Step 3: As runs complete, capture timing data

When each subagent task completes, you receive a notification containing `total_tokens` and `duration_ms`. Save this data immediately to `timing.json` in the run directory, beside `outputs/`:

```json
{
  "total_tokens": 84852,
  "duration_ms": 23332,
  "total_duration_seconds": 23.3
}
```

This is the only opportunity to capture this data: it comes through the task notification and isn't persisted elsewhere. Process each notification as it arrives rather than trying to batch them.

### Step 4: Grade, aggregate, and launch the viewer

Once all runs are done:

1. **Grade each run**: spawn a grader subagent (or grade inline) that reads `agents/grader.md` and evaluates each assertion against the outputs. Save results to `grading.json` in each run directory, beside `outputs/`. The grading.json expectations array must use the fields `text`, `passed`, and `evidence` (not `name`/`met`/`details` or other variants); the viewer depends on these exact field names. For assertions that can be checked programmatically, write and run a script rather than eyeballing it: scripts are faster, more reliable, and can be reused across iterations.

2. **Aggregate into benchmark**: run the aggregation script from the skill-creator directory:
   ```bash
   python -m scripts.aggregate_benchmark <workspace>/iteration-N --skill-name <name>
   ```
   This produces `benchmark.json` and `benchmark.md` with pass_rate, time, and tokens for each configuration, with mean ± stddev and the delta. If generating benchmark.json manually, see `references/schemas.md` for the exact schema the viewer expects.
   Put each with_skill version before its baseline counterpart.

3. **Check the leading words**: a skill steers through its leading words, the compact concepts its description and body lean on (see "Leading words" in `references/writing-great-skills.md`). Before you grep, list them: read the description and body and write down each such word (for example _tracer bullets_, _red_, _tight_). Leave out a word the eval prompt itself contains: a hit would only echo the prompt. Then count each word, as a whole word, in every with_skill run's transcript:
   ```bash
   grep -c -i -w '<word>' <workspace>/iteration-N/*/with_skill/outputs/transcript.md
   ```
   The transcript is the executor's written log of its plan and reasoning, not its raw hidden thinking. A leading word that is absent from a run's reasoning and plan (a count of 0) is a steering failure, even when every assertion passes: the agent did not think with the word, so the skill did not steer that run. Write down each miss, hand the list to the analyst pass below, and fix it before the next iteration, per `references/writing-great-skills.md`: pick a stronger word, or anchor the word at the step where it should act.

4. **Do an analyst pass**: read the benchmark data and surface patterns the aggregate stats might hide. See `agents/analyzer.md` (the "Analyzing Benchmark Results" section) for what to look for: things like assertions that always pass regardless of skill (non-discriminating), high-variance evals (possibly flaky), and time/token tradeoffs.

5. **Launch the viewer** with both qualitative outputs and quantitative data:
   ```bash
   nohup python <skill-creator-path>/eval-viewer/generate_review.py \
     <workspace>/iteration-N \
     --skill-name "my-skill" \
     --benchmark <workspace>/iteration-N/benchmark.json \
     > /dev/null 2>&1 &
   VIEWER_PID=$!
   ```
   For iteration 2+, also pass `--previous-workspace <workspace>/iteration-<N-1>`.

   With no display (a remote box), pass `--static <output_path>` to write a standalone HTML file instead of starting a server; `references/other-surfaces.md` covers how `feedback.json` comes back then.

   After the runs finish, build the viewer with `generate_review.py` and put it in front of the user before you judge the quality of the outputs yourself; it beats writing custom HTML.

6. **Tell the user** something like: "I've opened the results in your browser. There are two tabs: 'Outputs' lets you click through each test case and leave feedback, 'Benchmark' shows the quantitative comparison. When you're done, come back here and let me know."

### What the user sees in the viewer

The "Outputs" tab shows one test case at a time:

- **Prompt**: the task that was given
- **Output**: the files the skill produced, rendered inline where possible
- **Previous Output** (iteration 2+): collapsed section showing last iteration's output
- **Formal Grades** (if grading was run): collapsed section showing assertion pass/fail
- **Feedback**: a textbox that auto-saves as they type
- **Previous Feedback** (iteration 2+): their comments from last time, shown below the textbox

The "Benchmark" tab shows the stats summary: pass rates, timing, and token usage for each configuration, with per-eval breakdowns and analyst observations.

Navigation is via prev/next buttons or arrow keys. When done, they click "Submit All Reviews" which saves all feedback to `feedback.json`.

### Step 5: Read the feedback

When the user tells you they're done, read `feedback.json`:

```json
{
  "reviews": [
    {
      "run_id": "eval-1-chart-axis-labels-with_skill",
      "feedback": "the chart is missing axis labels",
      "timestamp": "..."
    },
    {
      "run_id": "eval-2-csv-summary-with_skill",
      "feedback": "",
      "timestamp": "..."
    },
    {
      "run_id": "eval-3-pivot-table-with_skill",
      "feedback": "perfect, love this",
      "timestamp": "..."
    }
  ],
  "status": "complete"
}
```

Empty feedback means the user thought it was fine. Focus your improvements on the test cases where the user had specific complaints. An eval whose feedback comes back empty across iterations has also stopped earning its keep as a pressure point: swap in a fresh test case rather than rerunning a guaranteed green.

Kill the viewer server when you're done with it:

```bash
kill $VIEWER_PID 2>/dev/null
```

---

## Improving the skill

This is the heart of the loop. You've run the test cases, the user has reviewed the results, and now you need to make the skill better based on their feedback.

First check you're in the right loop. If the skill produces the right outputs but rarely fires, the body is fine and the description is the problem: go to Description Optimization. If it fires but the outputs are wrong, iterate on the body here. If it fires and the agent bypasses its rules under pressure, that's a discipline problem: pressure-test per `references/bulletproofing.md` instead of polishing prose.

### How to think about improvements

1. **Generalize from the feedback.** The big picture thing that's happening here is that we're trying to create skills that can be used a million times (maybe literally, maybe even more who knows) across many different prompts. Here you and the user are iterating on only a few examples over and over again because it helps move faster. The user knows these examples in and out and it's quick for them to assess new outputs. But if the skill you and the user are codeveloping works only for those examples, it's useless. Rather than put in fiddly overfitty changes, or oppressively constrictive MUSTs, if there's some stubborn issue, you might try branching out and using different metaphors, or recommending different patterns of working. It's relatively cheap to try and maybe you'll land on something great.

2. **Keep the prompt lean.** Remove things that aren't pulling their weight. Make sure to read the transcripts, not just the final outputs; if it looks like the skill is making the model waste a bunch of time doing things that are unproductive, you can try getting rid of the parts of the skill that are making it do that and seeing what happens. When diagnosing a misbehaving skill, check it against the named failure modes in `references/writing-great-skills.md`: premature completion, duplication, sediment, sprawl, no-ops, and negation. For a discipline-enforcing skill, diagnose against the form-to-failure matrix in `references/bulletproofing.md` instead, so you don't strip the prohibitions and tables that skill type needs. And if a skill seemed to stop working partway through a long session, check the content lifecycle in `references/platform-mechanics.md` before rewriting: invoked content persists but compaction keeps only each skill's first 5,000 tokens, so the fix may be moving critical rules earlier, not rewording them.

3. **Explain the why.** Try hard to explain the **why** behind everything you're asking the model to do. Today's LLMs are _smart_. They have good theory of mind and when given a good harness can go beyond rote instructions and really make things happen. Even if the feedback from the user is terse or frustrated, try to actually understand the task and why the user is writing what they wrote, and what they actually wrote, and then transmit this understanding into the instructions. If you find yourself writing ALWAYS or NEVER in all caps, or using super rigid structures, that's a yellow flag: if possible, reframe and explain the reasoning so that the model understands why the thing you're asking for is important. That's a more humane, powerful, and effective approach. The one exception is a discipline-enforcing skill, where absolute language is the point; `references/bulletproofing.md` covers when each register is correct.

4. **Look for repeated work across test cases.** Read the transcripts from the test runs and notice if the subagents all independently wrote similar helper scripts or took the same multi-step approach to something. If all 3 test cases resulted in the subagent writing a `create_docx.py` or a `build_chart.py`, that's a strong signal the skill should bundle that script. Write it once, put it in `scripts/`, and tell the skill to use it. This saves every future invocation from reinventing the wheel. Reference it as `${CLAUDE_SKILL_DIR}/scripts/<name>` so the path works wherever the skill is installed (personal, project, or plugin level). If the skill may run via the API code execution tool, keep the script to the standard library or vendored code, since packages cannot be installed at runtime there (see `references/platform-mechanics.md`).

5. **Micro-test contested wording.** When you're unsure whether a line earns its place, test the wording itself before a full rerun: fresh-context single-shot reps against a no-guidance control, and if the control doesn't exhibit the failure, delete the line instead of authoring guidance. `references/bulletproofing.md` has the full protocol, plus the interrogation script for when an agent violates a rule despite having the skill.

This task is pretty important (we are trying to create billions a year in economic value here!) and your thinking time is not the blocker; take your time and really mull things over. I'd suggest writing a draft revision and then looking at it anew and making improvements. Really do your best to get into the head of the user and understand what they want and need.

### The iteration loop

After improving the skill:

1. Apply your improvements to the skill (in Claude Code, edits to personal and project skills take effect within the current session; plugin skills need `/reload-plugins`)
2. Rerun all test cases into a new `iteration-<N+1>/` directory, including baseline runs. If you're creating a new skill, the baseline is always `without_skill` (no skill); that stays the same across iterations. If you're improving an existing skill, use your judgment on what makes sense as the baseline: the original version the user came in with, or the previous iteration.
3. Launch the reviewer with `--previous-workspace` pointing at the previous iteration
4. Wait for the user to review and tell you they're done
5. Read the new feedback, improve again, repeat

Keep going until:

- The user says they're happy
- The feedback is all empty (everything looks good)
- For a discipline-enforcing skill: agents produce no new rationalizations under pressure (one passing run is not convergence)
- You're not making meaningful progress. The same complaint recurring across 2 iterations means your edits aren't landing: step back and ask the user what they actually want instead of tweaking again. And if roughly 5 iterations haven't converged, the skill likely needs a structural rewrite, not another tweak.

---

## Cutting a skill

When the user asks to cut, trim, shorten, simplify, or de-slop a skill, or to make it trigger less eagerly, read `references/cutting-skills.md`. It sorts each rule by how binding it is and each passage by what it contains, so every deletion has a stated reason, and it covers narrowing the description. A review request is an audit: report the cuts, edit nothing. A cut is a skill edit, so prove it with the iteration loop above, with the pre-cut snapshot as baseline: pass rate must hold while tokens fall. Length alone is not a reason to cut.

---

## Advanced: Blind comparison

For situations where you want a more rigorous comparison between two versions of a skill (e.g., the user asks "is the new version actually better?"), there's a blind comparison system. Read `agents/comparator.md` and `agents/analyzer.md` for the details. The basic idea is: give two outputs to an independent agent without telling it which is which, and let it judge quality. Then analyze why the winner won.

This is optional, requires subagents, and most users won't need it. The human review loop is usually sufficient.

---

## Description Optimization

The description field in SKILL.md frontmatter is the primary mechanism that determines whether Claude invokes a skill. After creating or improving a skill, offer to optimize the description for better triggering accuracy. The loop below needs `claude -p`; on claude.ai, check triggering by hand as `references/other-surfaces.md` says.

Respect the length limits from the description guidance in "Write the SKILL.md" above, targeting the tightest platform the skill ships to (full details in `references/platform-mechanics.md`). Whatever the limit, put the key use case in the first sentence, since truncation cuts from the tail.

### Step 1: Generate trigger eval queries

Create 20 eval queries, a mix of should-trigger and should-not-trigger. Save as JSON:

```json
[
  { "query": "the user prompt", "should_trigger": true },
  { "query": "another prompt", "should_trigger": false }
]
```

The queries must be realistic and something a Claude Code or Claude.ai user would actually type. Not abstract requests, but requests that are concrete and specific and have a good amount of detail. For instance, file paths, personal context about the user's job or situation, column names and values, company names, URLs. A little bit of backstory. Some might be in lowercase or contain abbreviations or typos or casual speech. Use a mix of different lengths, and focus on edge cases rather than making them clear-cut (the user will get a chance to sign off on them).

Bad: `"Format this data"`, `"Extract text from PDF"`, `"Create a chart"`

Good: `"ok so my boss just sent me this xlsx file (its in my downloads, called something like 'Q4 sales final FINAL v2.xlsx') and she wants me to add a column that shows the profit margin as a percentage. The revenue is in column C and costs are in column D i think"`

For the **should-trigger** queries (8-10), think about coverage. You want different phrasings of the same intent, some formal, some casual. Include cases where the user doesn't explicitly name the skill or file type but clearly needs it. Throw in some uncommon use cases and cases where this skill competes with another but should win.

For the **should-not-trigger** queries (8-10), the most valuable ones are the near-misses: queries that share keywords or concepts with the skill but actually need something different. Think adjacent domains, ambiguous phrasing where a naive keyword match would trigger but shouldn't, and cases where the query touches on something the skill does but in a context where another tool is more appropriate.

The key thing to avoid: don't make should-not-trigger queries obviously irrelevant. "Write a fibonacci function" as a negative test for a PDF skill is too easy: it doesn't test anything. The negative cases should be genuinely tricky.

### Step 2: Review with user

Present the eval set to the user for review using the HTML template:

1. Read the template from `assets/eval_review.html`
2. Replace the placeholders:
   - `__EVAL_DATA_PLACEHOLDER__` → the JSON array of eval items (no quotes around it: it's a JS variable assignment)
   - `__SKILL_NAME_PLACEHOLDER__` → the skill's name
   - `__SKILL_DESCRIPTION_PLACEHOLDER__` → the skill's current description
3. Write to a temp file (e.g., `/tmp/eval_review_<skill-name>.html`) and open it: `open /tmp/eval_review_<skill-name>.html`
4. The user can edit queries, toggle should-trigger, add/remove entries, then click "Export Eval Set"
5. The file downloads to `~/Downloads/eval_set.json`; check the Downloads folder for the most recent version in case there are multiple (e.g., `eval_set (1).json`)

This step matters: bad eval queries lead to bad descriptions.

### Step 3: Run the optimization loop

Tell the user: "This will take some time; I'll run the optimization loop in the background and check on it periodically."

Save the eval set to the workspace, then run in the background:

```bash
python -m scripts.run_loop \
  --eval-set <path-to-trigger-eval.json> \
  --skill-path <path-to-skill> \
  --model <model-id-powering-this-session> \
  --max-iterations 5 \
  --verbose
```

Use the model ID from your system prompt (the one powering the current session) so the triggering test matches what the user actually experiences.

While it runs, periodically tail the output to give the user updates on which iteration it's on and what the scores look like.

This handles the full optimization loop automatically. It splits the eval set into 60% train and 40% held-out test, evaluates the current description (running each query 3 times to get a reliable trigger rate), then calls Claude to propose improvements based on what failed. It re-evaluates each new description on both train and test, iterating up to 5 times. When it's done, it opens an HTML report in the browser showing the results per iteration and returns JSON with `best_description`, selected by test score rather than train score to avoid overfitting.

### How skill triggering works

Understanding the triggering mechanism helps design better eval queries. Skills appear in Claude's `available_skills` list with their name + description, and Claude decides whether to consult a skill based on that description. The important thing to know is that Claude only consults skills for tasks it can't easily handle on its own, simple, one-step queries like "read this PDF" may not trigger a skill even if the description matches perfectly, because Claude can handle them directly with basic tools. Complex, multi-step, or specialized queries reliably trigger skills when the description matches.

This means your eval queries should be substantive enough that Claude would actually benefit from consulting a skill. Simple queries like "read file X" are poor test cases: they won't trigger skills regardless of description quality.

Two mechanical failure modes trump any wording. Malformed frontmatter YAML makes Claude Code load the body with empty metadata, so `/skill-name` works but the skill never auto-triggers; check this first when a skill that should trigger never does (`claude --debug` shows the parse error). And with many skills installed, the listing that holds every description has a context budget; on overflow, descriptions are shortened starting with the least-invoked skills. `references/platform-mechanics.md` covers both, plus the `paths` frontmatter field for scoping triggering to file patterns deterministically.

### Step 4: Apply the result

Take `best_description` from the JSON output and update the skill's SKILL.md frontmatter. Show the user before/after and report the scores.

### Keep a trigger regression test

The optimization loop is a one-time tune-up; triggering can still regress later, when the description gets edited or neighboring skills arrive and compete. A cheap standing guard: run `claude -p "<realistic prompt>" --verbose --output-format stream-json` and grep the trace for `"skill":"<name>"` (plugin skills appear namespaced, `"plugin:name"`). Keep one prompt file per distinct entry path of the skill, plus a near-miss prompt asserted NOT to trigger when overtriggering is a risk. Each run costs a real Claude subprocess (tens of seconds), so wire these into PR checks rather than per-commit hooks. `references/marketplace-integration.md` has a drop-in runner script.

---

### Package and present

If you have a `present_files` tool, or the user wants a `.skill` file for claude.ai or Cowork, follow "Package and present" in `references/other-surfaces.md`.

---

## Reference files

The agents/ directory contains instructions for specialized subagents. Read them when you need to spawn the relevant subagent.

- `agents/grader.md`: How to evaluate assertions against outputs
- `agents/comparator.md`: How to do blind A/B comparison between two outputs
- `agents/analyzer.md`: How to analyze why one version beat another

The references/ directory has additional documentation:

- `references/schemas.md`: JSON structures for evals.json, grading.json, etc.
- `references/platform-mechanics.md`: how Claude Code, claude.ai, and the API discover, load, render, and constrain skills (locations and precedence, invocation states, the full frontmatter reference, arguments and substitutions, dynamic context injection, content lifecycle and compaction, listing budgets, portability and upload limits). Read it when picking frontmatter beyond name and description, deciding where a skill lives, bundling scripts, diagnosing triggering, or preparing a claude.ai upload.
- `references/writing-great-skills.md`: skill design vocabulary adapted from Matt Pocock's writing-great-skills (invocation and context load, information hierarchy, leading words, completion criteria, pruning, failure modes). Read it when drafting a new skill or diagnosing a misbehaving one.
- `references/bulletproofing.md`: test-first hardening for discipline-enforcing skills, adapted from Jesse Vincent's writing-skills (baseline-before-writing, pressure scenarios, rationalization tables, the form-to-failure matrix, wording micro-tests, persuasion register). Read it when a skill enforces a rule agents might skip under pressure, or when an agent keeps rationalizing its way around one.
- `references/cutting-skills.md`: trimming a skill to its behavioral core, adapted from swyx's skill-cutter (audit and cut modes, rule-force and content tables, gate check, trigger narrowing, report shape). Read it when the user asks to cut, shorten, or de-slop a skill, or to make it trigger less.
- `references/other-surfaces.md`: what changes on claude.ai (no subagents) and in Cowork (no browser or display), how to update an installed skill there, and how to package and present a `.skill` file. Read it before you start on claude.ai or in Cowork, before running test cases when you lack subagents or a display, or when you have a `present_files` tool.
- `references/marketplace-integration.md`: shipping a skill inside a plugin marketplace repo (convention discovery, manifest and marketplace registration, version bump discipline, structure and trigger-regression test scaffolds). Read it when the skill under construction lives in a repo that distributes plugins.

---

Repeating one more time the core loop here for emphasis:

- Figure out what the skill is about
- Draft or edit the skill
- Run claude-with-access-to-the-skill on test prompts
- With the user, evaluate the outputs:
  - Create benchmark.json and run `eval-viewer/generate_review.py` to help the user review them
  - Run quantitative evals
- Repeat until you and the user are satisfied
- Package the final skill and return it to the user.

Please add steps to your TodoList, if you have such a thing, to make sure you don't forget.

Good luck!
