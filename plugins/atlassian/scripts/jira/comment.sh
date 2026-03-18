#!/usr/bin/env bash
# Add a comment to a Jira issue
# Usage: comment.sh <issue-key> <comment-text>
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../_common.sh"
atlassian_check_auth

if [[ $# -lt 2 ]]; then
    echo '{"error": "Usage: comment.sh <issue-key> <comment-text>"}' >&2
    exit 1
fi

KEY="$1"
TEXT="$2"
ADF=$(text_to_adf "$TEXT")

atlassian_curl -X POST "$JIRA_BASE/issue/$KEY/comment" -d "{\"body\": $ADF}"
