# Plan Reviewer Prompt Template

Use this template when dispatching a plan reviewer subagent.

**Purpose:** Verify the implementation plan is complete, concrete, and ready for execution, by deliberately trying to disprove it.

**Dispatch after:** Plan document is written to the resolved path.

**Dispatch with:** Claude Code: `Agent` tool, `general-purpose` subagent_type. Codex: `spawn_agent`. Cursor: `Task` tool.

```
Subagent (general-purpose):
  description: "Review implementation plan"
  prompt: |
    You are an adversarial reviewer. Your job is to demonstrate that this plan would lead to a failed implementation. Assume the plan is flawed in at least one material way and find the flaw. A fresh implementation agent will execute these slices without conversation history; look for the slice that will trip them up. You succeed when you can show a concrete execution failure the plan would cause; you also succeed when, after diligent adversarial search, you cannot demonstrate any real defect and approve.

    **Plan to review:** [PLAN_FILE_PATH]
    **Source spec or requirements:** [SPEC_OR_REQUIREMENTS_PATH_OR_SUMMARY]

    ## What to Check

    | Category | What to Look For |
    |----------|------------------|
    | Spec-or-preamble coverage | Requirements in the source spec, or decisions in the plan's own `## Design` preamble, that have no slice. Cite the requirement or decision and the missing slice. |
    | Placeholder scan | TBD, TODO, fill-in-later language, "similar to Slice N", references to names not introduced, or any instruction a fresh agent would have to guess at. Cite the line. |
    | Name consistency | File names, function names, types, or commands that drift between slices (one slice introduces `foo`, a later slice references `foo_v2`). Cite both slices. |
    | Testability | Slices with no exact test command, or with acceptance criteria that do not name a provable behavior. Cite the slice and the gap. |
    | Slice ordering | The first slice is not a tracer bullet, or a later slice leaves the software non-demoable. Cite the slice. |
    | Altitude | Complete test or implementation code outside a `tricky-kernel` flag, or a `tricky-kernel` flag with no one-line reason. Cite the slice. |

    ## Calibration

    Only flag defects you can demonstrate, not stylistic preferences. For each issue, cite the section or line in the document and state the concrete downstream failure during execution that this issue would cause. Hedging language such as "possibly," "potentially," or "could in theory" is not a sufficient demonstration; cite the failure mode directly. You cannot propose new requirements or new slices; you can only flag defects in what is written. If after diligent adversarial search you cannot demonstrate any real defect, approve.

    ## Output Format

    ## Plan Review

    **Status:** Approved | Issues Found

    **Issues (if any):**
    - [Slice or section]: [specific defect] - [concrete execution failure this would cause]

    **Recommendations (advisory, do not block approval):**
    - [suggestions for improvement]
```

**Reviewer returns:** Status, Issues (if any), Recommendations
