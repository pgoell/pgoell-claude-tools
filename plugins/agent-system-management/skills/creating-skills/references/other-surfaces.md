# Other Surfaces: Claude.ai, Cowork, Packaging

Read this before running test cases when you have no subagents (Claude.ai), no browser or display (Cowork, a remote box), or a `present_files` tool: it says which steps of SKILL.md change.

## Claude.ai

In Claude.ai, the core workflow is the same (draft → test → review → improve → repeat), but because Claude.ai doesn't have subagents, some mechanics change. Here's what to adapt:

**Running test cases**: No subagents means no parallel execution. For each test case, read the skill's SKILL.md, then follow its instructions to accomplish the test prompt yourself. Do them one at a time. This is less rigorous than independent subagents (you wrote the skill and you're also running it, so you have full context), but it's a useful sanity check, and the human review step compensates. Skip the baseline runs, just use the skill to complete the task as requested.

To check the leading words (SKILL.md Step 4) without subagents, write your plan and reasoning to `<workspace>/iteration-<N>/eval-<id>-<name>/with_skill/outputs/transcript.md` for each run as you work (keep the `with_skill/` level even without baselines, so Step 4's grep finds it), then grep those files for each leading word as Step 4 shows. You wrote the skill, so its words are already on your mind and the check fails less often than it should; treat a pass as weak evidence.

**Reviewing results**: If you can't open a browser (e.g., Claude.ai's VM has no display, or you're on a remote server), skip the browser reviewer entirely. Instead, present results directly in the conversation. For each test case, show the prompt and the output. If the output is a file the user needs to see (like a .docx or .xlsx), save it to the filesystem and tell them where it is so they can download and inspect it. Ask for feedback inline: "How does this look? Anything you'd change?"

**Benchmarking**: Skip the quantitative benchmarking: it relies on baseline comparisons which aren't meaningful without subagents. Focus on qualitative feedback from the user.

**The iteration loop**: Same as before (improve the skill, rerun the test cases, ask for feedback), just without the browser reviewer in the middle. You can still organize results into iteration directories on the filesystem if you have one.

**Description optimization**: The automated loop requires the `claude` CLI tool (specifically `claude -p`) which is only available in Claude Code. On Claude.ai, verify triggering manually instead: after the user uploads and enables the skill, have them try several prompts that should trigger it, check Claude's thinking to confirm the skill loads, and iterate on the description when it misses. Keep the description within claude.ai's 200-character cap.

**Blind comparison**: Requires subagents. Skip it.

**Packaging**: The `package_skill.py` script works anywhere with Python and a filesystem. On Claude.ai, you can run it and the user can download the resulting `.skill` file.

**Updating an existing skill**: The user might be asking you to update an existing skill, not create a new one. In this case:

- **Preserve the original name.** Note the skill's directory name and `name` frontmatter field, and use them unchanged. E.g., if the installed skill is `research-helper`, output `research-helper.skill` (not `research-helper-v2`).
- **Copy to a writeable location before editing.** The installed skill path may be read-only. Copy to `/tmp/skill-name/`, edit there, and package from the copy.
- **If packaging manually, stage in `/tmp/` first**, then copy to the output directory. Direct writes may fail due to permissions.
- **Match the upload format.** The archive must contain the skill folder as its root (not loose files, not a nested wrapper), and the folder name must match the skill name. `package_skill.py` produces this shape; replicate it when zipping by hand.

## Cowork

If you're in Cowork, the main things to know are:

- You have subagents, so the main workflow (spawn test cases in parallel, run baselines, grade, etc.) all works. (However, if you run into severe problems with timeouts, it's OK to run the test prompts in series rather than parallel.)
- You don't have a browser or display, so when generating the eval viewer, use `--static <output_path>` to write a standalone HTML file instead of starting a server. Then proffer a link that the user can click to open the HTML in their browser.
- Cowork tends to skip the eval viewer after the test runs. Build it with `generate_review.py` anyway, as SKILL.md Step 4 says, and show it to the user before you judge the outputs yourself.
- Feedback works differently: since there's no running server, the viewer's "Submit All Reviews" button will download `feedback.json` as a file. You can then read it from there (you may have to request access first). Copy `feedback.json` to `<workspace>/iteration-<N>/feedback.json` so the next iteration picks it up. The same holds on any headless box where you used `--static`.
- Packaging works: `package_skill.py` just needs Python and a filesystem.
- Description optimization (`run_loop.py` / `run_eval.py`) should work in Cowork just fine since it uses `claude -p` via subprocess, not a browser, but please save it until you've fully finished making the skill and the user agrees it's in good shape.
- **Updating an existing skill**: The user might be asking you to update an existing skill, not create a new one. Follow "Updating an existing skill" in the Claude.ai section of this file.
- Put "Create evals JSON and run `eval-viewer/generate_review.py` so human can review test cases" in your TodoList, if you have one, to make sure it happens.

## Package and present

Do this when you have the `present_files` tool, or when the user wants a `.skill` file to upload. First sweep the skill directory: every file referenced from SKILL.md exists (the packaging validator warns on broken markdown links, but backtick path references still need a manual check), and no bundled file carries secrets, since a packaged skill is a shared artifact. Then package the skill and present the .skill file to the user (with `present_files` if you have it):

```bash
python -m scripts.package_skill <path/to/skill-folder>
```

After packaging, direct the user to the resulting `.skill` file path so they can install it.
