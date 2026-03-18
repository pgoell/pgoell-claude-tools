#!/usr/bin/env bash
# Shared library for Atlassian wrapper scripts
# Source this file — do not execute directly

set -euo pipefail

# --- Auth ---

atlassian_check_auth() {
    if [[ -z "${ATLASSIAN_DOMAIN:-}" || -z "${ATLASSIAN_EMAIL:-}" || -z "${ATLASSIAN_API_TOKEN:-}" ]]; then
        echo '{"error": "Missing env vars. Set ATLASSIAN_DOMAIN, ATLASSIAN_EMAIL, ATLASSIAN_API_TOKEN. Generate a token at https://id.atlassian.com/manage/api-tokens"}' >&2
        exit 1
    fi
}

# --- Base URLs ---

JIRA_BASE="https://${ATLASSIAN_DOMAIN:-}.atlassian.net/rest/api/3"
CONFLUENCE_V1_BASE="https://${ATLASSIAN_DOMAIN:-}.atlassian.net/wiki/rest/api"
CONFLUENCE_V2_BASE="https://${ATLASSIAN_DOMAIN:-}.atlassian.net/wiki/api/v2"

# --- Python detection ---

if command -v python3 &>/dev/null; then
    PYTHON_CMD="python3"
elif command -v python &>/dev/null; then
    PYTHON_CMD="python"
elif command -v uv &>/dev/null; then
    PYTHON_CMD="uv run python"
else
    echo '{"error": "Python is required for JSON escaping. Install python3, python, or uv."}' >&2
    exit 1
fi

# --- Curl wrapper ---

# Usage: atlassian_curl [curl args...]
# Adds auth headers automatically. Pass method, URL, data as normal curl args.
atlassian_curl() {
    local http_code body tmpfile
    tmpfile=$(mktemp)
    http_code=$(curl -s -o "$tmpfile" -w '%{http_code}' \
        -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        "$@")
    body=$(cat "$tmpfile")
    rm -f "$tmpfile"

    if [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
        if [[ -n "$body" ]]; then
            echo "$body"
        fi
    else
        echo "{\"error\": \"HTTP $http_code\", \"body\": $body}" >&2
        exit 1
    fi
}

# --- JSON / ADF helpers ---

# Escape a string for safe embedding in JSON
json_escape() {
    printf '%s' "$1" | $PYTHON_CMD -c 'import sys,json; print(json.dumps(sys.stdin.read())[1:-1])'
}

# Wrap plain text in a minimal ADF document
text_to_adf() {
    local escaped
    escaped=$(json_escape "$1")
    printf '{"version":1,"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"%s"}]}]}' "$escaped"
}
