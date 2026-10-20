# Tests for structure-hook with fake PostToolUse JSON. Sourced by run.sh,
# which defines fresh, ok, bad and mkfile.

# Feeds the hook a Write event for path $1; sets RC and ERR.
hook() {
  ERR="$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":""}}' "$1" |
    bash scripts/structure-hook 2>&1 >/dev/null)"
  RC=$?
}

# H1 a big untracked file reaches Claude with exit 2; the index is untouched.
fresh
mkfile small.md 100
git add -A
before="$(git ls-files -s)"
mkfile "$REPO/big.md" 20004
hook "$REPO/big.md"
if [ "$RC" -eq 2 ] && grep -qF 'file-size: big.md is ~5001 tokens' <<<"$ERR" &&
  [ "$(git ls-files -s)" = "$before" ]; then
  ok "H1 big new file exits 2, real index unchanged"
else
  bad "H1 big new file exits 2, real index unchanged (rc=$RC)"
fi

# H2 the size on disk counts, not the staged copy.
fresh
mkfile doc.md 100
git add -A
git commit -qm init
mkfile doc.md 20004
hook "$REPO/doc.md"
if [ "$RC" -eq 2 ]; then ok "H2 tracked file grown on disk exits 2"; else bad "H2 tracked file grown on disk exits 2 (rc=$RC)"; fi

# H3 a crowded folder reaches Claude; a small one passes silently.
fresh
for i in 1 2 3 4 5 6 7 8; do mkfile "src/m$i.py" 1; done
hook "$REPO/src/m8.py"
if [ "$RC" -eq 2 ] && grep -qF 'fan-out: src holds 8 entries' <<<"$ERR"; then
  ok "H3 crowded folder exits 2"
else
  bad "H3 crowded folder exits 2 (rc=$RC)"
fi
mkfile "$REPO/lib/ok.py" 1
hook "$REPO/lib/ok.py"
if [ "$RC" -eq 0 ] && [ -z "$ERR" ]; then ok "H3 small file in a small folder passes"; else bad "H3 small file in a small folder passes (rc=$RC)"; fi

# H4 files outside a repo, ignored files and missing paths pass.
mkdir -p "$WORK/outside"
mkfile "$WORK/outside/big.md" 20004
GIT_CEILING_DIRECTORIES="$WORK" hook "$WORK/outside/big.md"
rc_out=$RC
echo 'big-ignored.md' >.gitignore
mkfile big-ignored.md 20004
hook "$REPO/big-ignored.md"
rc_ign=$RC
hook "$REPO/nope.md"
if [ "$rc_out" -eq 0 ] && [ "$rc_ign" -eq 0 ] && [ "$RC" -eq 0 ]; then
  ok "H4 outside, ignored and missing files pass"
else
  bad "H4 outside, ignored and missing files pass (rc=$rc_out/$rc_ign/$RC)"
fi
