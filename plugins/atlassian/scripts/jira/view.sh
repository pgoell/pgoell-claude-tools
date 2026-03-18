#!/usr/bin/env bash
# View a Jira issue by key
# Usage: view.sh <issue-key> [--fields f1,f2]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../_common.sh"
atlassian_check_auth

KEY=""
FIELDS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --fields) FIELDS="$2"; shift 2 ;;
        *) KEY="$1"; shift ;;
    esac
done

if [[ -z "$KEY" ]]; then
    echo '{"error": "Usage: view.sh <issue-key> [--fields f1,f2]"}' >&2
    exit 1
fi

URL="$JIRA_BASE/issue/$KEY"
if [[ -n "$FIELDS" ]]; then
    URL="$URL?fields=$FIELDS"
fi

atlassian_curl "$URL"
