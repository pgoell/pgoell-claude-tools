# init.sh: copies templates, refuses a folder inside a checkout
test_init() {
out=$("$skill/scripts/init.sh" "$L" 2>&1); ok "init exit" $? 0
hasnt "init prints no cp warning" "$out" "cp:"
for f in loop.env models.env standing-order.md standing-order-impl.md rules.local.md ledger.tsv HANDOFF.md; do
  [ -f "$L/$f" ]; ok "init copies $f" $? 0
done
for f in driver-herdr.sh rules.md; do
  [ -e "$L/$f" ]; ok "init copies no $f" $? 1
done
for n in next.sh wait.sh gate.sh start.sh notify.sh grant.sh takeover-check.sh lib.sh; do
  cmp -s "$skill/scripts/stub.sh" "$L/$n"; ok "init makes $n a stub" $? 0
  [ -x "$L/$n" ]; ok "init makes $n executable" $? 0
done
mkdir -p "$T/co" && git -C "$T/co" init -q
out=$("$skill/scripts/init.sh" "$T/co/a/loop" 2>&1); ok "init refuses a checkout" $? 1
[ -e "$T/co/a" ]; ok "a refused folder is not left behind" $? 1
echo keep >"$L/ledger.tsv"; "$skill/scripts/init.sh" "$L" >/dev/null 2>&1
ok "init keeps existing files" "$(cat "$L/ledger.tsv")" keep
}
