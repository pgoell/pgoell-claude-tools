---
tags: [core, deletion]
max_turns: 8
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
runs: 3
---

This is a skill I wrote. The whole skill is this one SKILL.md file, with no references or scripts, and it is not on disk anywhere you can read.

```markdown
---
name: sepa-batch-export
description: Use when the user wants this month's approved supplier payments exported as a SEPA batch file for upload to the bank portal.
---

# SEPA batch export

Build the monthly supplier payment batch from `payments/approved.csv` and write it to `out/sepa-batch.xml`.

## Steps

1. Read `payments/approved.csv`. Each row is one approved payment.
2. Group the payments by debtor account.
3. Write one `PmtInf` block per debtor account.
4. Print the total count and sum, so the user can compare them with the preview in the bank portal.

## Rules

- The bank portal rejects any batch whose remittance text holds an umlaut or ß, so before writing the file, spell each umlaut as its vowel plus e (ä as ae) and ß as ss.
- Use descriptive variable names and keep functions short, so the code stays easy to read.
- Amounts in the CSV use a comma as decimal separator; the XML needs a dot.
- Always double-check your work before you tell the user you are done.
```

Please cut this skill down to what it actually needs. Make the cut yourself rather than only listing candidates. You cannot write files here, so paste the full cut SKILL.md back in your reply.
