---
name: practicing-a-topic
description: Use when the user wants adaptive practice or later recall on something already studied, especially from a learning record, notes or earlier lesson. For example "practice attention from yesterday's record" or "test whether I can still use MVCC in new situations". Not for a first lesson, a printable quiz, or a briefing of blind spots.
---

# Practicing a Topic

Exercise recall and transfer, rather than explaining a topic from the beginning.
Ask one problem at a time and adapt to the learner's observed reasoning.

## Load the evidence

Read [learning-record.md](../quizzing-a-topic/references/learning-record.md) and
[storage.md](../quizzing-a-topic/references/storage.md). Apply their record,
destination, evidence and write rules. Load the named record or sources and
relevant prior attempts. Create a new practice record linked to the earlier one;
resume the same practice record only when asked to continue it.

If no history is available, begin with one diagnostic problem on the named topic
and mark prior understanding unknown. Ask one scope question only if the topic
is unbounded. Never invent a prior lesson. If the user actually wants first
instruction, use `learning:quizzing-a-topic`; a concept to reconstruct belongs to
`learning:rebuilding-a-concept`. Reuse user-supplied problems when requested.

## Practice loop

1. Choose one or a few precise target claims, prioritizing unresolved gaps and
   assisted attempts. Read their sources and verify the reference solution
   before posing the problem. Hold the solution back from the learner.
2. Pose a short problem that calls for those ideas without naming the method the
   learner must recall. Start with achievable difficulty, not a trick. Ask for
   the answer and a short explanation; invite confidence without requiring it.
   Wait for the learner. Do not fabricate their working to advance the loop.
3. Record the attempt before feedback. Judge the reasoning, not merely the final
   answer. Record partial correctness and uncertainty in the assessment.
4. If stuck, give the smallest useful hint and wait. Escalate only as needed.
   After three unsuccessful hints, offer a brief re-teach; give the answer when
   requested. Keep hints and exposure attached to that problem. A successful
   retry remains assisted even after a turn boundary or session resume.
5. For a later independent check, use a fresh problem whose solution has not
   been exposed. Change the operation, assumptions or context enough to require a new reasoning
   decision; merely renaming variables or wrapping the same equation in a new
   story does not test transfer. Do not recycle the same question
   and reset its hint counter. Recent teaching is still noted as context.
6. Adjust one difficulty dimension at a time: familiarity of cues or number of
   combined ideas. Repeated failures call for a simpler case or a prerequisite
   repair; immediate success calls for a less familiar application. Aim for
   effortful success, not an arbitrary perfect score.
7. Save the assessment and next action before the next problem. On stop, save
   an incomplete checkpoint with pending questions. End with the specific
   evidence collected and gaps remaining, not a blanket declaration of mastery.

## Interaction

Prefer open problems for transfer. Use multiple choice for diagnosis only when
it helps, with shuffled answers and no correct-answer tells. On Claude Code use
`AskUserQuestion` if available; on Codex and Cursor use the host's supported
question interface or plain chat. Ask for open reasoning in normal conversation
and wait for the response. Never expose the key in an option description.

Do not generate a long worksheet unless requested. Do not create reminders,
change schedules, or rewrite canonical concept notes as a side effect. When
asked for saved review material, use the existing storage/format adapter.
