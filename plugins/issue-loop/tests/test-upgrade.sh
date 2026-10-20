# test_upgrade: scripts/upgrade.sh on a fixture folder built from the live
# rules.md: the dry run, the apply, the second run, and the refusals. It works
# in $T/up and never reads the shared loop folder.

# _up_fill LINE ANSWER: LINE with its first FILL marker replaced by ANSWER.
_up_fill() {
  local re='(<FILL:[^>]*>)' m
  [[ $1 =~ $re ]] || { printf '%s\n' "$1"; return; }
  m=${BASH_REMATCH[1]}
  printf '%s\n' "${1/"$m"/"$2"}"
}

# _up_old_rules: the live rules.md with the real case's answers and rewrites.
_up_old_rules() {
  local line
  while IFS= read -r line; do
    case $line in
      "1. Bar."*) line=$(_up_fill "$line" "it does what the issue asks and keeps every convention in AGENTS.md") ;;
      "   - While working"*) line=$(_up_fill "$line" "mise run test-one NAME") ;;
      "   - Run the full suite"*) line=$(_up_fill "$line" "mise run test") ;;
      "   - <FILL: the lint"*) line=$(_up_fill "$line" "mise run lint") ;;
      "3. Who codes."*) line="3. Who codes. Subagents of this loop code on {{CODER_MODEL}}, and review subagents run on {{REVIEW_MODEL}}. You plan, brief, review and integrate." ;;
      "9. Merge and deploy"*) line="9. No deploy. Merge with gh pr merge --squash --auto --delete-branch, then wait for the checks with gh pr checks N --watch --fail-fast. Nobody deploys {{BASE}} from this loop." ;;
      "13. Every kind."*) line=$(_up_fill "$line" "every runtime: Claude Code, Codex and Cursor. Leaving a kind out of one runtime is an open Asked item.") ;;
      "14. Live data."*) line="14. No live data. This repo stores no user data, so nothing the loop does reaches a database." ;;
    esac
    printf '%s\n' "$line"
  done <"$skill/assets/rules.md"
}

# _up_snap DIR: the md5 of every file under DIR, in name order.
_up_snap() { (cd "$1" && find . -type f -exec md5sum {} + | sort); }

# _up_pick SNAP NAME: the md5 line of NAME in SNAP.
_up_pick() { printf '%s\n' "$1" | grep -F "  ./$2"; }

test_upgrade() {
  local up=$T/up sc=$skill/scripts pl=$skill/assets
  local stubs="next.sh wait.sh gate.sh start.sh notify.sh grant.sh takeover-check.sh lib.sh"
  local data="CLAUDE.md CLAUDE.local.md HANDOFF.md HANDOFF-2026-10-18-orch2.md hello.txt ledger.tsv orch-name task.md task.start standing-order.md models.env"
  local n f pre post out st fixed loc nl bad
  . "$pl/rules.sh"

  # the fixture: a folder as the 0.8 scripts left it
  mkdir -p "$up"
  _up_old_rules >"$up/rules.md"
  fixed=$(cat "$up/rules.md")
  grep -v '^ISSUE_LOOP_VERSION=' "$pl/loop.env" >"$up/loop.env"
  cat "$pl/models.env" >"$up/models.env"
  for n in $stubs driver-herdr.sh; do
    printf 'old %s\n' "${n%.sh}" >"$up/$n"; chmod +x "$up/$n"
  done
  printf '%s\n' "the standing order" >"$up/CLAUDE.md"
  printf '%s\n' "my own notes" >"$up/CLAUDE.local.md"
  printf '%s\n' "handoff" >"$up/HANDOFF.md"
  printf '%s\n' "handoff 2" >"$up/HANDOFF-2026-10-18-orch2.md"
  printf '%s\n' "hello" >"$up/hello.txt"
  printf '%s\t%s\n' "2026-10-18" "277" >"$up/ledger.tsv"
  printf '%s\n' "orch" >"$up/orch-name"
  printf '%s\n' "task line" >"$up/task.md"
  printf '%s\n' "1700000000" >"$up/task.start"
  printf '%s\n' "the standing order" >"$up/standing-order.md"

  # the dry run says what it would do and changes no file
  pre=$(_up_snap "$up")
  out=$("$sc/upgrade.sh" "$up" 2>&1); st=$?
  ok "dry run exits 0" "$st" 0
  has "dry run: stub for next.sh" "$out" "would replace next.sh with the stub"
  has "dry run: stub for lib.sh" "$out" "would replace lib.sh with the stub"
  has "dry run: driver moves" "$out" "would move driver-herdr.sh"
  has "dry run: rules.local.md" "$out" "would write rules.local.md"
  has "dry run: loop.env" "$out" "would add ISSUE_LOOP_VERSION=latest"
  has "dry run: says nothing changed" "$out" "dry run: nothing changed. Run again with --apply."
  ok "dry run changes no file" "$(_up_snap "$up")" "$pre"

  # --apply
  out=$("$sc/upgrade.sh" "$up" --apply 2>&1); st=$?
  ok "apply exits 0" "$st" 0
  for n in $stubs; do
    cmp -s "$up/$n" "$sc/stub.sh"; ok "$n is the stub" "$?" 0
    [ -x "$up/$n" ]; ok "$n is executable" "$?" 0
    ok "old $n in before-upgrade/" "$(cat "$up/before-upgrade/$n")" "old ${n%.sh}"
  done
  ok "driver-herdr.sh moved" "$(cat "$up/before-upgrade/driver-herdr.sh")" "old driver-herdr"
  [ ! -e "$up/driver-herdr.sh" ]; ok "driver-herdr.sh gone from the folder" "$?" 0
  ok "rules.md is in before-upgrade/" "$(cat "$up/before-upgrade/rules.md")" "$fixed"
  [ ! -e "$up/rules.md" ]; ok "rules.md gone from the folder" "$?" 0

  post=$(_up_snap "$up")
  for f in $data; do ok "$f untouched" "$(_up_pick "$post" "$f")" "$(_up_pick "$pre" "$f")"; done

  has "loop.env gained the version pin" "$(cat "$up/loop.env")" "ISSUE_LOOP_VERSION=latest"
  has "loop.env keeps its old lines" "$(cat "$up/loop.env")" "DRIVER=driver-herdr.sh"

  loc=$(cat "$up/rules.local.md")
  for n in "## 1.1" "## 5.1" "## 5.2" "## 5.3" "## 13.1" "## 3" "## 9" "## 14"; do
    has "rules.local.md has $n" "$loc" "$n"
  done
  ok "rules.local.md has no ## 1" "$(grep -cx '## 1' "$up/rules.local.md")" 0
  ok "rules.local.md has no ## 5" "$(grep -cx '## 5' "$up/rules.local.md")" 0
  ok "the brief rebuilt from rules.local.md is the old rules.md" \
    "$(assemble_rules "$pl/rules.md" "$up/rules.local.md")" "$fixed"

  # a second run changes nothing
  pre=$(_up_snap "$up")
  out=$("$sc/upgrade.sh" "$up" --apply 2>&1); st=$?
  ok "second run exits 0" "$st" 0
  has "second run says nothing to change" "$out" "nothing to change"
  ok "second run changes no file" "$(_up_snap "$up")" "$pre"

  # refusal: both rules files
  local both=$T/up-both
  mkdir -p "$both"
  cat "$pl/loop.env" >"$both/loop.env"
  printf '%s\n' "old" >"$both/rules.md"
  printf '%s\n' "new" >"$both/rules.local.md"
  pre=$(_up_snap "$both")
  "$sc/upgrade.sh" "$both" --apply >/dev/null 2>&1; ok "both rules files: exit 1" "$?" 1
  ok "both rules files: nothing changed" "$(_up_snap "$both")" "$pre"

  # refusal: no loop.env
  local none=$T/up-none
  mkdir -p "$none"
  printf '%s\n' "x" >"$none/hello.txt"
  pre=$(_up_snap "$none")
  "$sc/upgrade.sh" "$none" --apply >/dev/null 2>&1; ok "no loop.env: exit 2" "$?" 2
  ok "no loop.env: nothing changed" "$(_up_snap "$none")" "$pre"

  # refusal: the brief check. Rule 2 gets a "## " line, which a rules.local.md
  # section cannot hold, so the rebuilt file does not parse and nothing is written.
  local bad=$T/up-bad
  mkdir -p "$bad"
  cat "$pl/loop.env" >"$bad/loop.env"
  nl=$'\n'
  badrules=${fixed/"2. Checklist first, then freeze it."/"2. Checklist first, then freeze it.${nl}## Notes"}
  printf '%s\n' "$badrules" >"$bad/rules.md"
  pre=$(_up_snap "$bad")
  out=$("$sc/upgrade.sh" "$bad" --apply 2>&1); st=$?
  ok "brief check refuses: exit 1" "$st" 1
  has "brief check refuses: says so" "$out" "refused"
  ok "brief check refuses: nothing changed" "$(_up_snap "$bad")" "$pre"
}
