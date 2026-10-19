# Running and Evaluating Test Cases

Read this when you run a skill's test cases: it holds Steps 1 to 5 of "Running and evaluating test cases" in SKILL.md, from spawning the runs to reading the user's feedback. The steps are one continuous sequence, so read them all before Step 1.

## Step 1: Spawn all runs (with-skill AND baseline) in the same turn

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
- **Discipline-enforcing skill whose baselines already ran before the skill was written** (the inverted path in Test Cases in SKILL.md): reuse those captured runs as the baseline arm and spawn only the with-skill runs.

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

## Step 2: While runs are in progress, draft assertions

Don't just wait for the runs to finish; you can use this time productively. Draft quantitative assertions for each test case and explain them to the user. If assertions already exist in `evals/evals.json`, review them and explain what they check.

Good assertions are objectively verifiable and have descriptive names: they should read clearly in the benchmark viewer so someone glancing at the results immediately understands what each one checks. Subjective skills (writing style, design quality) are better evaluated qualitatively; don't force assertions onto things that need human judgment.

Update the `eval_metadata.json` files and `evals/evals.json` with the assertions once drafted. Also explain to the user what they'll see in the viewer, both the qualitative outputs and the quantitative benchmark.

## Step 3: As runs complete, capture timing data

When each subagent task completes, you receive a notification containing `total_tokens` and `duration_ms`. Save this data immediately to `timing.json` in the run directory, beside `outputs/`:

```json
{
  "total_tokens": 84852,
  "duration_ms": 23332,
  "total_duration_seconds": 23.3
}
```

This is the only opportunity to capture this data: it comes through the task notification and isn't persisted elsewhere. Process each notification as it arrives rather than trying to batch them.

## Step 4: Grade, aggregate, and launch the viewer

Once all runs are done:

1. **Grade each run**: spawn a grader subagent (or grade inline) that reads `agents/grader.md` and evaluates each assertion against the outputs. Save results to `grading.json` in each run directory, beside `outputs/`. The grading.json expectations array must use the fields `text`, `passed`, and `evidence` (not `name`/`met`/`details` or other variants); the viewer depends on these exact field names. For assertions that can be checked programmatically, write and run a script rather than eyeballing it: scripts are faster, more reliable, and can be reused across iterations.

2. **Aggregate into benchmark**: run the aggregation script with `<creating-skills-path>` (this skill's folder) as the working directory:
   ```bash
   cd <creating-skills-path> && python -m scripts.aggregate_benchmark <workspace>/iteration-N --skill-name <name>
   ```
   This writes `benchmark.json` and `benchmark.md` into `iteration-N/` with pass_rate, time, and tokens for each configuration, with mean ± stddev and the delta (with_skill or new_skill minus the baseline). If generating benchmark.json manually, see `references/schemas.md` for the exact schema the viewer expects.

3. **Check the leading words**: a skill steers through its leading words, the compact concepts its description and body lean on (see "Leading words" in `references/writing-great-skills.md`). Before you grep, list them: read the description and body and write down each such word (for example _tracer bullets_, _red_, _tight_). Leave out a word the eval prompt itself contains: a hit would only echo the prompt. Then count each word, as a whole word, in every with_skill run's transcript:
   ```bash
   grep -s -c -i -w '<word>' <workspace>/iteration-N/*/with_skill/outputs/transcript.md <workspace>/iteration-N/*/with_skill/run-*/outputs/transcript.md
   ```
   The transcript is the executor's written log of its plan and reasoning, not its raw hidden thinking. A leading word that is absent from a run's reasoning and plan (a count of 0) is a steering failure, even when every assertion passes: the agent did not think with the word, so the skill did not steer that run. Write down each miss, hand the list to the analyst pass below, and fix it before the next iteration, per `references/writing-great-skills.md`: pick a stronger word, or anchor the word at the step where it should act.

4. **Do an analyst pass**: read the benchmark data and surface patterns the aggregate stats might hide. See `agents/analyzer.md` (the "Analyzing Benchmark Results" section) for what to look for: things like assertions that always pass regardless of skill (non-discriminating), high-variance evals (possibly flaky), and time/token tradeoffs. Write the analyzer's notes array into the `notes` field of `iteration-N/benchmark.json` (the script leaves it `[]`), so the viewer shows them.

5. **Launch the viewer** with both qualitative outputs and quantitative data:
   ```bash
   nohup python <creating-skills-path>/eval-viewer/generate_review.py \
     <workspace>/iteration-N \
     --skill-name <name> \
     --benchmark <workspace>/iteration-N/benchmark.json \
     > /dev/null 2>&1 &
   VIEWER_PID=$!
   ```
   For iteration 2+, also pass `--previous-workspace <workspace>/iteration-<N-1>`.

   With no display (a remote box), pass `--static <output_path>` to write a standalone HTML file instead of starting a server; `references/other-surfaces.md` covers how `feedback.json` comes back then.

   After the runs finish, build the viewer with `generate_review.py` and put it in front of the user before you judge the quality of the outputs yourself; it beats writing custom HTML.

6. **Tell the user** something like: "I've opened the results in your browser. There are two tabs: 'Outputs' lets you click through each test case and leave feedback, 'Benchmark' shows the quantitative comparison. When you're done, come back here and let me know."

## What the user sees in the viewer

The "Outputs" tab shows one test case at a time:

- **Prompt**: the task that was given
- **Output**: the files the skill produced, rendered inline where possible
- **Previous Output** (iteration 2+): collapsed section showing last iteration's output
- **Formal Grades** (if grading was run): collapsed section showing assertion pass/fail
- **Feedback**: a textbox that auto-saves as they type
- **Previous Feedback** (iteration 2+): their comments from last time, shown below the textbox

The "Benchmark" tab shows the stats summary: pass rates, timing, and token usage for each configuration, with per-eval breakdowns and analyst observations.

Navigation is via prev/next buttons or arrow keys. When done, they click "Submit All Reviews" which saves all feedback to `iteration-N/feedback.json`.

## Step 5: Read the feedback

When the user tells you they're done, read `<workspace>/iteration-N/feedback.json` (schema in `references/schemas.md`; a `run-<n>` run's id ends in `-run-<n>`, as in `eval-1-chart-axis-labels-with_skill-run-1`):

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
