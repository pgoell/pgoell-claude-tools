#!/bin/bash
# usage: gate.sh <issue numbers...>
# Pass or fail for the task that next.sh started last. Exit 0 only if all holds:
# the issues are closed, every PR made since the task began is merged with no
# open box and every ticked box names its test (Test: or Proof: on its line),
# the live commit is the head of BASE (or every commit after it falls outside
# LIVE_TYPES), the implementer's checkout is clean on BASE, and the live app
# answers. It reads; it changes nothing but a fetch. A newer installed plugin gets a NEWER PLUGIN line, which never fails the gate.
# A task that ended with HELD (its PR waits for the owner's review) gets GATE
# HELD, exit 0, in place of GATE PASS: the held PR is open with auto-merge on and
# no check that fails or runs, and its issues may stay open. The HELD line is
# read where wait.sh reads the DONE line: task.notified and the screen.
# Needs: gh (logged in), git, jq, curl, GNU date.
. "$(dirname "$0")/lib.sh"
start=$(cat "$S/task.start")
cd "$REPO" || exit 2
bad=0
no() { echo "FAIL $*"; bad=1; }
held=0 nheld=0
{ head -1 "$S/task.notified" 2>/dev/null; screen_tail "$IMPL" 40; } | grep -qE '^\s*HELD ' && held=1
for n in "$@"; do
  if [ "$(gh issue view "$n" --json state -q .state)" != CLOSED ]; then
    if [ $held = 1 ]; then echo "issue $n open: it closes when the held PR lands"; else no "issue $n open"; fi
  fi
done
for p in $(gh pr list --state all --search "created:>=$start" --json number -q '.[].number'); do
  state=$(gh pr view "$p" --json state -q .state)
  echo "PR $p $state $(gh pr view "$p" --json title -q .title)"
  if [ $held = 1 ] && [ "$state" = OPEN ]; then
    nheld=$((nheld + 1))
    echo "HELD PR $p: waits for the owner's review"
    [ -n "$(gh pr view "$p" --json autoMergeRequest -q '.autoMergeRequest // empty')" ] || no "PR $p held without auto-merge"
    gh pr checks "$p" --json name,bucket -q '.[] | select(.bucket != "pass" and .bucket != "skipping") | "\(.name) \(.bucket)"' |
      while read -r c; do echo "FAIL PR $p held with check $c"; done | grep . && bad=1
  else
    [ "$state" = MERGED ] || no "PR $p not merged"
  fi
  body=$(gh pr view "$p" --json body -q .body)
  open=$(grep -cE '^\s*- \[ \]' <<<"$body")
  [ "$open" = 0 ] || no "PR $p: $open open boxes"
  # A box inside a fenced code block is an example, not a checklist line.
  # A box's test may sit on its own line or on the indented lines under it.
  k=$(awk '/^[[:space:]]*```/ { f = !f; next } f { next }
    /^[[:space:]]*- \[[xX]\]/ { if (b && !t) n++; b = 1; t = /Test:|Proof:/; next }
    b && /^[[:space:]]+[^[:space:]]/ && !/^[[:space:]]*- / { if (/Test:|Proof:/) t = 1; next }
    { if (b && !t) n++; b = 0 }
    END { if (b && !t) n++; print n + 0 }' <<<"$body")
  [ "$k" = 0 ] || no "PR $p: $k ticked boxes name no test"
  gh pr view "$p" --json files -q '.files[].path' | grep -E "$MACHINE_FILES" | sed "s/^/TELL HUMAN: PR $p touched /"
done
[ $held = 0 ] || [ $nheld -gt 0 ] || no "the task ended with HELD but no PR of it is open"
head=$(git ls-remote origin "refs/heads/$BASE" | cut -f1)
if [ -n "$DEPLOY_WORKFLOW" ]; then
  live=$(gh run list --workflow "$DEPLOY_WORKFLOW" -L 5 --json headSha,conclusion -q '[.[]|select(.conclusion=="success")][0].headSha')
  # LIVE_TYPES in loop.env: commit types that must reach live. Unset, every commit must.
  if [ "$live" != "$head" ]; then
    git fetch -q origin "$BASE" 2>/dev/null
    if subj=$(git log --format=%s "$live..$head" 2>/dev/null) && ! grep -qE "^(${LIVE_TYPES:-.*})" <<<"$subj"; then
      echo "note: live is ${live:0:7}, $BASE is ${head:0:7}; nothing there needs a deploy"
    else no "live is ${live:0:7}, $BASE is ${head:0:7}"; fi
  fi
fi
[ -z "$(git --no-optional-locks status --porcelain)" ] || no "working tree dirty"
[ "$(git branch --show-current)" = "$BASE" ] || no "not on $BASE"
if [ -n "$ALIVE_URL" ]; then
  curl -fsS -o /dev/null "$ALIVE_URL" || no "live app does not answer"
fi
echo "issues opened since start:"
gh issue list --state all --limit 50 --search "created:>=$start" --json number,title,labels -q '.[]|"  #\(.number) [\([.labels[].name]|join(","))] \(.title)"'
echo "minutes: $((($(date +%s) - $(date -d "$start" +%s)) / 60))"
# The orchestrator cannot see its own context size: read it from the newest
# transcript of a session started in this folder. It never fails the gate.
t=$(ls -t "$HOME/.claude/projects/$(printf %s "$S" | sed 's/[^A-Za-z0-9]/-/g')"/*.jsonl 2>/dev/null | head -1)
ctx=$([ -n "$t" ] && tail -n 300 "$t" | jq -Rn '[inputs|fromjson?|select(.type=="assistant")|.message.usage|select(.)]|last|(.input_tokens+.cache_read_input_tokens+.cache_creation_input_tokens)//empty' 2>/dev/null)
echo "orchestrator context: ${ctx:-unknown} tokens"
# 120k is the cheapest point measured (the plugin's tests/handover-cost.py); 150k is the
# ceiling past which an orchestrator forgot standing orders.
if [ "${ctx:-0}" -gt 150000 ] 2>/dev/null; then
  echo "HAND OVER NOW: past 150k. Run issue-loop:handing-over before the next brief."
elif [ "${ctx:-0}" -gt 120000 ] 2>/dev/null; then
  echo "HAND OVER: past 120k, and this is a break between tasks. Run issue-loop:handing-over before the next brief."
fi
# A newer issue-loop installed than the one this task ran: say so, never fail.
inst=$(installed_root)
ib=$(basename "$inst")
rb=$(basename "$ISSUE_LOOP_ROOT")
if [ -n "$inst" ] && [ "$ib" != "$rb" ] && [ "$(printf '%s\n' "$ib" "$rb" | sort -V | tail -1)" = "$ib" ]; then
  hold=" The next next.sh takes it up."
  [ "${ISSUE_LOOP_VERSION:-latest}" = latest ] || hold=" ISSUE_LOOP_VERSION=$ISSUE_LOOP_VERSION in loop.env holds the loop back."
  echo "NEWER PLUGIN: issue-loop $ib is installed, this task ran $rb.$hold"
fi
if [ $bad = 1 ]; then echo "GATE FAIL"; elif [ $held = 1 ]; then echo "GATE HELD"; else echo "GATE PASS"; fi
exit $bad
