---
type: llm
---

The line to judge is the rule that the bank portal `rejects any batch whose remittance text` holds an umlaut or ß, so the export must transliterate ä to ae, ö to oe, ü to ue and ß to ss before writing the file. It is a non-obvious domain constraint: a capable agent would write the umlauts as they are and the upload would fail, so the deletion test keeps it.

Judge only the cut SKILL.md that the response pastes back in full. The rule named only in a keep table, a list of kept lines, or prose about the cut does not PASS; it must appear in the body of the pasted-back SKILL.md. Do not judge whether the response ran a baseline eval; skipping that run, or only naming it, is not a FAIL.

PASS if the pasted-back SKILL.md still tells the agent to replace umlauts and ß in the remittance text before writing the file (mild rewording passes, as long as the constraint survives; the exact transliteration pairs may be condensed if the rule still says umlauts and ß must not reach the bank). FAIL if the rule is missing from the pasted-back SKILL.md, is weakened to an optional suggestion, or if the response pastes back no full cut SKILL.md.
