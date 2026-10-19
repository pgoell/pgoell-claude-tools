# grant.sh: the user's standing order, only from a terminal and a typed yes,
# and next.sh's checks that the order is in place
tty_run() { printf '%s\n' "$1" | script -qec "$L/grant.sh" /dev/null 2>&1; }
grant2() { sed -i "s|^REPO=.*|REPO=$1|" "$T/loop2/loop.env"; printf 'yes\n' | script -qec "$T/loop2/grant.sh" /dev/null 2>&1; }
test_grant() {
echo orch >"$L/orch-name"; git -C "$T/repo" init -q
out=$("$L/next.sh" "Fix #7" 2>&1); ok "next refuses without a standing order" $? 3
has "next names the missing order" "$out" "no standing order in $L/CLAUDE.md"
[ -f "$STUB/sent" ]; ok "next sent nothing without a standing order" $? 1
out=$("$L/grant.sh" </dev/null 2>&1); ok "grant refuses without a terminal" $? 2
out=$(tty_run yes); ok "grant refuses FILL markers" $? 3
sed -i 's/<FILL:[^>]*>/filled/g' "$L/standing-order.md"
out=$(tty_run no); ok "grant without a yes" $? 1
has "grant shows the order before it asks" "$out" "## issue-loop standing order: $L"
[ -e "$L/CLAUDE.md" ] || [ -e "$T/repo/CLAUDE.local.md" ]; ok "nothing written without a yes" $? 1
out=$(tty_run yes); ok "grant exit" $? 0
has "the loop folder holds the order" "$(cat "$L/CLAUDE.md")" "## issue-loop standing order: $L"
has "the order names the implementer" "$(cat "$L/CLAUDE.md")" 'the implementer `impl`'
hasnt "the order has no placeholder left" "$(cat "$L/CLAUDE.md" "$T/repo/CLAUDE.local.md")" "{{"
has "the checkout holds the order" "$(cat "$T/repo/CLAUDE.local.md")" "## issue-loop standing order: $L"
has "the order is kept out of git" "$(cat "$T/repo/.git/info/exclude")" "CLAUDE.local.md"
ok "the checkout stays clean" "$(git -C "$T/repo" status --porcelain)" ""
out=$(tty_run yes); has "a second grant changes nothing" "$out" "already in $L/CLAUDE.md"
ok "the order is there once" "$(grep -c '^## issue-loop standing order' "$L/CLAUDE.md")" 1
git init -q "$T/tracked"; echo mine >"$T/tracked/CLAUDE.local.md"; git -C "$T/tracked" add CLAUDE.local.md
mkdir "$T/ro"; chmod a-w "$T/ro"; git init -q "$T/nonl"; printf '*.log' >"$T/nonl/.git/info/exclude"
cp -r "$L" "$T/loop2"; rm "$T/loop2/CLAUDE.md"
out=$(grant2 "$T/tracked"); ok "grant refuses a tracked CLAUDE.local.md" $? 1
ok "the tracked file is left alone" "$(cat "$T/tracked/CLAUDE.local.md")" mine
out=$(grant2 "$T/ro"); ok "grant fails when it cannot write" $? 1
hasnt "a failed grant does not say granted" "$out" "granted."; [ -e "$T/loop2/CLAUDE.md" ]; ok "a failed grant writes neither file" $? 1
out=$(grant2 "$T/nonl"); ok "grant with an exclude file that has no last newline" $? 0
ok "that checkout stays clean" "$(git -C "$T/nonl" status --porcelain)" ""
chmod u+w "$T/ro"; ln -s "$L" "$T/link"
mv "$T/repo/CLAUDE.local.md" "$T/impl-order"
out=$("$L/next.sh" "Fix #7" 2>&1); ok "next refuses without the implementer's order" $? 3
has "next names the checkout" "$out" "no standing order in $T/repo/CLAUDE.local.md"
cp "$T/impl-order" "$T/repo/CLAUDE.md"; "$L/next.sh" "Fix #7" >/dev/null 2>&1; ok "the order may sit in the checkout's CLAUDE.md" $? 0
rm "$T/repo/CLAUDE.md" "$STUB/sent"; mv "$T/impl-order" "$T/repo/CLAUDE.local.md"
"$T/link/next.sh" "Fix #7" >/dev/null 2>&1; ok "the order holds when the folder is reached through a link" $? 0; rm "$STUB/sent"
grep -v '^19\. ' "$L/rules.md" >"$L/rules.keep"; mv "$L/rules.md" "$L/rules.full"; mv "$L/rules.keep" "$L/rules.md"; rm "$L/orch-name"
"$L/next.sh" "Fix #7" >/dev/null 2>&1; ok "next needs no orch-name without rule 19" $? 0
mv "$L/rules.full" "$L/rules.md"; rm -f "$STUB/sent"
}
