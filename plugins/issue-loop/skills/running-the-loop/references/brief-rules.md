# The brief, rule by rule

`rules.md` in the loop folder is the brief every task gets, below the task line. Each rule is there because of a fault that happened. Drop a rule whose fault cannot happen in your repo; keep the ones marked **core**, since the scripts or the orchestrator's routine lean on them.

The numbers below come from the example project, a web app built by this loop over two days.

| Rule | In short                                                | The fault that earned it                                                                                                                           | Drop it when                                |
| ---- | ------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------- |
| 1    | A bar, and where it ends                                | "A gap is a blocker" with no edge: one task added 9 items of its own, took 133 minutes and never merged. The ask was met at minute 13              | never; write a bar that fits the product    |
| 2    | **core** Checklist first, one outside look, then frozen | Same task. With the freeze, 22 of 22 tasks wrote the list first and the median fell to 40 minutes. The gate counts the boxes                       | never                                       |
| 3    | Subagents code; fixes go back to the same subagent      | The main session's context is the scarce thing. Fresh subagents reread every file; one harness was rebuilt by 10 of 10 subagents                   | tiny repos, where the main session may code |
| 4    | Edit tool only; no chained edit and test                | 35 heredocs and 9 `sed -i` in one session, none reviewable. A chained `git checkout` reverted a folder of source                                   | never while several agents share a checkout |
| 5    | Tests are the proof; single tests while working         | The suite ate 72 of 136 minutes. A test filter matched a file name and ran the whole file. Tests "passed" that nobody saw fail                     | never; change the commands to yours         |
| 6    | Look once, with a script                                | Clicking by hand through a browser tool is slow and misses a 20 ms race                                                                            | no user interface                           |
| 7    | **core** One review, at most 10 findings, tagged A to D | An open review took 28 minutes and its fixes 37 more. With the bar, review found real faults in 20 of 22 tasks at a median of 6 minutes            | never                                       |
| 8    | Git: fresh branch, the repo's commit rules, push early  | CI runs while the review runs; a PR title check failed 3 merges that went through anyway                                                           | never; change to your rules                 |
| 9    | Merge and deploy with one bounded wait                  | Three stalls of 600 seconds waiting on a hung CI job                                                                                               | no deploy: cut the deploy half              |
| 10   | **core** Time box: 60 minutes, then cut and finish      | Tasks of 70 to 135 minutes. The box is self-reported, so `wait.sh` has the real clock                                                              | never                                       |
| 11   | Hands off what is not yours                             | Other sessions' PRs and uncommitted work in the same repo                                                                                          | never                                       |
| 12   | **core** The final report and the exact DONE line       | `wait.sh` settles on that line; the orchestrator reads "Not fixed", "Slips" and "Issues opened"                                                    | never                                       |
| 13   | "A thing" means every kind of the thing                 | A feature shipped for some block types and filed the rest as follow-ups                                                                            | your issues cannot be read that way         |
| 14   | Live data: rehearse, back up, compare                   | A PR rebuilt a live table with no backup                                                                                                           | no stored data                              |
| 15   | **core** Severity beats the frozen list                 | 12 faults shipped; 7 were known to the task before its own merge and parked as "outside the list". One let an account paste another account's data | never                                       |
| 16   | The machine's own parts get a second review             | The loop changes its own CI, deploy and hooks. A fault there takes the loop or the data down                                                       | the loop may not touch those files at all   |
| 17   | Label every opened issue; at most 2 wishes              | 82 issues filed in 22 tasks, 53 without a label, 38 of them wishes. Nobody could put the queue in order                                            | never                                       |
| 18   | Do not work around a refusal                            | Auto mode and the fence hook only help if a refused session stops instead of finding another door                                                  | never                                       |

## The eight ideas behind the rules

If you rewrite the brief for another kind of project, keep these:

1. **Frozen checklist.** Scope is decided once, before code, with one outside look. Later finds are fixed (own fault), filed (old fault) or noted (nitpick).
2. **Tests as proof.** Each box names its test. Each test was seen failing.
3. **One review with a bar.** A fresh reviewer, a cap on findings, severity tags, a time limit.
4. **Time box.** With a rule for what to cut, so that nothing is dropped.
5. **Severity beats the frozen list.** The freeze must not become the place to park a known fault.
6. **Second review for the machine's own parts.** With one question: what breaks, and how do we get back?
7. **Labels on opened issues.** The task that finds a fault knows best what kind it is.
8. **The exact DONE line.** A machine reads it.

## Changing the brief while the loop runs

- A slip seen once goes into the next task line ("tell every subagent rule 4").
- A slip seen twice, or a fault that reached live, becomes a rule or a clause in `rules.md`. It applies from the next task. Tell the user and note it in `HANDOFF.md`.
- A rule that binds the user (who merges, what waits for them) changes only on their word. Write their words and the date into `HANDOFF.md`.
- Rules in prose are weak. One of the brief's rules ("back up first") was checked by nothing, and the 60 minutes were self-reported. Where a rule matters, build a check: a gate script line, a CI job, a hook.
