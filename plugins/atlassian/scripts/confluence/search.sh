#!/usr/bin/env bash
# Search Confluence pages via CQL
# Usage: search.sh <cql> [--limit N]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../_common.sh"
atlassian_check_auth

CQL=""
LIMIT=10

while [[ $# -gt 0 ]]; do
    case $1 in
        --limit) LIMIT="$2"; shift 2 ;;
        *) CQL="$1"; shift ;;
    esac
done

if [[ -z "$CQL" ]]; then
    echo '{"error": "Usage: search.sh <cql> [--limit N]"}' >&2
    exit 1
fi

ENCODED_CQL=$(printf '%s' "$CQL" | $PYTHON_CMD -c 'import sys,urllib.parse; print(urllib.parse.quote(sys.stdin.read()))')

atlassian_curl "$CONFLUENCE_V1_BASE/search?cql=$ENCODED_CQL&limit=$LIMIT"
