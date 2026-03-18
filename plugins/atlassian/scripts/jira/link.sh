#!/usr/bin/env bash
# Link two Jira issues
# Usage: link.sh <from-key> <link-type> <to-key>
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../_common.sh"
atlassian_check_auth

if [[ $# -lt 3 ]]; then
    echo '{"error": "Usage: link.sh <from-key> <link-type> <to-key>"}' >&2
    exit 1
fi

FROM="$1"
LINK_TYPE="$2"
TO="$3"

atlassian_curl -X POST "$JIRA_BASE/issueLink" -d "{
    \"type\": {\"name\": \"$(json_escape "$LINK_TYPE")\"},
    \"inwardIssue\": {\"key\": \"$(json_escape "$FROM")\"},
    \"outwardIssue\": {\"key\": \"$(json_escape "$TO")\"}
}"
