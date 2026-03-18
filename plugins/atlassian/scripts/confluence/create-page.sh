#!/usr/bin/env bash
# Create a Confluence page
# Usage: create-page.sh --space-id ID --title "..." --body "..."
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../_common.sh"
atlassian_check_auth

SPACE_ID="" TITLE="" BODY=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --space-id) SPACE_ID="$2"; shift 2 ;;
        --title) TITLE="$2"; shift 2 ;;
        --body) BODY="$2"; shift 2 ;;
        *) echo "{\"error\": \"Unknown arg: $1\"}" >&2; exit 1 ;;
    esac
done

if [[ -z "$SPACE_ID" || -z "$TITLE" || -z "$BODY" ]]; then
    echo '{"error": "Usage: create-page.sh --space-id ID --title \"...\" --body \"...\""}' >&2
    exit 1
fi

PAYLOAD=$(printf '%s\n%s\n%s' "$SPACE_ID" "$TITLE" "$BODY" | $PYTHON_CMD -c "
import json, sys
lines = sys.stdin.read().split('\n', 2)
print(json.dumps({
    'spaceId': lines[0],
    'title': lines[1],
    'status': 'current',
    'body': {
        'representation': 'storage',
        'value': lines[2]
    }
}))
")

atlassian_curl -X POST "$CONFLUENCE_V2_BASE/pages" -d "$PAYLOAD"
