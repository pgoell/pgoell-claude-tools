#!/usr/bin/env bash
# Assign a Jira issue
# Usage: assign.sh <issue-key> <account-id> | assign.sh <issue-key> --me | assign.sh <issue-key> --unassign
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../_common.sh"
atlassian_check_auth

if [[ $# -lt 2 ]]; then
    echo '{"error": "Usage: assign.sh <issue-key> <account-id|--me|--unassign>"}' >&2
    exit 1
fi

KEY="$1"
ASSIGNEE="$2"

if [[ "$ASSIGNEE" == "--unassign" ]]; then
    atlassian_curl -X PUT "$JIRA_BASE/issue/$KEY/assignee" -d '{"accountId": null}'
elif [[ "$ASSIGNEE" == "--me" ]]; then
    MY_ID=$(atlassian_curl "$JIRA_BASE/myself" | $PYTHON_CMD -c 'import sys,json; print(json.load(sys.stdin)["accountId"])')
    atlassian_curl -X PUT "$JIRA_BASE/issue/$KEY/assignee" -d "{\"accountId\": \"$MY_ID\"}"
else
    atlassian_curl -X PUT "$JIRA_BASE/issue/$KEY/assignee" -d "{\"accountId\": \"$(json_escape "$ASSIGNEE")\"}"
fi
