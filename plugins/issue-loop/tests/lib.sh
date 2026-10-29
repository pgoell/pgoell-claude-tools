# Sourced by tests/run.sh: the temp folder, the counters, the checks, the stub
# driver wiring and the fake gh, git and curl that every test file shares.
skill="$here/../skills/running-the-loop"
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
pass=0 fail=0
ok() { if [ "$2" = "$3" ]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL $1: got '$2', want '$3'"; fi; }
has() { if grep -qF -- "$3" <<<"$2"; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL $1: no '$3' in: $2"; fi; }
hasnt() { if grep -qF -- "$3" <<<"$2"; then fail=$((fail + 1)); echo "FAIL $1: found '$3'"; else pass=$((pass + 1)); fi; }
L="$T/loop"

# wire the stub driver and the fakes
wire_stub() {
cp "$here/driver-stub.sh" "$L/"
export STUB="$T/stub" LOOP_SLEEP_SCALE=0 FAKE="$T/fake"
mkdir -p "$STUB" "$FAKE" "$T/bin" "$T/repo" "$T/cache" "$T/claude/plugins"
# the fake install: the installed issue-loop is this checkout's plugin folder
ln -s "$(cd "$here/.." && pwd)" "$T/cache/0.9.0"
printf '{"version":2,"plugins":{"issue-loop@pgoell-claude-tools":[{"scope":"user","installPath":"%s/cache/0.9.0","version":"0.9.0"}]}}\n' "$T" >"$T/claude/plugins/installed_plugins.json"
export CLAUDE_CONFIG_DIR="$T/claude"
sed -i -e 's|^DRIVER=.*|DRIVER=driver-stub.sh|' -e "s|^REPO=.*|REPO=$T/repo|" -e 's|^ALIVE_URL=.*|ALIVE_URL=https://app.example/alive|' "$L/loop.env"
}

# fake gh, git and curl for gate.sh
make_fakes() {
cat >"$T/bin/gh" <<'GH'
#!/bin/bash
json=""; for ((i = 1; i <= $#; i++)); do [ "${!i}" = --json ] && { j=$((i + 1)); json=${!j}; }; done
case "$1 $2 $json" in
"issue view state") cat "$FAKE/issue_state" ;;
"pr list number") cat "$FAKE/prs" ;;
"pr view state") cat "$FAKE/pr_state" 2>/dev/null || echo MERGED ;;
"pr view autoMergeRequest") cat "$FAKE/auto" 2>/dev/null ;;
"pr checks name,bucket") cat "$FAKE/checks" 2>/dev/null ;;
"pr view title") echo "fix: a thing" ;;
"pr view body") cat "$FAKE/body" ;;
"pr view files") cat "$FAKE/files" ;;
"run list headSha,conclusion") cat "$FAKE/live" ;;
"issue list number,title,labels") echo "  #12 [bug] a new bug" ;;
*) echo "fake gh: $*" >&2; exit 1 ;;
esac
GH
cat >"$T/bin/git" <<'GIT'
#!/bin/bash
case "$*" in
"ls-remote origin refs/heads/main") printf 'abc1234\trefs/heads/main\n' ;;
"--no-optional-locks status --porcelain") cat "$FAKE/dirty" ;;
"branch --show-current") echo main ;;
*) echo "fake git: $*" >&2; exit 1 ;;
esac
GIT
cat >"$T/bin/curl" <<'CURL'
#!/bin/bash
[ -f "$FAKE/down" ] && exit 22; exit 0
CURL
chmod +x "$T/bin"/*
}
