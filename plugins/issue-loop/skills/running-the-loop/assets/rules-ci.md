This file holds the plugin's rules for a repo whose code review runs in CI, in the form of rules.local.md.
next.sh lays it over rules.md when loop.env says REVIEW_IN=ci, before the loop's own rules.local.md, so a loop's own ## 7, ## 15 or ## 16 still wins.

## 7

7. The review runs in CI. When your boxes are ticked and the suite is green, push. Do not start a review subagent: CI reviews the PR once its other checks pass. Each finding that blocks the merge is a thread on its line, and the base branch takes no merge while one is open. Read the threads and the summary with the filter of rule 2: a reply by an author outside it is no finding. Answer every thread with a reply whose first word says what you did, then resolve it (gh api graphql, resolveReviewThread): `Fixed` with a test, `Rejected` with why it is not a bug, `Intentional` with why it is meant so, or `Didn't matter` with why. Then read the review's summary: make the design changes you agree with, open an issue by rule 17 for each fault {{BASE}} already has, and put the nits you leave in the PR body. Each push starts a new round on the new commits only. After three rounds the review stops: do not push a fourth fix, end with BLOCKED and the reason.

## 15

15. Severity beats the frozen list. Before the merge, list every issue this task opened. If one is a privacy fault, a data loss, a crash, or a gap in what the issue asked, and this PR's code causes or widens it, it is not a follow-up: fix it here, or do not merge and end with BLOCKED. "Outside the list" does not excuse a fault your diff ships. Before you write "{{BASE}} has it", prove it: git log -S on the lines at fault. If a PR of the last three days brought them in, name that PR in the issue. List the issues this task opened in the PR body before the review runs, so the CI review reads them. Put every blocking finding you answered with anything but `Fixed` in the final report under "Not fixed", with the reason.

## 16

16. The machine's own parts wait for the owner. A PR that touches a path the repo gives to a code owner (CI, deploy, containers, agent settings, the schema, whatever its CODEOWNERS names) merges only after the owner's approving review. That wait is not a test failure: never request, give, fake or work around an approval, never merge with --admin, and do not wait for it. When every other check is green and every thread is answered, leave auto-merge on and end the task with HELD #N and the reason; the release and the live proof come in a later task once it lands. Put "TOUCHES THE MACHINE" as its own line in your final report, with the way back in one sentence.
