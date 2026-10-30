# 2026-10-30: Fix

issue-loop 0.13.1. `next.sh` fast-forwards the loop's checkout (`REPO`) to `origin/BASE` before each brief when the checkout sits on `BASE`, and warns when it cannot. The implementer reads `CLAUDE.md` from that checkout, and nothing pulled it before: in kasten it stood 32 commits behind, so sessions never read a rule merged the day before. Changed page: [the issue-loop plugin](/reference/plugins/issue-loop.md).
