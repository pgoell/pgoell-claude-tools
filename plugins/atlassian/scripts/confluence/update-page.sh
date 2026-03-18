#!/usr/bin/env bash
# Update a Confluence page (handles version increment)
# Usage: update-page.sh <page-id> --body "..." [--title "..."]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../_common.sh"
atlassian_check_auth

PAGE_ID="" BODY="" TITLE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --body) BODY="$2"; shift 2 ;;
        --title) TITLE="$2"; shift 2 ;;
        *) PAGE_ID="$1"; shift ;;
    esac
done

if [[ -z "$PAGE_ID" || -z "$BODY" ]]; then
    echo '{"error": "Usage: update-page.sh <page-id> --body \"...\" [--title \"...\"]"}' >&2
    exit 1
fi

# GET current page for version number and title
CURRENT=$(atlassian_curl "$CONFLUENCE_V2_BASE/pages/$PAGE_ID")

PAYLOAD=$(printf '%s\n%s\n%s\n%s' "$PAGE_ID" "$TITLE" "$BODY" "$CURRENT" | $PYTHON_CMD -c "
import json, sys
parts = sys.stdin.read().split('\n', 3)
page_id, title, body, current_json = parts[0], parts[1], parts[2], parts[3]
current = json.loads(current_json)
version = current['version']['number'] + 1
final_title = title if title else current['title']
print(json.dumps({
    'id': page_id,
    'status': 'current',
    'title': final_title,
    'version': {'number': version},
    'body': {
        'representation': 'storage',
        'value': body
    }
}))
")

atlassian_curl -X PUT "$CONFLUENCE_V2_BASE/pages/$PAGE_ID" -d "$PAYLOAD"
