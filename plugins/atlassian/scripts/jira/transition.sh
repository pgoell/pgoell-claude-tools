#!/usr/bin/env bash
# Transition a Jira issue to a new status
# Usage: transition.sh <issue-key> <status-name>
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../_common.sh"
atlassian_check_auth

if [[ $# -lt 2 ]]; then
    echo '{"error": "Usage: transition.sh <issue-key> <status-name>"}' >&2
    exit 1
fi

KEY="$1"
TARGET_STATUS="$2"

# Fetch available transitions
TRANSITIONS=$(atlassian_curl "$JIRA_BASE/issue/$KEY/transitions")

# Find matching transition ID (case-insensitive)
TRANSITION_ID=$(echo "$TRANSITIONS" | $PYTHON_CMD -c "
import sys, json
data = json.load(sys.stdin)
target = '$TARGET_STATUS'.lower()
for t in data.get('transitions', []):
    if t['to']['name'].lower() == target or t['name'].lower() == target:
        print(t['id'])
        break
")

if [[ -z "$TRANSITION_ID" ]]; then
    AVAILABLE=$(echo "$TRANSITIONS" | $PYTHON_CMD -c "
import sys, json
data = json.load(sys.stdin)
print(', '.join(t['to']['name'] for t in data.get('transitions', [])))
")
    echo "{\"error\": \"Status '$TARGET_STATUS' not found. Available: $AVAILABLE\"}" >&2
    exit 1
fi

atlassian_curl -X POST "$JIRA_BASE/issue/$KEY/transitions" -d "{\"transition\": {\"id\": \"$TRANSITION_ID\"}}"
