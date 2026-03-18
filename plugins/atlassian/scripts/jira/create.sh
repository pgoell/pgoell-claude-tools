#!/usr/bin/env bash
# Create a Jira issue
# Usage: create.sh --project KEY --type Type --summary "..." [--description "..."] [--assignee account-id]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../_common.sh"
atlassian_check_auth

PROJECT="" TYPE="" SUMMARY="" DESCRIPTION="" ASSIGNEE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --project) PROJECT="$2"; shift 2 ;;
        --type) TYPE="$2"; shift 2 ;;
        --summary) SUMMARY="$2"; shift 2 ;;
        --description) DESCRIPTION="$2"; shift 2 ;;
        --assignee) ASSIGNEE="$2"; shift 2 ;;
        *) echo "{\"error\": \"Unknown arg: $1\"}" >&2; exit 1 ;;
    esac
done

if [[ -z "$PROJECT" || -z "$TYPE" || -z "$SUMMARY" ]]; then
    echo '{"error": "Usage: create.sh --project KEY --type Type --summary \"...\" [--description \"...\"] [--assignee account-id]"}' >&2
    exit 1
fi

SUMMARY_JSON=$(json_escape "$SUMMARY")

PAYLOAD="{\"fields\": {\"project\": {\"key\": \"$PROJECT\"}, \"issuetype\": {\"name\": \"$(json_escape "$TYPE")\"}, \"summary\": \"$SUMMARY_JSON\""

if [[ -n "$DESCRIPTION" ]]; then
    ADF=$(text_to_adf "$DESCRIPTION")
    PAYLOAD="$PAYLOAD, \"description\": $ADF"
fi

if [[ -n "$ASSIGNEE" ]]; then
    PAYLOAD="$PAYLOAD, \"assignee\": {\"id\": \"$(json_escape "$ASSIGNEE")\"}"
fi

PAYLOAD="$PAYLOAD}}"

atlassian_curl -X POST "$JIRA_BASE/issue" -d "$PAYLOAD"
