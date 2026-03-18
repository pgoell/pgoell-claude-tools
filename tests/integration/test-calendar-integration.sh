#!/usr/bin/env bash
# Test: Calendar integration (live API)
# Requires gws auth (gws auth login -s calendar)
# Captures stream-json to verify which tools Claude uses
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../test-helpers.sh"
cd "$(cd "$SCRIPT_DIR/../.." && pwd)"

LOG_DIR=$(mktemp -d)
trap "rm -rf $LOG_DIR" EXIT

echo "=== Test: Calendar integration (live API) ==="

# Skip if no gws auth available
if ! check_gws_auth; then
    echo "  [SKIP] No gws auth configured (run 'gws auth login -s calendar')"
    exit 0
fi

# Test 1: View agenda
echo ""
echo "Test 1: View agenda"
output=$(run_claude_logged "Show me my calendar agenda for today using the gws CLI." "$LOG_DIR/agenda.json" 120)
assert_not_contains "$output" "unauthorized|403|401" "Agenda without auth errors" || true
show_tools_used "$LOG_DIR/agenda.json"

# Test 2: Create a test event
echo ""
echo "Test 2: Create a test event"
TIMESTAMP=$(date +%s)
# Create event 2 hours from now
START_TIME=$(date -u -d "+2 hours" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v+2H +%Y-%m-%dT%H:%M:%SZ)
END_TIME=$(date -u -d "+3 hours" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v+3H +%Y-%m-%dT%H:%M:%SZ)
output=$(run_claude_logged "Use gws to create a calendar event with summary 'Test Event $TIMESTAMP' starting at $START_TIME and ending at $END_TIME." "$LOG_DIR/create.json" 120)
assert_not_contains "$output" "unauthorized|403|401" "Create without auth errors" || true
show_tools_used "$LOG_DIR/create.json"

# Extract event ID from output
EVENT_ID=$(echo "$output" | grep -oE '"id":\s*"[^"]+' | head -1 | sed 's/"id":\s*"//' || true)
if [ -z "$EVENT_ID" ]; then
    EVENT_ID=$(echo "$output" | grep -oE '[a-z0-9]{20,}' | head -1 || true)
fi

if [ -n "$EVENT_ID" ]; then
    echo "  Created event: $EVENT_ID"

    # Test 3: Get event details
    echo ""
    echo "Test 3: Get event details"
    output=$(run_claude_logged "Use gws to get details of calendar event with ID '$EVENT_ID'." "$LOG_DIR/get.json" 120)
    assert_contains "$output" "Test Event $TIMESTAMP|$EVENT_ID" "Shows the event" || true
    show_tools_used "$LOG_DIR/get.json"

    # Test 4: Update the event
    echo ""
    echo "Test 4: Update event title"
    output=$(run_claude_logged "Use gws to update calendar event '$EVENT_ID' and change its summary to 'Updated Test $TIMESTAMP'." "$LOG_DIR/update.json" 120)
    assert_not_contains "$output" "unauthorized|403|401" "Update without auth errors" || true
    show_tools_used "$LOG_DIR/update.json"

    # Test 5: Delete the test event
    echo ""
    echo "Test 5: Delete the test event"
    output=$(run_claude_logged "Use gws to delete calendar event '$EVENT_ID'. Proceed without confirmation." "$LOG_DIR/delete.json" 120)
    assert_not_contains "$output" "unauthorized|403|401" "Delete without auth errors" || true
    show_tools_used "$LOG_DIR/delete.json"
else
    echo "  [SKIP] Could not extract event ID from create output"
fi

# Test 6: List calendars
echo ""
echo "Test 6: List calendars"
output=$(run_claude_logged "Use gws to list all my calendars." "$LOG_DIR/list.json" 120)
assert_contains "$output" "calendar|primary|list" "Lists calendars" || true
show_tools_used "$LOG_DIR/list.json"

echo ""
echo "=== Calendar integration tests complete ==="
