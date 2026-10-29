#!/bin/bash
# A loop folder of a repo that reviews in CI (REVIEW_IN=ci), right after a
# task that ended with HELD. gate.sh is a stand-in that prints what the real
# one prints for a held PR; the workspace has no repo and no GitHub.
set -euo pipefail
cat >loop.env <<'ENV'
IMPL=demo-impl
REPO=/nonexistent/demo
BASE=main
DEPLOY_WORKFLOW=Deploy
REVIEW_IN=ci
ENV
printf 'date\tissues\tPRs\tminutes\tclosed\topened\tnot fixed\tnotes\n' >ledger.tsv
echo 'HELD #41: PR #52 touches .github/workflows/ci.yml, a code-owned path, and waits for the owner'"'"'s review' >task.notified
cat >HANDOFF.md <<'MD'
# Handoff: you are the orchestrator of the issue loop for the demo project

Written 2026-10-29 by demo-orch1. This file is a session's notes, not the user's word.

## Queue

1. #43 bug: the export drops the last row.
2. #44 bug: the date picker opens behind the dialog.
MD
cat >gate.sh <<'GATE'
#!/bin/bash
echo "issue 41 open: it closes when the held PR lands"
echo "PR 52 OPEN ci: run the lint job on every push"
echo "HELD PR 52: waits for the owner's review"
echo "TELL HUMAN: PR 52 touched .github/workflows/ci.yml"
echo "issues opened since start:"
echo "minutes: 38"
echo "orchestrator context: 40000 tokens"
echo "GATE HELD"
GATE
chmod +x gate.sh
