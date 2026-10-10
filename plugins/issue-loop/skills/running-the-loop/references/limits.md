# Honest limits, and the stand-ins

Read this before you promise the user anything, and say these limits in your first report. The numbers come from an outside review of the example project (a web app, 22 tasks in 16 hours at the time of the review, later 19 more tasks in 21 hours). Some are measured, some are the review's guess; the review marks which, and so does this file.

## What the loop proves, and what not

The review's line: the loop is fast and honest, and its checks hold for logic.

- **Proven**: what tests can drive. Flows by mouse and key in a headless browser, the saved state after each action, account isolation, a schema move.
- **Not proven**: taste. Layout, wording, whether a flow feels right. Also what a headless browser fakes: native controls, real touch, print against screen, whether old stored data still opens.
- Tests can be hollow. Of 340 tests named in PRs, about 5 checked their own setup and 6 would pass with the feature gone.

## What it ships by mistake

- 12 of its own faults shipped in 22 tasks; 10 reached the live site, for 32 minutes to almost 9 hours. One was a privacy fault. None lost data.
- **7 of the 12 were known to the task before its own merge.** The frozen checklist had made "outside the list" the place to park them. Rule 15 of the brief blocks that, and it still failed once. So read "Issues opened" after every task: the orchestrator's reading caught more shipped faults than any other check.
- 4 issues said "the base branch has it" when a loop PR had brought the fault in.

## The queue grows

- Each task files 2 to 6 issues (3.7 on average, measured).
- Feature tasks: 16 closed, 52 filed. Bug batches of five: 29 closed, 30 filed.
- Most of what is filed are wishes. The bug queue can reach zero; the wish list never will. That is why wishes wait for the user's `go`.

## Cost and time

- 45 to 100 minutes per task, about 69 on average over 19 tasks.
- About 25 to 30 dollars per task at list prices (read from the session's own status line; a guess as a total).
- The orchestrator's context filled to over 200k tokens before the first planned handover. Hand over at 150k.

## Nobody uses the product

No check in the loop is a person who uses the product for its purpose. Real users are the true inspection, and the loop has none. Everything below is a stand-in.

## Gates that were theatre

Found by the review. Each looked like a check and stopped nothing.

| Gate                                   | Why it stopped nothing                                                    | What replaced it                                           |
| -------------------------------------- | ------------------------------------------------------------------------- | ---------------------------------------------------------- |
| Branch protection                      | The agent's token was an admin's, admins were not bound, no review needed | the fence hook refuses admin merges; the user binds admins |
| "Back up the live data first" (a rule) | Prose. Nothing looked for the file                                        | the deploy takes the snapshot itself                       |
| Deploy check: front page answers       | 200 on a dead app                                                         | a route that reads the database; a smoke test              |
| The 60 minute rule                     | Self-reported                                                             | `wait.sh` reads the clock                                  |
| "0 open boxes"                         | Looked at the newest PR only                                              | `gate.sh` reads every PR since the task began              |
| The DONE match                         | Any line that began with DONE                                             | `wait.sh` wants this task's token                          |
| "Subagents code"                       | The main session edited in 17 of 22 tasks                                 | nothing; a few lines are allowed, watch "Slips"            |

What held from the start: required checks, and a deploy only from a green base branch (24 merges, 0 red deploys).

## The stand-ins the example project built

The loop built each of these as a task of its own. They are examples; pick by what your product can lose.

| Stand-in                        | What it does                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               | Catches                                                                      |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------- |
| Canary and smoke test           | The deploy builds under a side name, runs the new build on a copy of the data with no network, and plays one real flow end to end (sign up, make a document, type, save, reload, export)                                                                                                                                                                                                                                                                                                                                                                                                   | a build that starts but does not work; a schema move that fails on real data |
| Snapshot before deploy          | After the canary passes and before the switch, the deploy copies the live database (read-only, integrity check, row counts, keep 30)                                                                                                                                                                                                                                                                                                                                                                                                                                                       | data loss with no way back                                                   |
| Automatic way back              | The old build keeps a tag. If the live check fails after the switch, the deploy switches back. Code only: a schema move needs the snapshot                                                                                                                                                                                                                                                                                                                                                                                                                                                 | a bad build that stays live                                                  |
| Fence hook                      | A `PreToolUse` hook on shell and edit tools in the repo. Refuses admin merges, `--no-verify`, force pushes, container commands on the live stack, and writes into the live data folder; allows reads. Each refusal names the allowed way and says: do not work around, end with BLOCKED. Fails closed. Against mistakes, not against an attacker                                                                                                                                                                                                                                           | the commands with no way back                                                |
| Headed test lane                | A CI job with a real window for the tests of native controls (select lists, colour pickers, file dialogs), at a true tablet size. Not required at first                                                                                                                                                                                                                                                                                                                                                                                                                                    | what headless browsers fake                                                  |
| Screen against print, by pixels | Renders the editor and the exported PDF at one size and compares them with a small tolerance                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               | print that differs from the screen                                           |
| Corpus of stored data           | Real stored documents with every word blanked. Each must open and save unchanged                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | old data that no longer opens                                                |
| A "user" session                | Every fifth task, a fresh session with no source access uses the product on a staging copy, by real clicks: it builds a fixed set of documents, exports each, holds the export beside the screen, then tries to break what the last five PRs changed, and files at most 8 issues. The first run took 20 minutes and about 15 dollars and found 2 bugs and 2 wishes the tests had not. Its brief named steps its allowed tools could not do (hover, drag, shift-click, sliders): write such a brief only from steps the session's allowed tools can do, and run it once before you trust it | faults only use shows                                                        |

## Not worth it yet, by the review

A second model as reviewer; mutation testing (seeing each new test fail first is cheaper); a second implementer (only for work in disjoint files, and then in a clone of its own).
