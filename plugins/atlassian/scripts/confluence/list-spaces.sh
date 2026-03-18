#!/usr/bin/env bash
# List Confluence spaces
# Usage: list-spaces.sh [--limit N]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../_common.sh"
atlassian_check_auth

LIMIT=25

while [[ $# -gt 0 ]]; do
    case $1 in
        --limit) LIMIT="$2"; shift 2 ;;
        *) echo "{\"error\": \"Unknown arg: $1\"}" >&2; exit 1 ;;
    esac
done

atlassian_curl "$CONFLUENCE_V2_BASE/spaces?limit=$LIMIT"
