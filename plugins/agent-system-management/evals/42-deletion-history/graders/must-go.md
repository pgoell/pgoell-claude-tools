---
type: llm
---

The line to judge is the history note that the platform team `retired in March 2025` the nightly cleanup cron job this skill took over from. It is history that does not change what the agent does next, so the deletion test cuts it.

Judge only the cut SKILL.md that the response pastes back in full. Ignore any keep or delete table, list of cuts, or prose about the cut: the line appearing there does not FAIL. Do not judge whether the response ran a baseline eval; skipping that run, or only naming it, is not a FAIL.

PASS if the pasted-back SKILL.md says nothing about the old cron job, its retirement, the platform team, or March 2025, in the original or any reworded form. FAIL if any of that history remains in the pasted-back SKILL.md, or if the response pastes back no full cut SKILL.md.
