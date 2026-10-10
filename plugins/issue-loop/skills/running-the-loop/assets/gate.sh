#!/bin/bash
# usage: gate.sh <issue numbers...>
# Pass or fail for the task that next.sh started last. Exit 0 only if all holds:
# the issues are closed, every PR made since the task began is merged with no
# open box, the live commit is the head of BASE, the implementer's checkout is
# clean on BASE, and the live app answers. It reads; it changes nothing.
# Needs: gh (logged in), git, jq, curl, GNU date.
. "$(dirname "$0")/lib.sh"
start=$(cat "$S/task.start")
cd "$REPO" || exit 2
bad=0
no() { echo "FAIL $*"; bad=1; }
for n in "$@"; do
  [ "$(gh issue view "$n" --json state -q .state)" = CLOSED ] || no "issue $n open"
done
for p in $(gh pr list --state all --search "created:>=$start" --json number -q '.[].number'); do
  state=$(gh pr view "$p" --json state -q .state)
  echo "PR $p $state $(gh pr view "$p" --json title -q .title)"
  [ "$state" = MERGED ] || no "PR $p not merged"
  open=$(gh pr view "$p" --json body -q .body | grep -cE '^\s*- \[ \]')
  [ "$open" = 0 ] || no "PR $p: $open open boxes"
  gh pr view "$p" --json files -q '.files[].path' | grep -E "$MACHINE_FILES" | sed "s/^/TELL HUMAN: PR $p touched /"
done
head=$(git ls-remote origin "refs/heads/$BASE" | cut -f1)
if [ -n "$DEPLOY_WORKFLOW" ]; then
  live=$(gh run list --workflow "$DEPLOY_WORKFLOW" -L 5 --json headSha,conclusion -q '[.[]|select(.conclusion=="success")][0].headSha')
  [ "$live" = "$head" ] || no "live is ${live:0:7}, $BASE is ${head:0:7}"
fi
[ -z "$(git --no-optional-locks status --porcelain)" ] || no "working tree dirty"
[ "$(git branch --show-current)" = "$BASE" ] || no "not on $BASE"
if [ -n "$ALIVE_URL" ]; then
  curl -fsS -o /dev/null "$ALIVE_URL" || no "live app does not answer"
fi
echo "issues opened since start:"
gh issue list --state all --limit 50 --search "created:>=$start" --json number,title,labels -q '.[]|"  #\(.number) [\([.labels[].name]|join(","))] \(.title)"'
echo "minutes: $((($(date +%s) - $(date -d "$start" +%s)) / 60))"
[ $bad = 0 ] && echo "GATE PASS" || echo "GATE FAIL"
exit $bad
