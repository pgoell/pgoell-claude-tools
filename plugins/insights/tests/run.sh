#!/bin/bash
# usage: tests/run.sh
# Runs the activity skill's scripts against fixtures: two transcripts, one
# ledger, one git checkout made on the spot, and fake gh and bunx. No session,
# no network. Needs bash, git, jq and uv.
set -u
here=$(cd "$(dirname "$0")" && pwd)
scripts="$here/../skills/activity/scripts"
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
pass=0 fail=0
ok() { if [ "$2" = "$3" ]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL $1: got '$2', want '$3'"; fi; }
has() { if grep -qF -- "$3" <<<"$2"; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL $1: no '$3' in: $2"; fi; }
hasnt() { if grep -qF -- "$3" <<<"$2"; then fail=$((fail + 1)); echo "FAIL $1: found '$3'"; else pass=$((pass + 1)); fi; }

D=2026-10-09
V="$T/vault" C="$T/Code" P="$T/projects" S="$T/state"
mkdir -p "$V/01 Periodic/00 Daily" "$V/01 Periodic/06 Insights/memory" "$C/app/.worktrees/x" "$C/loop" "$C/loop2" \
  "$P/-app" "$P/-app--worktrees-x" "$P/-vault" "$P/-job" "$S/news" "$S/insights" "$T/bin"
printf -- '---\nid: 1\ntype: Note\n---\n# 2026-10-10 Saturday\n\nZeitung: [[paper]]\n\n## TODOs\n\n- [ ] keep me\n' >"$V/01 Periodic/00 Daily/2026-10-10.md"
echo '{"fingerprint":"f","verdict":"pending","ref":"https://github.com/me/app/pull/9"}' >"$V/01 Periodic/06 Insights/memory/problems.jsonl"

# one checkout with a GitHub origin and two commits on the day
git -C "$C/app" init -q -b main
git -C "$C/app" remote add origin git@github.com:me/app.git
for n in 1 2; do
  GIT_AUTHOR_DATE="${D}T12:00:00+02:00" GIT_COMMITTER_DATE="${D}T12:00:00+02:00" \
    git -C "$C/app" -c user.name=t -c user.email=t@t commit -q --allow-empty -m "feat: step $n"
done
# a rebase copy on a side branch must not count
git -C "$C/app" checkout -q -b side
GIT_AUTHOR_DATE="${D}T13:00:00+02:00" GIT_COMMITTER_DATE="${D}T13:00:00+02:00" \
  git -C "$C/app" -c user.name=t -c user.email=t@t commit -q --allow-empty -m "feat: step 2 again"
git -C "$C/app" checkout -q main

# transcripts: a session in the checkout, one in a worktree that is gone, one in the vault, one of the job itself
rec() { printf '{"type":"user","sessionId":"%s","timestamp":"%sT10:00:00.000Z","cwd":"%s","message":{"content":"%s"}}\n' "$1" "$D" "$2" "$3"; }
{
  rec s-app "$C/app" "fix the bug"
  echo '{"type":"bridge-session","sessionId":"s-app","bridgeSessionId":"cse_01ABC"}'
  echo '{"type":"pr-link","sessionId":"s-app","prNumber":9,"prUrl":"https://github.com/me/app/pull/9"}'
  echo '{"type":"pr-link","prNumber":8,"prUrl":"https://github.com/me/app/pull/8"}'
  printf '{"type":"bridge-session","sessionId":"s-app","bridgeSess'
} >"$P/-app/s-app.jsonl"
rec s-wt "$C/app/.worktrees/gone" "more" >"$P/-app--worktrees-x/s-wt.jsonl"
rec s-vault "$V" "a private thought" >"$P/-vault/s-vault.jsonl"
rec s-job "$C/app" "run it insights-self-run" >"$P/-job/s-job.jsonl"

printf 'date\tissues\tPRs\tminutes\tclosed\topened\tnot fixed\tnotes\n%s\t1 2\t7\t70\t2\t0\t-\tfine\n%s\t3\t9 (open, rule 16)\t47 (+3)\t0\t0\t-\tTOUCHES THE MACHINE\n2026-10-08\t4\t5\t10\t1\t0\t-\told\n' "$D" "$D" >"$C/loop/ledger.tsv"
printf 'date\tissues\tPRs\tminutes\n%s\t5\t9\t5\n' "$D" >"$C/loop2/ledger.tsv"
printf '== 2026-10-09T06:00:00 news\n== 2026-10-09T06:10:00 exit 0\n' >"$S/news/$D.log"
printf '== 2026-10-09T05:30:00 insights\n== 2026-10-09T05:40:00 exit 1\n' >"$S/insights/$D.log"

# fakes: gh answers from the query, bunx prints one ccusage report
cat >"$T/bin/gh" <<'EOF'
#!/bin/bash
[ -n "${GH_DOWN:-}" ] && exit 1
pr() { printf '{"number":%s,"title":"%s","url":"https://github.com/me/app/pull/%s","repository":{"nameWithOwner":"me/app"},"createdAt":"%s","isDraft":false}' "$1" "$2" "$1" "$3"; }
case "$*" in
"api user"*) echo me ;;
"search prs"*"--owner=me"*"--created="*) echo "[$(pr 7 'feat: seven' 2026-10-09T08:00:00Z),$(pr 9 'fix: nine' 2026-10-09T09:00:00Z)]" ;;
"search prs"*"--owner=me"*"--merged-at="*) echo "[$(pr 7 'feat: seven' 2026-10-09T08:00:00Z)]" ;;
"search prs"*"--owner=me"*"--state=open"*) echo "[$(pr 9 'fix: nine' 2026-10-09T09:00:00Z),$(pr 2 'old one' 2026-01-01T09:00:00Z)]" ;;
"search issues"*"--created="*) echo '[{"number":1,"repository":{"nameWithOwner":"me/app"}},{"number":2,"repository":{"nameWithOwner":"me/app"}},{"number":3,"repository":{"nameWithOwner":"me/app"}}]' ;;
"search issues"*"--closed="*) echo '[{"number":1,"repository":{"nameWithOwner":"me/app"}}]' ;;
"pr list"*) echo '[{"headRefName":"red"},{"headRefName":"fixed"},{"headRefName":"stopped"}]' ;;
"run list"*"--created 2026-10-08T22:00:00Z..2026-10-09T21:59:59Z"*)
  ci() { printf '{"conclusion":"%s","status":"%s","createdAt":"2026-10-09T%s:00:00Z","headBranch":"%s","workflowName":"CI","url":"https://github.com/me/app/actions/runs/%s"}' "$1" "$2" "$3" "$4" "$5"; }
  echo "[$(ci failure completed 08 red 1),$(ci '' in_progress 09 red 2),$(ci failure completed 08 fixed 3),$(ci success completed 09 fixed 4),
    $(ci failure completed 08 stopped 5),$(ci cancelled completed 09 stopped 6),$(ci failure completed 08 merged-away 7),$(ci failure completed 08 main 8)]" ;;
*) exit 1 ;;
esac
EOF
cat >"$T/bin/bunx" <<'EOF'
#!/bin/bash
[ -n "${BUNX_DOWN:-}" ] && exit 1
echo '{"projects":{"-app":[{"date":"2026-10-09","totalTokens":1000000,"totalCost":10.5}],"-app--worktrees-x":[{"date":"2026-10-09","totalTokens":500000,"totalCost":2}],"-vault":[{"date":"2026-10-09","totalTokens":10,"totalCost":1}]},"totals":{"totalTokens":1500010,"totalCost":13.5}}'
EOF
chmod +x "$T/bin/gh" "$T/bin/bunx"
export PATH="$T/bin:$PATH"

args=(--vault "$V" --date "$D")
collect() { uv run -q "$scripts/collect.py" "${args[@]}" --code "$C" --projects "$P" --state "$S" --private "$V" 2>&1; }
J="$V/01 Periodic/07 Activity/$D.json"
q() { jq -r "$1" "$J"; }

out=$(collect); ok "collect exit" $? 0
ok "sources all ok but the vault" "$(q '.sources|to_entries|map(select(.value!="ok")|.key)|join(",")')" vault
ok "worktree session folds into its repo" "$(q '.repos[]|select(.name=="app").sessions')" 2
ok "private session counts under vault" "$(q '.repos[]|select(.name=="vault").sessions')" 1
ok "the job's own session is left out" "$(q '.scope.own_runs_skipped')" 1
hasnt "no typed text in the data" "$(cat "$J")" "private thought"
ok "commits count the default branch only" "$(q '.repos[]|select(.name=="app").commits')" 2
ok "no commit subjects, subagent counts or helper keys in the data" "$(q '[.repos[]|keys[]|select(test("commit_list|subagent|prs_open$|^_"))]|length')" 0
ok "a torn line and a pr-link with no session are skipped" "$(q '.open_prs|map(select(.session))|length')" 1
ok "prs opened" "$(q '.repos[]|select(.name=="app").prs_opened')" 2
ok "prs merged" "$(q '.repos[]|select(.name=="app").prs_merged')" 1
ok "issues opened and closed" "$(q '.repos[]|select(.name=="app")|"\(.issues_opened)/\(.issues_closed)"')" 3/1
ok "cost folds worktree folder into the repo" "$(q '.repos[]|select(.name=="app").cost')" 12.5
ok "total cost from ccusage" "$(q '.usage.cost')" 13.5
ok "ledger keeps the day only" "$(q '.ledger|length')" 3
ok "ledger maps to the repo by PR number" "$(q '.ledger[0].repo')" app
ok "ledger minutes read the first number" "$(q '.repos[]|select(.name=="app").loop_minutes')" 122
ok "a ledger whose only PR is still open maps to the repo" "$(q '.ledger[2]|"\(.repo) \(.pr_urls[0])"')" "app https://github.com/me/app/pull/9"
ok "ledger PR url skips the rule number" "$(q '.ledger[1].pr_urls|join(",")')" https://github.com/me/app/pull/9
ok "failed CI: newest finished run, open PR or default branch only" "$(q '.failed_ci|map(.branch)|sort|join(",")')" main,red
ok "open prs, oldest first" "$(q '.open_prs|map(.number)|join(",")')" 2,9
ok "old open pr is stale" "$(q '.open_prs[0].stale')" true
ok "pending insights pr is marked" "$(q '.open_prs[1].insights')" true
ok "session url from the bridge id" "$(q '.open_prs[1].session.url')" https://claude.ai/code/session_01ABC
ok "cron states" "$(q '.cron|map("\(.job) \(.state)")|join("; ")')" "insights failed, exit 1; news ok"

# render: refuses bad notes, then renders
N="$T/notes.json"
note() { jq -n --arg h "$1" --arg u "$2" --arg l "${3:-#9}" --arg r "${4:-app}" '{needs:[{headline:$h,why:"Open since 2026-10-09.",links:[{label:$l,url:$u}],resume:"s-app"}],shipped:{($r):"1 PR: seven."}}' >"$N"; }
render() { uv run -q "$scripts/render.py" "${args[@]}" --notes "$N" 2>&1; }
note "app #9 waits" https://github.com/me/app/pull/404
out=$(render); ok "render refuses an unknown link" $? 1
has "render names the link" "$out" "pull/404"
note "app #9 waits $(printf '\xe2\x80\x94') now" https://github.com/me/app/pull/9
out=$(render); ok "render refuses a dash" $? 1; has "render names the dash" "$out" "holds a dash"
note "app #9 waits" "$S/news/$D.log"
out=$(render); ok "render refuses a log path as a link" $? 1
note "app #9 waits" "fix: nine"
out=$(render); ok "render refuses a PR title as a link" $? 1
note "app #9 waits" https://github.com/me/app/pull/9 "nine $(printf '\xe2\x80\x94') now"
out=$(render); ok "render refuses a dash in a label" $? 1
has "render names the label" "$out" "link label"
note "app [9] waits" https://github.com/me/app/pull/9
out=$(render); ok "render refuses a bracket in a headline" $? 1
note "app #9 waits" https://github.com/me/app/pull/9 "#9" vault
out=$(render); ok "render refuses a summary for a repo that merged nothing" $? 1
has "render names the repo" "$out" "shipped['vault']"
[ -e "$V/01 Periodic/07 Activity/$D.html" ]; ok "nothing rendered on errors" $? 1
note "app #9 waits" https://github.com/me/app/pull/9
out=$(render); ok "render exit" $? 0
H=$(cat "$V/01 Periodic/07 Activity/$D.html")
has "page has the headline" "$H" "app #9 waits"
has "page has the resume command" "$H" "claude --resume s-app"
has "page has the summary" "$H" "1 PR: seven."
has "page names the missing source" "$H" "Unavailable on this run: vault."
hasnt "page loads nothing from outside" "$H" "<link"

# link_daily: one block above the first heading, replaced on a second run, the rest untouched
link() { uv run -q "$scripts/link_daily.py" "${args[@]}" --note-day 2026-10-10 >/dev/null 2>&1; }
note_file="$V/01 Periodic/00 Daily/2026-10-10.md"
link; ok "link exit" $? 0
link
ok "one link line after two runs" "$(grep -c '^Aktivität:' "$note_file")" 1
ok "needs line sits under the link" "$(grep -A1 '^Aktivität:' "$note_file" | tail -1)" "- [app #9 waits](https://github.com/me/app/pull/9)"
ok "link sits above the first heading" "$(grep -n -e '^Aktivität:' -e '^## TODOs' "$note_file" | head -1 | cut -d: -f2)" "Aktivität"
ok "frontmatter untouched" "$(head -4 "$note_file" | tr '\n' '|')" "---|id: 1|type: Note|---|"
ok "todos untouched" "$(tail -1 "$note_file")" "- [ ] keep me"
# the user's own lines under the block and a mention under a heading survive a rerun
sed -i 's|^- \[app #9 waits\].*|&\n- my own bullet\n- [my link](https://example.org)|' "$note_file"
printf '\n## Dump\n\nAktivität: see [[01 Periodic/07 Activity/%s.html]]\n- a dump bullet\n' "$D" >>"$note_file"
before=$(cat "$note_file"); link
ok "a rerun changes nothing it did not write" "$(cat "$note_file")" "$before"
jq '.needs += [{headline:"cron died",why:"See the log.",links:[]}] | .needs |= reverse' "$J" >"$T/j" && cp "$T/j" "$J"; link
ok "an item with no link stays out of the note" "$(grep -c 'cron died' "$note_file")" 0
ok "the user bullet still follows the block" "$(grep -A2 '^Aktivität: \[\[' "$note_file" | tail -1)" "- my own bullet"
ok "the dump bullet is still there" "$(tail -1 "$note_file")" "- a dump bullet"

# a missing gh and a failing ccusage degrade, they do not crash
out=$(GH_DOWN=1 BUNX_DOWN=1 collect); ok "collect exit without gh and ccusage" $? 0
ok "sources say unavailable" "$(q '[.sources.github,.sources.ci,.sources.usage]|join(",")')" unavailable,unavailable,unavailable
ok "sessions still counted" "$(q '.repos[]|select(.name=="app").sessions')" 2
echo '{"needs":[],"shipped":{}}' >"$N"
out=$(render); ok "render exit with sources down" $? 0
has "page names the gaps" "$(cat "$V/01 Periodic/07 Activity/$D.html")" "Unavailable on this run: github, ci, usage, vault."

# cron wrapper: three tools for the model, the periodic folder from kasten's variable, exit 1 with no page
mkdir -p "$T/home/.local/bin" "$V/P/07 Activity"
printf '#!/bin/bash\nprintf "%%s\\n" "$@" >"$HOME/args"\n[ -n "${NO_PAGE:-}" ] || echo page >"%s/P/07 Activity/$(TZ=Europe/Berlin date -d yesterday +%%F).html"\n' "$V" >"$T/home/.local/bin/claude"
chmod +x "$T/home/.local/bin/claude"
cron() { HOME="$T/home" KASTEN_PERIODIC_PATH=P INSIGHTS_LOG_DIR="$T/log" "$here/../scripts/cron-activity.sh" "$V"; }
cron; ok "cron exit" $? 0
ok "cron allows three tools" "$(sed -n '/--allowedTools/,$p' "$T/home/args" | tr '\n' '|')" "--allowedTools|Read|Write|Bash(uv run:*)|"
has "cron passes the periodic folder" "$(cat "$T/home/args")" '--periodic "P"'
rm "$V/P/07 Activity/"*.html; NO_PAGE=1 cron; ok "cron exit with no page" $? 1

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
