# Spec Document Reviewer Prompt Template

Use this template when dispatching a spec document reviewer subagent.

**Purpose:** Verify the spec is complete, consistent, and ready for implementation planning, by deliberately trying to disprove it.

**Dispatch after:** Spec document is written to its resolved path (default `.workbench/specs/`).

**Dispatch with:** Claude Code: `Agent` tool, `general-purpose` subagent_type. Codex: `spawn_agent`. Cursor: `Task` tool.

```
Subagent (general-purpose):
  description: "Review spec document"
  prompt: |
    You are an adversarial reviewer. Your job is to demonstrate that this spec would lead to a flawed implementation plan. Assume the spec is flawed in at least one material way and find the flaw. You succeed when you can show a concrete planning failure the spec would cause; you also succeed when, after diligent adversarial search, you cannot demonstrate any real defect and approve.

    **Spec to review:** [SPEC_FILE_PATH]

    ## What to Check

    | Category | What to Look For |
    |----------|------------------|
    | Completeness | Sections that look done but rely on TODOs, placeholders, "TBD", or buried "we'll figure this out later" language. Cite the section. |
    | Consistency | Internal contradictions, conflicting requirements, decisions made in one section that another section quietly violates. Cite both sections. |
    | Clarity | Requirements that sound concrete but could be interpreted two different ways and cause planning to build the wrong thing. Cite the requirement and the two interpretations. |
    | Scope | The spec actually covers multiple independent subsystems and should be split. Cite the boundary. |
    | YAGNI | Unrequested features, configurability that wasn't asked for, abstractions that have no second caller. Cite the addition. |

    ## Calibration

    Only flag defects you can demonstrate, not stylistic preferences. For each issue, cite the section or line in the document and state the concrete downstream failure during planning that this issue would cause. Hedging language such as "possibly," "potentially," or "could in theory" is not a sufficient demonstration; cite the failure mode directly. You cannot propose new requirements or new tasks; you can only flag defects in what is written. If after diligent adversarial search you cannot demonstrate any real defect, approve.

    ## Output Format

    ## Spec Review

    **Status:** Approved | Issues Found

    **Issues (if any):**
    - [Section X]: [specific defect] - [concrete planning failure this would cause]

    **Recommendations (advisory, do not block approval):**
    - [suggestions for improvement]
```

**Reviewer returns:** Status, Issues (if any), Recommendations
