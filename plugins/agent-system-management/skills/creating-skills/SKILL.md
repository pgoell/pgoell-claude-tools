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

Check available MCPs - if useful for research (searching docs, finding similar skills, looking up best practices), research in parallel via subagents if available, otherwise inline. Come prepared with context to reduce burden on the user. Canonical sources worth consulting: the Agent Skills open standard at agentskills.io, Anthropic's skill authoring best practices (platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices), and the example skills at github.com/anthropics/skills.

### Write the SKILL.md

Based on the user interview, fill in these components:

- **name**: Skill identifier. Prefer a verb-first gerund named for what the skill does or its core insight (processing-pdfs, condition-based-waiting), not vague nouns like helper, utils, or tools. In Claude Code the typed `/command` comes from the skill's directory name, not this field (which is a display label), so name the directory with the same care and keep the two identical.
- **description**: When to trigger, what it does. This is the primary triggering mechanism. It does two jobs: state what the skill is, and list the branches (genuinely distinct ways the skill gets used) that should trigger it. All "when to use" info goes here, not in the body. Every word of the description sits in the context window on every turn, so it earns even harder pruning than the body:
  - Front-load the skill's leading word; the description is where it does its invocation work, and when the same word lives in the user's prompts and docs, the agent links that shared language to the skill and fires it more reliably.
  - One trigger per branch. Synonyms that rename a single branch are duplication ("build features using TDD ... asks for test-first development" is one branch written twice). Collapse them; keep only the genuinely distinct branches.
  - Cut identity that's already in the body. Keep the description to triggers, plus any "when another skill needs..." reach clause.
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
- Branching is the cleanest disclosure test: inline what every branch of the skill needs, push behind a pointer what only some branches reach.
- A pointer's wording, not its target, decides when and how reliably the agent reaches the material. If a must-have reference file keeps getting skipped, sharpen the pointer's wording first; inline the material only if that fails.
- Co-locate: keep a concept's definition, rules, and caveats under one heading rather than scattered across the file, so reading one part brings its neighbours with it.

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

A skill exists to wrangle determinism out of a stochastic system. Predictability, the agent taking the same process every run rather than producing the same output, is the root virtue the practices below serve (adapted from Matt Pocock's writing-great-skills; `references/writing-great-skills.md` has the full vocabulary):

- **Leading words**: anchor behaviour in a compact concept the model already knows from pretraining (_lesson_, _fog of war_, _tracer bullets_) instead of restating a quality in a sentence. "Fast, deterministic, low-overhead" collapses into a _tight_ loop. Fewer tokens, and a sharper hook for the agent to hang its thinking on.
- **Completion criteria**: end each step on a condition that is checkable (the agent can tell done from not-done) and, where it matters, exhaustive ("every modified model accounted for", not "produce a change list"). A vague criterion invites the agent to declare done early and rush ahead.
- **Prompt the positive**: steering by prohibition backfires, since a ban names the unwanted behaviour into context ("don't think of an elephant"). State the target behaviour ("write one-line comments") so the banned one is never spoken; keep a prohibition only as a hard guardrail you cannot phrase positively, and pair it with what to do instead. Discipline enforcement is the one failure type where prohibitions are the correct form (see below).
- **The no-op test**: for each sentence, ask whether it changes behaviour versus what the model does by default. If not, delete the whole sentence rather than trim it. A weak leading word ("be thorough" when the agent is already thorough-ish) is a no-op; the fix is a stronger word (_relentless_).

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

This section is one continuous sequence: don't stop partway through. Do NOT use `/skill-test` or any other testing skill.

Put results in `<skill-name>-workspace/` as a sibling to the skill directory. Within the workspace, organize results by iteration (`iteration-1/`, `iteration-2/`, etc.) and within that, each test case gets a directory (`eval-0/`, `eval-1/`, etc.). Don't create all of this upfront, just create directories as you go.

### Step 1: Spawn all runs (with-skill AND baseline) in the same turn

For each test case, spawn two subagents in the same turn, one with the skill, one without. This is important: don't spawn the with-skill runs first and then come back for baselines later. Launch everything at once so it all finishes around the same time.

**With-skill run:**

```
Execute this task:
- Skill path: <path-to-skill>
- Task: <eval prompt>
- Input files: <eval files if any, or "none">
- Save outputs to: <workspace>/iteration-<N>/eval-<ID>/with_skill/outputs/
- Outputs to save: <what the user cares about, e.g., "the .docx file", "the final CSV">
```

**Baseline run** (same prompt, but the baseline depends on context):

- **Creating a new skill**: no skill at all. Same prompt, no skill path, save to `without_skill/outputs/`.
- **Improving an existing skill**: the old version. Before editing, snapshot the skill (`cp -r <skill-path> <workspace>/skill-snapshot/`), then point the baseline subagent at the snapshot. Save to `old_skill/outputs/`.
- **Discipline-enforcing skill whose baselines already ran before the skill was written** (the inverted path in Test Cases): reuse those captured runs as the baseline arm and spawn only the with-skill runs.

Write an `eval_metadata.json` for each test case (assertions can be empty for now). Give each eval a descriptive name based on what it's testing, not just "eval-0". Use this name for the directory too. If this iteration uses new or modified eval prompts, create these files for each new eval directory; don't assume they carry over from previous iterations.

```json
{
  "eval_id": 0,
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

When each subagent task completes, you receive a notification containing `total_tokens` and `duration_ms`. Save this data immediately to `timing.json` in the run directory:

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

1. **Grade each run**: spawn a grader subagent (or grade inline) that reads `agents/grader.md` and evaluates each assertion against the outputs. Save results to `grading.json` in each run directory. The grading.json expectations array must use the fields `text`, `passed`, and `evidence` (not `name`/`met`/`details` or other variants); the viewer depends on these exact field names. For assertions that can be checked programmatically, write and run a script rather than eyeballing it: scripts are faster, more reliable, and can be reused across iterations.

2. **Aggregate into benchmark**: run the aggregation script from the skill-creator directory:
   ```bash
   python -m scripts.aggregate_benchmark <workspace>/iteration-N --skill-name <name>
   ```
   This produces `benchmark.json` and `benchmark.md` with pass_rate, time, and tokens for each configuration, with mean ± stddev and the delta. If generating benchmark.json manually, see `references/schemas.md` for the exact schema the viewer expects.
   Put each with_skill version before its baseline counterpart.

3. **Do an analyst pass**: read the benchmark data and surface patterns the aggregate stats might hide. See `agents/analyzer.md` (the "Analyzing Benchmark Results" section) for what to look for: things like assertions that always pass regardless of skill (non-discriminating), high-variance evals (possibly flaky), and time/token tradeoffs.

4. **Launch the viewer** with both qualitative outputs and quantitative data:
   ```bash
   nohup python <skill-creator-path>/eval-viewer/generate_review.py \
     <workspace>/iteration-N \
     --skill-name "my-skill" \
     --benchmark <workspace>/iteration-N/benchmark.json \
     > /dev/null 2>&1 &
   VIEWER_PID=$!
   ```
   For iteration 2+, also pass `--previous-workspace <workspace>/iteration-<N-1>`.

   **Cowork / headless environments:** If `webbrowser.open()` is not available or the environment has no display, use `--static <output_path>` to write a standalone HTML file instead of starting a server. Feedback will be downloaded as a `feedback.json` file when the user clicks "Submit All Reviews". After download, copy `feedback.json` into the workspace directory for the next iteration to pick up.

Note: please use generate_review.py to create the viewer; there's no need to write custom HTML.

5. **Tell the user** something like: "I've opened the results in your browser. There are two tabs: 'Outputs' lets you click through each test case and leave feedback, 'Benchmark' shows the quantitative comparison. When you're done, come back here and let me know."

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
      "run_id": "eval-0-with_skill",
      "feedback": "the chart is missing axis labels",
      "timestamp": "..."
    },
    { "run_id": "eval-1-with_skill", "feedback": "", "timestamp": "..." },
    {
      "run_id": "eval-2-with_skill",
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

The description field in SKILL.md frontmatter is the primary mechanism that determines whether Claude invokes a skill. After creating or improving a skill, offer to optimize the description for better triggering accuracy.

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

### Package and Present (only if `present_files` tool is available)

Check whether you have access to the `present_files` tool. If you don't, skip this step. If you do, first sweep the skill directory: every file referenced from SKILL.md exists (the packaging validator warns on broken markdown links, but backtick path references still need a manual check), and no bundled file carries secrets, since a packaged skill is a shared artifact. Then package the skill and present the .skill file to the user:

```bash
python -m scripts.package_skill <path/to/skill-folder>
```

After packaging, direct the user to the resulting `.skill` file path so they can install it.

---

## Claude.ai-specific instructions

In Claude.ai, the core workflow is the same (draft → test → review → improve → repeat), but because Claude.ai doesn't have subagents, some mechanics change. Here's what to adapt:

**Running test cases**: No subagents means no parallel execution. For each test case, read the skill's SKILL.md, then follow its instructions to accomplish the test prompt yourself. Do them one at a time. This is less rigorous than independent subagents (you wrote the skill and you're also running it, so you have full context), but it's a useful sanity check, and the human review step compensates. Skip the baseline runs, just use the skill to complete the task as requested.

**Reviewing results**: If you can't open a browser (e.g., Claude.ai's VM has no display, or you're on a remote server), skip the browser reviewer entirely. Instead, present results directly in the conversation. For each test case, show the prompt and the output. If the output is a file the user needs to see (like a .docx or .xlsx), save it to the filesystem and tell them where it is so they can download and inspect it. Ask for feedback inline: "How does this look? Anything you'd change?"

**Benchmarking**: Skip the quantitative benchmarking: it relies on baseline comparisons which aren't meaningful without subagents. Focus on qualitative feedback from the user.

**The iteration loop**: Same as before (improve the skill, rerun the test cases, ask for feedback), just without the browser reviewer in the middle. You can still organize results into iteration directories on the filesystem if you have one.

**Description optimization**: The automated loop requires the `claude` CLI tool (specifically `claude -p`) which is only available in Claude Code. On Claude.ai, verify triggering manually instead: after the user uploads and enables the skill, have them try several prompts that should trigger it, check Claude's thinking to confirm the skill loads, and iterate on the description when it misses. Keep the description within claude.ai's 200-character cap.

**Blind comparison**: Requires subagents. Skip it.

**Packaging**: The `package_skill.py` script works anywhere with Python and a filesystem. On Claude.ai, you can run it and the user can download the resulting `.skill` file.

**Updating an existing skill**: The user might be asking you to update an existing skill, not create a new one. In this case:

- **Preserve the original name.** Note the skill's directory name and `name` frontmatter field -- use them unchanged. E.g., if the installed skill is `research-helper`, output `research-helper.skill` (not `research-helper-v2`).
- **Copy to a writeable location before editing.** The installed skill path may be read-only. Copy to `/tmp/skill-name/`, edit there, and package from the copy.
- **If packaging manually, stage in `/tmp/` first**, then copy to the output directory -- direct writes may fail due to permissions.
- **Match the upload format.** The archive must contain the skill folder as its root (not loose files, not a nested wrapper), and the folder name must match the skill name. `package_skill.py` produces this shape; replicate it when zipping by hand.

---

## Cowork-Specific Instructions

If you're in Cowork, the main things to know are:

- You have subagents, so the main workflow (spawn test cases in parallel, run baselines, grade, etc.) all works. (However, if you run into severe problems with timeouts, it's OK to run the test prompts in series rather than parallel.)
- You don't have a browser or display, so when generating the eval viewer, use `--static <output_path>` to write a standalone HTML file instead of starting a server. Then proffer a link that the user can click to open the HTML in their browser.
- For whatever reason, the Cowork setup seems to disincline Claude from generating the eval viewer after running the tests, so just to reiterate: whether you're in Cowork or in Claude Code, after running tests, you should always generate the eval viewer for the human to look at examples before revising the skill yourself and trying to make corrections, using `generate_review.py` (not writing your own boutique html code). Sorry in advance but I'm gonna go all caps here: GENERATE THE EVAL VIEWER _BEFORE_ evaluating inputs yourself. You want to get them in front of the human ASAP!
- Feedback works differently: since there's no running server, the viewer's "Submit All Reviews" button will download `feedback.json` as a file. You can then read it from there (you may have to request access first).
- Packaging works: `package_skill.py` just needs Python and a filesystem.
- Description optimization (`run_loop.py` / `run_eval.py`) should work in Cowork just fine since it uses `claude -p` via subprocess, not a browser, but please save it until you've fully finished making the skill and the user agrees it's in good shape.
- **Updating an existing skill**: The user might be asking you to update an existing skill, not create a new one. Follow the update guidance in the claude.ai section above.

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

Please add steps to your TodoList, if you have such a thing, to make sure you don't forget. If you're in Cowork, please specifically put "Create evals JSON and run `eval-viewer/generate_review.py` so human can review test cases" in your TodoList to make sure it happens.

Good luck!
