---
name: test-driven-development
description: "Deprecated and retired without replacement. Formerly used when implementing any feature, bugfix, refactor, or behavior change before writing implementation code. Enforces test-first RED-GREEN-REFACTOR discipline."
---

# Test-Driven Development

> **Deprecated.** Retired without replacement. This copy is archived and no longer maintained.

Use this skill before implementation work. It governs each small implementation chunk until the change is complete.

## Core Rule

Write the test first. Watch it fail for the expected reason. Write the smallest code that makes it pass. Refactor only after green.

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

If implementation code was written before the test, delete that implementation and restart from the test. Do not keep it as reference material.

## When To Use

Use for:

- New features.
- Bug fixes.
- Refactoring that can change behavior.
- Any user-visible behavior change.

Exceptions require an explicit user decision:

- Throwaway prototypes.
- Generated code.
- Pure configuration changes.

## Outer and Inner Loops

TDD runs as two nested feedback loops, not one.

The outer loop is acceptance-test driven. For each slice of behavior, write a failing acceptance test that exercises the feature from outside the unit boundary. Watch it fail for the right reason. Then drive inner cycles until that acceptance test goes green.

The inner loop is red-green-refactor as described in the next section. It runs many times inside one outer-loop iteration: one inner cycle per unit-level behavior needed to satisfy the acceptance test.

When the acceptance test passes, refactor at the slice boundary if useful, then start the outer loop again with the next slice.

"Acceptance test" here means any test that exercises the slice from outside the unit boundary; an integration test or end-to-end test fits the same role when the project uses that language.

Source: Freeman and Pryce, Growing Object-Oriented Software Guided by Tests, Figure 1.2.

## Red-Green-Refactor

### RED: Write One Failing Test

Write the smallest test that expresses one expected behavior.

Requirements:

- One behavior per test.
- Clear name that describes the expected behavior.
- Real code when possible. Use mocks only when the boundary is external or expensive.
- No broad "works" tests.

### Verify RED

Run the narrowest useful test command.

Confirm:

- The test fails.
- The failure is the expected assertion or missing behavior.
- The failure is not a syntax error, setup error, typo, or unrelated broken test.

If the test passes immediately, it does not prove the new behavior. Fix the test before writing implementation code.

### GREEN: Write Minimal Code

Write only the implementation needed for the failing test.

Do not add:

- Extra options.
- Future-proofing.
- Unrequested error handling.
- Refactors that are not needed for the current test.

### Verify GREEN

Run the narrow test again and confirm it passes. Then run the relevant broader test command for the touched area.

If the test fails, fix implementation code first. Only change the test if the expected behavior is wrong.

### REFACTOR

The third step of the cycle, not an optional polish pass. GREEN intentionally produced the smallest code that worked; REFACTOR is where that intentional sloppiness is paid back on the same cycle, before the next test compounds it.

Refactor passes (each one followed by Verify GREEN):

- Improve names so the next reader does not need to re-derive intent.
- Remove duplication, both inside the new code and against code already nearby.
- Move code into existing local patterns instead of inventing new ones.
- Tighten or split tests that have grown vague, overlapping, or coupled to the implementation.

Rules:

- Keep the same tests green after every refactor. Never change tests and implementation in the same step; if both need to move, do them as two refactors with a verify in between.
- One refactor at a time, then rerun the narrow tests before the next change. Multi-change refactors hide which step broke green.
- Stop when the chunk's design matches the local patterns; do not invent new abstractions mid-cycle. New patterns belong in their own brainstorm, not a refactor.

Why this step is mandatory: Kent Beck states the two rules of TDD as "write new code only if you first have a failing test" and "eliminate duplication." The second rule is the REFACTOR step. Skipping it leaves duplication and unclear names in the codebase that the next chunk inherits, and the test safety net that makes refactoring cheap is most valuable in the same cycle that produced the code. Sources: Kent Beck, Test-Driven Development by Example, Section I (the two rules); Freeman and Pryce, Growing Object-Oriented Software Guided by Tests, Section 1.5 (refactoring after green to preserve internal quality).

## Good Tests

| Quality          | Good                               | Bad                                                 |
| ---------------- | ---------------------------------- | --------------------------------------------------- |
| Minimal          | One behavior.                      | A test name with "and" covering multiple behaviors. |
| Clear            | Name states the expected behavior. | `test1` or `works`.                                 |
| Behavior-focused | Exercises public behavior.         | Checks private implementation details.              |
| Repeatable       | Runs without manual state.         | Depends on local setup not created by the test.     |

## Common Rationalizations

| Excuse                                       | Response                                                                                                                                                                                                                             |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| "Too simple to test."                        | Simple code still breaks. Write the small test.                                                                                                                                                                                      |
| "I'll test after."                           | Tests written after implementation can pass without proving they catch the missing behavior.                                                                                                                                         |
| "I already manually tested it."              | Manual checks are not repeatable regression coverage.                                                                                                                                                                                |
| "The existing code has no tests."            | Add the narrowest test around the behavior you are changing.                                                                                                                                                                         |
| "Keeping the code as reference is harmless." | Reference code biases the test. Delete it and restart test-first.                                                                                                                                                                    |
| "TDD is slowing me down."                    | Debugging untested behavior is usually slower than proving it incrementally.                                                                                                                                                         |
| "Refactor later."                            | GREEN intentionally produced code below your bar; REFACTOR pays back the gap on the same cycle. Deferring it accumulates duplication and unclear names that the next chunk inherits, and the test safety net is cheapest to use now. |

## Red Flags

Stop and restart the chunk if any of these happen:

- Implementation code before a failing test.
- Test added after implementation.
- Test passes immediately.
- You cannot explain the failure.
- The failure is from setup or syntax instead of missing behavior.
- You are rationalizing "just this once."
- You are adapting code that was written before the test.
- You declared the cycle done after GREEN without doing the REFACTOR pass.

## Workflow With Plans

When executing a Workbench implementation plan, this skill is invoked as `deprecated:test-driven-development`:

1. Take one checkbox implementation chunk.
2. Write or update the outer-loop acceptance test for the chunk: the test that fails until the chunk's slice-level behavior works end to end.
3. Run the exact command and capture the expected outer-loop failure.
4. Drive inner red-green-refactor cycles inside the chunk until the outer-loop test passes.
5. Run the outer-loop command and relevant broader checks.
6. Mark the chunk complete only after the outer-loop test is green.

If a chunk is too large to test first, split the chunk. Hard-to-test behavior is usually underspecified or poorly isolated.

## Runtime Notes

Use the test runner documented by the project. In this repository, prefer deterministic filesystem checks for skill structure and run the frontmatter lint after changing any `SKILL.md`.
