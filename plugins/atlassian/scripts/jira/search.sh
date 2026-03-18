#!/usr/bin/env bash
# Search Jira issues via JQL
# Usage: search.sh <jql> [--limit N] [--fields f1,f2]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../_common.sh"
atlassian_check_auth

JQL=""
LIMIT=20
FIELDS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --limit) LIMIT="$2"; shift 2 ;;
        --fields) FIELDS="$2"; shift 2 ;;
        *) JQL="$1"; shift ;;
    esac
done

if [[ -z "$JQL" ]]; then
    echo '{"error": "Usage: search.sh <jql> [--limit N] [--fields f1,f2]"}' >&2
    exit 1
fi

PAYLOAD="{\"jql\": $(printf '%s' "$JQL" | $PYTHON_CMD -c 'import sys,json; print(json.dumps(sys.stdin.read()))'), \"maxResults\": $LIMIT"
if [[ -n "$FIELDS" ]]; then
    FIELDS_JSON=$(printf '%s' "$FIELDS" | $PYTHON_CMD -c 'import sys,json; print(json.dumps([f.strip() for f in sys.stdin.read().split(",")]))')
    PAYLOAD="$PAYLOAD, \"fields\": $FIELDS_JSON"
fi
PAYLOAD="$PAYLOAD}"

atlassian_curl -X POST "$JIRA_BASE/search/jql" -d "$PAYLOAD"
