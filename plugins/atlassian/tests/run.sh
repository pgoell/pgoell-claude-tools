#!/bin/bash
# usage: tests/run.sh
# Parses every JSON body in the jira and confluence skills: each ```json fence
# and each curl -d body in a bash fence of skills/*/SKILL.md and
# skills/*/references/*.md, with json.loads. Prints one line per body and the
# count; exits non-zero if any body fails. No network. Needs bash, python3.
set -u
export PYTHONDONTWRITEBYTECODE=1
here=$(cd "$(dirname "$0")" && pwd)
python3 -I "$here/check_json_bodies.py" "$here"/../skills/*/SKILL.md "$here"/../skills/*/references/*.md
