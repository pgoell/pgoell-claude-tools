#!/bin/bash
# usage: tests/run.sh
# Runs the loop's script templates against a stub driver and fake gh, git and
# curl. No session, no network. Needs bash, jq, GNU date, timeout, and script
# from util-linux (grant.sh wants a terminal).
# The cases live in tests/test-*.sh, one file per script or skill under test,
# with the shared checks and fakes in tests/lib.sh. They share one loop folder,
# each case building on the state the one before left, so they run in this order.
set -u
here=$(cd "$(dirname "$0")" && pwd)
. "$here/lib.sh"
for f in init next grant wait notify gate stub takeover start models skill-text rules upgrade; do . "$here/test-$f.sh"; done

test_init
wire_stub
test_next_refusals
test_grant
test_next_sends
test_next_pulls
test_next_go_ahead
test_trusted
test_wait
test_notify
test_gate
test_stub
test_takeover
test_start
test_models
test_skill_text
test_rules
test_upgrade

echo "$pass passed, $fail failed"
[ $fail = 0 ]
