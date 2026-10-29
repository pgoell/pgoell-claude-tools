# The gate and the report

Step 4 of "One turn of the loop" in `SKILL.md` runs `./gate.sh 41 38 39` and reads the implementer's report. This page says what a pass means and what to read.

## What `GATE PASS` means

`GATE PASS` means: issues closed, every PR since the task began merged with no open box and with each ticked box naming its test (`Test:` or `Proof:` on its line or an indented line under it), the live commit is the head of the base branch, the checkout is clean, the app answers.

## Reading the report

The screen keeps only about 70 lines of it (`. ./lib.sh; drv_read "$IMPL" 130` shows what is left), so read the headings in capitals and "Not fixed" from the PR body, where rule 12 puts them too (`gh pr view N --json body,comments`). Read these parts of the report above all:

- **Not fixed**: review findings the task left in.
- **Slips**: rules the task broke (a test bent to pass, an unreviewed commit).
- **Issues opened**: this is where shipped faults hide. For each, ask: is it a gap in what was asked, a privacy or data fault, or something that hides the product's main function? If yes, it runs NEXT.
- **OUTPUT CHANGES**: what the product now puts out differently for the same input (a print, an export). Tell the user each line; nobody asked for most of them.
- **Heads up** lines at the bottom of the session's screen.

## Check what the gate cannot

If the task touched stored data (`TOUCHES LIVE DATA`), open the live data read-only and compare integrity and row counts with your baseline in `HANDOFF.md`. Do that also when the report says "DATA FAULT ON LIVE: none": the line is the task's word, the rows are the check. Tell the user each line under "CAN STILL LOSE". If it touched the machine (`TOUCHES THE MACHINE`, or a `TELL HUMAN` line from the gate), check the changed part on the real thing and tell the user what changed and the way back.
