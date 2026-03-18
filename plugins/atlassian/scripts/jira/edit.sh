#!/usr/bin/env bash
# Edit a Jira issue
# Usage: edit.sh <issue-key> [--summary "..."] [--description "..."] [--labels "l1,l2"] [--type "..."]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../_common.sh"
atlassian_check_auth

KEY="" SUMMARY="" DESCRIPTION="" LABELS="" TYPE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --summary) SUMMARY="$2"; shift 2 ;;
        --description) DESCRIPTION="$2"; shift 2 ;;
        --labels) LABELS="$2"; shift 2 ;;
        --type) TYPE="$2"; shift 2 ;;
        *) KEY="$1"; shift ;;
    esac
done

if [[ -z "$KEY" ]]; then
    echo '{"error": "Usage: edit.sh <issue-key> [--summary \"...\"] [--description \"...\"]"}' >&2
    exit 1
fi

FIELDS=""
if [[ -n "$SUMMARY" ]]; then
    FIELDS="\"summary\": \"$(json_escape "$SUMMARY")\""
fi
if [[ -n "$DESCRIPTION" ]]; then
    ADF=$(text_to_adf "$DESCRIPTION")
    [[ -n "$FIELDS" ]] && FIELDS="$FIELDS, "
    FIELDS="${FIELDS}\"description\": $ADF"
fi
if [[ -n "$LABELS" ]]; then
    LABELS_JSON=$(printf '%s' "$LABELS" | $PYTHON_CMD -c 'import sys,json; print(json.dumps([l.strip() for l in sys.stdin.read().split(",")]))')
    [[ -n "$FIELDS" ]] && FIELDS="$FIELDS, "
    FIELDS="${FIELDS}\"labels\": $LABELS_JSON"
fi
if [[ -n "$TYPE" ]]; then
    [[ -n "$FIELDS" ]] && FIELDS="$FIELDS, "
    FIELDS="${FIELDS}\"issuetype\": {\"name\": \"$(json_escape "$TYPE")\"}"
fi

if [[ -z "$FIELDS" ]]; then
    echo '{"error": "No fields to update. Use --summary, --description, --labels, or --type"}' >&2
    exit 1
fi

atlassian_curl -X PUT "$JIRA_BASE/issue/$KEY" -d "{\"fields\": {$FIELDS}}"
