---
type: llm
---

The line to judge is the rule `descriptive variable names` (the draft says: "Use descriptive variable names and keep functions short, so the code stays easy to read."). It is ordinary engineering advice a capable agent already follows, so the deletion test cuts it even though it is correct.

Judge only the cut SKILL.md that the response pastes back in full. Ignore any keep or delete table, list of cuts, or prose about the cut: the line appearing there does not FAIL. Do not judge whether the response ran a baseline eval; skipping that run, or only naming it, is not a FAIL.

PASS if the pasted-back SKILL.md holds no rule about descriptive variable names, short functions, or readable code, in the original or any reworded form. FAIL if such a rule remains in the pasted-back SKILL.md, or if the response pastes back no full cut SKILL.md.
