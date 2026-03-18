#!/usr/bin/env bash
# Get a Confluence page by ID
# Usage: get-page.sh <page-id> [--body-format storage|atlas_doc_format|view]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../_common.sh"
atlassian_check_auth

PAGE_ID=""
BODY_FORMAT="storage"

while [[ $# -gt 0 ]]; do
    case $1 in
        --body-format) BODY_FORMAT="$2"; shift 2 ;;
        *) PAGE_ID="$1"; shift ;;
    esac
done

if [[ -z "$PAGE_ID" ]]; then
    echo '{"error": "Usage: get-page.sh <page-id> [--body-format storage|atlas_doc_format|view]"}' >&2
    exit 1
fi

atlassian_curl "$CONFLUENCE_V2_BASE/pages/$PAGE_ID?body-format=$BODY_FORMAT"
