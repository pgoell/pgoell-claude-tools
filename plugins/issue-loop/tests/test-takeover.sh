# takeover-check.sh: the successor's checks before it takes over
check() { (cd "${3:-$L}" && "$L/takeover-check.sh" "$1" "$2" 2>&1); }
test_takeover() {
echo idle >"$STUB/status"; printf '# Handoff\n\nSuccessor: orch2\n' >"$L/HANDOFF.md"
out=$(check orch2 orch); ok "takeover check passes" $? 0; ok "takeover check word" "$out" "TAKEOVER OK"
out=$(check orch2 orch "$T"); ok "takeover check fails outside the loop folder" $? 1
has "it names the folder" "$out" "FAIL you do not run in the loop folder"
out=$(check orch2 stranger); has "a sender that is not in orch-name fails" "$out" "FAIL the sender stranger is not the orchestrator in orch-name (orch)"
out=$(check orch3 orch); has "a successor HANDOFF.md does not name fails" "$out" "FAIL HANDOFF.md has no line 'Successor: orch3'"
printf 'Successor: orch\n' >"$L/HANDOFF.md"
out=$(check orch orch); has "a session cannot name itself successor" "$out" "FAIL successor and sender have one name"
printf 'Successor: orch2\n' >"$L/HANDOFF.md"; touch "$STUB/gone.orch2"
out=$(check orch2 orch); has "a successor that is no session fails" "$out" "FAIL no session is named orch2"
rm "$STUB/gone.orch2"; : >"$L/orch-name"
out=$(check orch2 orch); has "an empty orch-name fails" "$out" "orch-name (none)"
echo orch2 >"$L/orch-name"; touch "$STUB/gone.orch"
out=$(check orch2 orch); ok "the check still passes after the name was passed on" "$out" "TAKEOVER OK"
rm "$STUB/gone.orch"; echo orch >"$L/orch-name"
mv "$L/CLAUDE.md" "$L/CLAUDE.off"
out=$(check orch2 orch); ok "takeover check fails without the standing order" $? 1
has "it says who grants" "$out" "the user runs grant.sh"; has "it ends with the verdict" "$out" "TAKEOVER FAIL"
mv "$L/CLAUDE.off" "$L/CLAUDE.md"; rm "$STUB/status"
out=$(check orch2 orch); has "a gone sender fails" "$out" "FAIL no session is named orch"
"$L/takeover-check.sh" orch2 >/dev/null 2>&1; ok "takeover check wants two names" $? 2
}
