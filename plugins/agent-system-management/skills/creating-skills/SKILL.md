---
name: creating-skills
description: Create new skills, modify and improve existing skills, and measure skill performance. Use when users want to create a skill from scratch, edit, or optimize an existing skill, run evals to test a skill, benchmark skill performance with variance analysis, or optimize a skill's description for better triggering accuracy. Also use when the user asks to cut, trim, shorten, or de-slop a skill (a SKILL.md and its references, not an AGENTS.md or CLAUDE.md), or to make it trigger less eagerly.
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
- **Optional fields** (`disable-model-invocation`, `user-invocable`, `compatibility` / `dependencies`, and Claude Code's further fields): read "Optional frontmatter fields" in `references/skill-writing-guide.md` before you set one.
- **the rest of the skill :)**

### Skill Writing Guide

Before you lay out the skill's files and write its body, read `references/skill-writing-guide.md`: the anatomy of a skill folder, progressive disclosure (what stays in SKILL.md and what goes behind a pointer), the principle of lack of surprise (no malware, no hardcoded secrets), the writing patterns (output formats, examples, arguments, dynamic context injection, wrapping CLIs and APIs, feedback loops), and the writing style (explain the why, calibrate specificity, match the form of a fix to the failure).

#### Skills in plugin marketplace repos

When the skill lives in a repo that distributes plugins (a marketplace manifest at the repo root, a directory of plugins), writing SKILL.md is only half the job: the skill must be registered in the marketplace manifest, the plugin version bumped, index docs updated, and the repo's checks passed. Discover the host repo's conventions (author, license, commit style, version-tracking files) from its existing plugins rather than inventing values. `references/marketplace-integration.md` has the discovery checklist, wiring steps, version discipline, and drop-in test scaffolds. A repo may cap file size (pgoell-claude-tools: 5000 tokens, bytes/4). A SKILL.md over the cap moves step detail into `references/`, loaded by the step that needs it: a deep split, not a cut by line count.

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

If you have no subagents (Claude.ai), no browser or display (Cowork, a remote box), or a `present_files` tool, read `references/other-surfaces.md` first: it says which steps below and in `references/running-evals.md` change.

This section is one continuous sequence: don't stop partway through. Do NOT use `/skill-test` or any other testing skill.

Put results in `<skill-name>-workspace/` as a sibling to the skill directory. Within the workspace, organize results by iteration (`iteration-1/`, `iteration-2/`, etc.) and within that, each test case gets a directory `eval-<id>-<name>/`, where `<id>` is the test case's `id` in `evals/evals.json` (ids start at 1) and `<name>` is a short descriptive name (for example `eval-1-chart-axis-labels/`). Don't create all of this upfront, just create directories as you go.

Read `references/running-evals.md` before the first run and follow its Steps 1 to 5 in order: spawn all runs (with-skill AND baseline) in the same turn, draft assertions while they run, capture timing data as each completes, grade, aggregate and launch the viewer, then read the feedback.

---

## Improving the skill

This is the heart of the loop. You've run the test cases, the user has reviewed the results, and now you need to make the skill better based on their feedback.

First check you're in the right loop. If the skill produces the right outputs but rarely fires, the body is fine and the description is the problem: go to Description Optimization. If it fires but the outputs are wrong, iterate on the body here. If it fires and the agent bypasses its rules under pressure, that's a discipline problem: pressure-test per `references/bulletproofing.md` instead of polishing prose.

### How to think about improvements

Before you revise the skill, read `references/improving-skills.md`: generalize from the feedback, keep the prompt lean, explain the why, look for repeated work across test cases, and micro-test contested wording.

### The iteration loop

After improving the skill:

1. Apply your improvements to the skill (in Claude Code, edits to personal and project skills take effect within the current session; plugin skills need `/reload-plugins`)
2. Rerun all test cases into a new `iteration-<N+1>/` directory, including baseline runs (Steps 1 to 5 of `references/running-evals.md`). If you're creating a new skill, the baseline is always `without_skill` (no skill); that stays the same across iterations. If you're improving an existing skill, use your judgment on what makes sense as the baseline: the original version the user came in with, or the previous iteration.
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

The description field in SKILL.md frontmatter is the primary mechanism that determines whether Claude invokes a skill. After creating or improving a skill, offer to optimize the description for better triggering accuracy. The loop in `references/description-optimization.md` needs `claude -p`; on claude.ai, check triggering by hand as `references/other-surfaces.md` says.

Read `references/description-optimization.md` and follow its steps: generate trigger eval queries, review them with the user, run the optimization loop, and apply the result within the length limits. It also explains how skill triggering works and how to keep a trigger regression test.

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

- `references/skill-writing-guide.md`: optional frontmatter fields, skill anatomy, progressive disclosure, lack of surprise, writing patterns and style. Read it when you lay out a skill and write its body.
- `references/running-evals.md`: Steps 1 to 5 of running and evaluating test cases. Read it before you run test cases.
- `references/improving-skills.md`: how to think about improvements. Read it before each revision of a skill body.
- `references/description-optimization.md`: trigger eval queries, the optimization loop, how triggering works, the trigger regression test. Read it when you optimize a description.
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
