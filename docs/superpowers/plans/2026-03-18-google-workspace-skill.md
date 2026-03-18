# Google Workspace Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `google-workspace` plugin with Gmail and Calendar skills powered by the `gws` CLI.

**Architecture:** Flat plugin under `plugins/google-workspace/` with one SKILL.md per service. No wrapper scripts — the `gws` CLI is invoked directly. Auth gate checks `gws` is on PATH and authenticated. Reference docs for search operators and calendar patterns.

**Tech Stack:** Bash (tests), `gws` CLI, Claude Code plugin system (SKILL.md, plugin.json, marketplace.json)

**Spec:** `docs/superpowers/specs/2026-03-18-google-workspace-skill-design.md`

---

### Task 1: Plugin scaffold and metadata

**Files:**
- Create: `plugins/google-workspace/.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Create plugin.json**

```json
{
  "name": "google-workspace",
  "description": "Gmail and Calendar skills for Google Workspace via the gws CLI",
  "author": {
    "name": "Pascal Kraus"
  },
  "license": "MIT",
  "keywords": ["google", "workspace", "gmail", "calendar", "gws"]
}
```

Write to `plugins/google-workspace/.claude-plugin/plugin.json`.

- [ ] **Step 2: Update marketplace.json**

In `.claude-plugin/marketplace.json`, add to the `plugins` array:

```json
{
  "name": "google-workspace",
  "source": "./plugins/google-workspace",
  "description": "Google Workspace skills (Gmail, Calendar) powered by the gws CLI",
  "version": "1.0.0"
}
```

- [ ] **Step 3: Verify structure**

Run: `find plugins/google-workspace -type f`
Expected: `plugins/google-workspace/.claude-plugin/plugin.json`

Run: `cat .claude-plugin/marketplace.json | python3 -m json.tool`
Expected: Valid JSON with two entries in `plugins` array.

- [ ] **Step 4: Commit**

```bash
git add plugins/google-workspace/.claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "feat: scaffold google-workspace plugin with metadata"
```

---

### Task 2: Gmail SKILL.md

**Files:**
- Create: `plugins/google-workspace/skills/gmail/SKILL.md`

- [ ] **Step 1: Write Gmail SKILL.md**

Create `plugins/google-workspace/skills/gmail/SKILL.md` with the following content. This follows the exact frontmatter and section structure of `plugins/atlassian/skills/jira/SKILL.md`:

```markdown
---
name: gmail
description: Use when the user wants to search, read, send, or manage Gmail messages, drafts, labels, and filters via the gws CLI.
---

# Gmail Skill

Search, read, send, and manage Gmail messages, drafts, labels, and filters using the `gws` CLI.

---

## Auth Gate

Before any operation, verify the gws CLI is available and authenticated:

1. Check gws is on PATH: `which gws`
2. Check auth is valid: `gws auth status`

If either check fails, stop and tell the user:
> "The gws CLI is not installed or not authenticated. Install and configure it: https://github.com/googleworkspace/cli"

---

## Tool Preference

All operations use the `gws` CLI directly. No wrapper scripts.

- **Helper commands** (prefixed with `+`): Use for common operations. These handle formatting, threading, and MIME encoding automatically.
- **Raw API calls**: Use when no helper exists. Pass parameters via `--params '<JSON>'` and request bodies via `--json '<JSON>'`. Resource paths are space-separated (e.g., `gws gmail users messages list`).

Always prefer `+` helpers when one exists for the operation.

---

## Operations — Tier 1 (Read)

### Triage Inbox

Show unread inbox summary:
```bash
gws gmail +triage
```

Filtered/customized:
```bash
gws gmail +triage --query 'from:boss' --max 5
gws gmail +triage --labels
gws gmail +triage --format json
```

### Read a Message

```bash
gws gmail +read --id <messageId>
gws gmail +read --id <messageId> --headers
gws gmail +read --id <messageId> --format json
```

### Search / List Messages

```bash
gws gmail users messages list --params '{"userId": "me", "q": "<query>"}'
```

See `gmail-search-recipes.md` for query syntax.

### List Labels

```bash
gws gmail users labels list --params '{"userId": "me"}'
```

---

## Operations — Tier 2 (Write)

### Send Email

```bash
gws gmail +send --to <addr> --subject '<subj>' --body '<body>'
gws gmail +send --to <addr> --subject '<subj>' --body '<body>' --cc <addr> --bcc <addr>
gws gmail +send --to <addr> --subject '<subj>' --body '<body>' -a <filepath>
gws gmail +send --to <addr> --subject '<subj>' --body '<html>' --html
```

### Reply

```bash
gws gmail +reply --message-id <id> --body '<body>'
```

### Reply All

```bash
gws gmail +reply-all --message-id <id> --body '<body>'
gws gmail +reply-all --message-id <id> --body '<body>' --remove <addr>
```

### Forward

```bash
gws gmail +forward --message-id <id> --to <addr>
gws gmail +forward --message-id <id> --to <addr> --body 'FYI see below'
```

### Create Draft

```bash
gws gmail users drafts create --params '{"userId": "me"}' --json '<draft-json>'
```

---

## Operations — Tier 3 (Manage)

### Trash / Delete Message

```bash
gws gmail users messages trash --params '{"userId": "me", "id": "<id>"}'
gws gmail users messages delete --params '{"userId": "me", "id": "<id>"}'
```

Trash is reversible. Delete is permanent — confirm with the user first.

### Modify Labels on a Message

```bash
gws gmail users messages modify --params '{"userId": "me", "id": "<id>"}' --json '{"addLabelIds": ["STARRED"], "removeLabelIds": ["UNREAD"]}'
```

### Create / Delete Label

```bash
gws gmail users labels create --params '{"userId": "me"}' --json '{"name": "<label-name>"}'
gws gmail users labels delete --params '{"userId": "me", "id": "<labelId>"}'
```

### Filters

```bash
gws gmail users settings filters list --params '{"userId": "me"}'
gws gmail users settings filters create --params '{"userId": "me"}' --json '<filter-json>'
gws gmail users settings filters delete --params '{"userId": "me", "id": "<filterId>"}'
```

---

## Common Gmail Search Recipes

See `gmail-search-recipes.md`

---

## Self-Healing

When a command fails:

- Check the command's help: `gws gmail <command> --help`
- Inspect the API schema: `gws schema gmail.<resource>.<method>`
- Use `--dry-run` to preview requests without executing
- Exit codes: 0=success, 1=API error, 2=auth error, 3=validation, 4=discovery, 5=internal
- Auth errors (exit 2): re-run `gws auth status` and direct user to https://github.com/googleworkspace/cli
- Validation errors (exit 3): check `--params` JSON syntax and required fields

---

## Behavioral Guidelines

- Prefer `+` helper commands over raw API calls when a helper exists.
- JSON is the default output format for all commands including helpers. Use `--format table` for human-readable output when needed.
- Use `--dry-run` to preview destructive operations before executing.
- Confirm with the user before destructive operations (delete). Trash is reversible, delete is not.
- Default `userId` to `me` in `--params` unless the user specifies otherwise.
- When the user asks to "check email" or "what's new", use `+triage`.
- When the user provides a search query, construct the Gmail search string and use `users messages list`.
```

- [ ] **Step 2: Verify file exists and frontmatter is correct**

Run: `head -5 plugins/google-workspace/skills/gmail/SKILL.md`
Expected: YAML frontmatter with `name: gmail` and `description:`.

- [ ] **Step 3: Commit**

```bash
git add plugins/google-workspace/skills/gmail/SKILL.md
git commit -m "feat: add Gmail skill definition"
```

---

### Task 3: Gmail search recipes reference doc

**Files:**
- Create: `plugins/google-workspace/skills/gmail/gmail-search-recipes.md`

- [ ] **Step 1: Write gmail-search-recipes.md**

Create `plugins/google-workspace/skills/gmail/gmail-search-recipes.md`:

```markdown
# Gmail Search Recipes

Common Gmail search operators for use with `gws gmail users messages list --params '{"userId": "me", "q": "<query>"}'` and `gws gmail +triage --query '<query>'`.

---

## Basic Operators

| Operator | Example | Meaning |
|----------|---------|---------|
| `from:` | `from:alice@example.com` | Messages from a sender |
| `to:` | `to:bob@example.com` | Messages to a recipient |
| `cc:` | `cc:carol@example.com` | Messages CC'd to someone |
| `subject:` | `subject:weekly report` | Subject line contains text |
| `is:` | `is:unread` | Read state (`unread`, `read`, `starred`, `important`, `snoozed`) |
| `has:` | `has:attachment` | Messages with attachments |
| `filename:` | `filename:report.pdf` | Attachment filename |
| `label:` | `label:work` | Messages with a specific label |
| `in:` | `in:inbox` | Location (`inbox`, `sent`, `trash`, `spam`, `drafts`, `anywhere`) |

## Date Filters

| Operator | Example | Meaning |
|----------|---------|---------|
| `after:` | `after:2026/01/01` | Messages after date |
| `before:` | `before:2026/03/01` | Messages before date |
| `older_than:` | `older_than:7d` | Older than N days/months/years (`d`, `m`, `y`) |
| `newer_than:` | `newer_than:2d` | Newer than N days/months/years |

## Size Filters

| Operator | Example | Meaning |
|----------|---------|---------|
| `larger:` | `larger:5M` | Larger than size (K, M) |
| `smaller:` | `smaller:100K` | Smaller than size |

## Combining Operators

- **AND** (implicit): `from:alice subject:report` — both must match
- **OR**: `{from:alice from:bob}` — either matches
- **NOT**: `-from:noreply` — exclude a sender
- **Grouping**: `subject:(weekly report)` — phrase in subject

## Common Patterns

```
# Unread from a specific person
from:boss@company.com is:unread

# Recent attachments
has:attachment newer_than:7d

# Important emails this month
is:important after:2026/03/01

# Emails from team, excluding notifications
{from:alice from:bob from:carol} -from:noreply

# Large attachments to clean up
larger:10M older_than:30d

# Invoices and receipts
subject:(invoice OR receipt) has:attachment
```
```

- [ ] **Step 2: Commit**

```bash
git add plugins/google-workspace/skills/gmail/gmail-search-recipes.md
git commit -m "feat: add Gmail search recipes reference"
```

---

### Task 4: Calendar SKILL.md

**Files:**
- Create: `plugins/google-workspace/skills/calendar/SKILL.md`

- [ ] **Step 1: Write Calendar SKILL.md**

Create `plugins/google-workspace/skills/calendar/SKILL.md`:

```markdown
---
name: calendar
description: Use when the user wants to view agenda, create and manage events, check availability, and manage calendars via the gws CLI.
---

# Calendar Skill

View agenda, create and manage events, check availability, and manage calendars using the `gws` CLI.

---

## Auth Gate

Before any operation, verify the gws CLI is available and authenticated:

1. Check gws is on PATH: `which gws`
2. Check auth is valid: `gws auth status`

If either check fails, stop and tell the user:
> "The gws CLI is not installed or not authenticated. Install and configure it: https://github.com/googleworkspace/cli"

---

## Tool Preference

All operations use the `gws` CLI directly. No wrapper scripts.

- **Helper commands** (prefixed with `+`): Use for common operations. These handle timezone detection, formatting, and attendee management automatically.
- **Raw API calls**: Use when no helper exists. Pass parameters via `--params '<JSON>'` and request bodies via `--json '<JSON>'`. Resource paths are space-separated (e.g., `gws calendar events list`).

Always prefer `+` helpers when one exists for the operation.

---

## Operations — Tier 1 (Read)

### View Agenda

```bash
gws calendar +agenda
gws calendar +agenda --today
gws calendar +agenda --tomorrow
gws calendar +agenda --week
gws calendar +agenda --days 3
gws calendar +agenda --calendar 'Work'
gws calendar +agenda --today --timezone America/New_York
```

### Get Event Details

```bash
gws calendar events get --params '{"calendarId": "primary", "eventId": "<id>"}'
```

### List Events (Filtered)

```bash
gws calendar events list --params '{"calendarId": "primary", "timeMin": "<iso>", "timeMax": "<iso>"}'
```

### Check Availability

```bash
gws calendar freebusy query --json '{"timeMin": "<iso>", "timeMax": "<iso>", "items": [{"id": "primary"}]}'
```

---

## Operations — Tier 2 (Write)

### Create Event

```bash
gws calendar +insert --summary '<title>' --start '<iso>' --end '<iso>'
gws calendar +insert --summary '<title>' --start '<iso>' --end '<iso>' --location '<place>'
gws calendar +insert --summary '<title>' --start '<iso>' --end '<iso>' --attendee alice@example.com --attendee bob@example.com
gws calendar +insert --summary '<title>' --start '<iso>' --end '<iso>' --meet
gws calendar +insert --summary '<title>' --start '<iso>' --end '<iso>' --description '<text>'
```

### Quick-Add Event

```bash
gws calendar events quickAdd --params '{"calendarId": "primary", "text": "<natural language>"}'
```

### Update Event

```bash
gws calendar events patch --params '{"calendarId": "primary", "eventId": "<id>"}' --json '<event-json>'
```

### Move Event

```bash
gws calendar events move --params '{"calendarId": "primary", "eventId": "<id>", "destination": "<calId>"}'
```

---

## Operations — Tier 3 (Manage)

### Delete Event

```bash
gws calendar events delete --params '{"calendarId": "primary", "eventId": "<id>"}'
```

Confirm with the user before deleting.

### List Calendars

```bash
gws calendar calendarList list
```

### Create / Delete Calendar

```bash
gws calendar calendars insert --json '{"summary": "<name>"}'
gws calendar calendars delete --params '{"calendarId": "<id>"}'
```

Confirm with the user before deleting a calendar.

### Access Control (ACL)

```bash
gws calendar acl list --params '{"calendarId": "<id>"}'
gws calendar acl insert --params '{"calendarId": "<id>"}' --json '{"role": "reader", "scope": {"type": "user", "value": "<email>"}}'
gws calendar acl delete --params '{"calendarId": "<id>", "ruleId": "<ruleId>"}'
```

---

## Common Calendar Recipes

See `calendar-recipes.md`

---

## Self-Healing

When a command fails:

- Check the command's help: `gws calendar <command> --help`
- Inspect the API schema: `gws schema calendar.<resource>.<method>`
- Use `--dry-run` to preview requests without executing
- Exit codes: 0=success, 1=API error, 2=auth error, 3=validation, 4=discovery, 5=internal
- Auth errors (exit 2): re-run `gws auth status` and direct user to https://github.com/googleworkspace/cli
- Validation errors (exit 3): check `--params` JSON syntax and required fields

---

## Behavioral Guidelines

- Prefer `+` helpers (`+agenda`, `+insert`) over raw API calls when available.
- Default to `"calendarId": "primary"` in `--params` unless the user specifies a different calendar.
- Use ISO 8601 / RFC 3339 format for all timestamps (e.g., `2026-03-18T14:00:00-04:00`).
- Use `--dry-run` to preview commands before executing destructive operations.
- Confirm with the user before deleting events or calendars.
- When creating events with `+insert`, include timezone offset in the ISO timestamp.
- When the user asks "what's on my calendar" or "meetings today", use `+agenda --today`.
- When the user gives a natural-language event description, prefer `quickAdd` for simple cases and `+insert` for structured cases.
```

- [ ] **Step 2: Verify frontmatter**

Run: `head -5 plugins/google-workspace/skills/calendar/SKILL.md`
Expected: YAML frontmatter with `name: calendar`.

- [ ] **Step 3: Commit**

```bash
git add plugins/google-workspace/skills/calendar/SKILL.md
git commit -m "feat: add Calendar skill definition"
```

---

### Task 5: Calendar recipes reference doc

**Files:**
- Create: `plugins/google-workspace/skills/calendar/calendar-recipes.md`

- [ ] **Step 1: Write calendar-recipes.md**

Create `plugins/google-workspace/skills/calendar/calendar-recipes.md`:

```markdown
# Calendar Recipes

Common patterns for Google Calendar operations via the `gws` CLI.

---

## Agenda Shortcuts

```bash
# Today's events
gws calendar +agenda --today

# Tomorrow
gws calendar +agenda --tomorrow

# This week
gws calendar +agenda --week

# Next 3 days
gws calendar +agenda --days 3

# Specific calendar only
gws calendar +agenda --calendar 'Work'

# With timezone override
gws calendar +agenda --today --timezone America/New_York
```

## Listing Events with Date Ranges

Use ISO 8601 / RFC 3339 timestamps:

```bash
# Events today (construct timeMin/timeMax for the day)
gws calendar events list --params '{"calendarId": "primary", "timeMin": "2026-03-18T00:00:00Z", "timeMax": "2026-03-18T23:59:59Z"}'

# Events this week
gws calendar events list --params '{"calendarId": "primary", "timeMin": "2026-03-16T00:00:00Z", "timeMax": "2026-03-22T23:59:59Z"}'

# Single events only (expand recurring)
gws calendar events list --params '{"calendarId": "primary", "timeMin": "2026-03-18T00:00:00Z", "timeMax": "2026-03-18T23:59:59Z", "singleEvents": true, "orderBy": "startTime"}'
```

## Finding Free Slots

```bash
# Check availability for a single calendar
gws calendar freebusy query --json '{"timeMin": "2026-03-18T09:00:00Z", "timeMax": "2026-03-18T17:00:00Z", "items": [{"id": "primary"}]}'

# Check multiple calendars
gws calendar freebusy query --json '{"timeMin": "2026-03-18T09:00:00Z", "timeMax": "2026-03-18T17:00:00Z", "items": [{"id": "primary"}, {"id": "colleague@example.com"}]}'
```

## Creating Events

```bash
# Basic event
gws calendar +insert --summary 'Team Standup' --start '2026-03-19T09:00:00-04:00' --end '2026-03-19T09:30:00-04:00'

# With attendees and Meet link
gws calendar +insert --summary 'Sprint Review' --start '2026-03-20T14:00:00-04:00' --end '2026-03-20T15:00:00-04:00' --attendee alice@example.com --attendee bob@example.com --meet

# With location and description
gws calendar +insert --summary 'Lunch' --start '2026-03-19T12:00:00-04:00' --end '2026-03-19T13:00:00-04:00' --location 'Conference Room A' --description 'Weekly team lunch'

# Quick-add from natural language
gws calendar events quickAdd --params '{"calendarId": "primary", "text": "Lunch with Alice tomorrow at noon"}'
```

## Recurring Events

Create via raw API with `recurrence` field:

```bash
gws calendar events insert --params '{"calendarId": "primary"}' --json '{
  "summary": "Daily Standup",
  "start": {"dateTime": "2026-03-18T09:00:00-04:00", "timeZone": "America/New_York"},
  "end": {"dateTime": "2026-03-18T09:15:00-04:00", "timeZone": "America/New_York"},
  "recurrence": ["RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR"]
}'
```

Common RRULE patterns:
- `RRULE:FREQ=DAILY` — every day
- `RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR` — Mon/Wed/Fri
- `RRULE:FREQ=MONTHLY;BYMONTHDAY=1` — first of every month
- `RRULE:FREQ=WEEKLY;COUNT=10` — weekly for 10 occurrences
- `RRULE:FREQ=WEEKLY;UNTIL=20261231T000000Z` — weekly until end of year

## All-Day Events

Use `date` instead of `dateTime`:

```bash
gws calendar events insert --params '{"calendarId": "primary"}' --json '{
  "summary": "Company Holiday",
  "start": {"date": "2026-03-20"},
  "end": {"date": "2026-03-21"}
}'
```

Note: end date is exclusive (March 21 means the event covers only March 20).

## Updating Events

```bash
# Change title
gws calendar events patch --params '{"calendarId": "primary", "eventId": "<id>"}' --json '{"summary": "New Title"}'

# Add attendee
gws calendar events patch --params '{"calendarId": "primary", "eventId": "<id>"}' --json '{"attendees": [{"email": "new@example.com"}]}'

# Change time
gws calendar events patch --params '{"calendarId": "primary", "eventId": "<id>"}' --json '{"start": {"dateTime": "2026-03-19T10:00:00-04:00"}, "end": {"dateTime": "2026-03-19T11:00:00-04:00"}}'
```

## Timezone Handling

- `+agenda` auto-detects your Google account timezone; override with `--timezone <IANA>`
- Always include timezone offset in ISO timestamps: `2026-03-18T14:00:00-04:00`
- Set `timeZone` field in event JSON for recurring events: `"timeZone": "America/New_York"`
- Use `Z` suffix for UTC: `2026-03-18T18:00:00Z`
```

- [ ] **Step 2: Commit**

```bash
git add plugins/google-workspace/skills/calendar/calendar-recipes.md
git commit -m "feat: add Calendar recipes reference"
```

---

### Task 6: Add gws auth helper to test-helpers.sh

**Files:**
- Modify: `tests/test-helpers.sh`

- [ ] **Step 1: Add check_gws_auth function**

Append before the `# Export functions` block in `tests/test-helpers.sh`:

```bash
# Check if gws CLI is authenticated
check_gws_auth() {
    command -v gws &>/dev/null && gws auth status &>/dev/null 2>&1
}
```

- [ ] **Step 2: Extend show_tools_used to detect gws commands**

In the `show_tools_used` function, add a grep for `gws` commands after the existing `acli` grep (around line 200):

```bash
grep -oE 'gws (gmail|calendar) [+a-z_-]+' "$log_file" 2>/dev/null | sort -u | sed 's/^/    - gws: /' || true
```

Also update the "no commands detected" guard to include `gws`:

```bash
if ! grep -qE 'scripts/|acli |curl -s|gws ' "$log_file" 2>/dev/null; then echo "    (no commands detected)"; fi
```

- [ ] **Step 3: Add export for the new function**

Add to the export block:

```bash
export -f check_gws_auth
```

- [ ] **Step 4: Commit**

```bash
git add tests/test-helpers.sh
git commit -m "feat: add check_gws_auth helper for Google Workspace tests"
```

---

### Task 7: Gmail unit tests

**Files:**
- Create: `tests/unit/test-gmail-skill.sh`

- [ ] **Step 1: Write test-gmail-skill.sh**

Create `tests/unit/test-gmail-skill.sh` following the exact pattern from `tests/unit/test-jira-skill.sh`:

```bash
#!/usr/bin/env bash
# Test: gmail skill
# Verifies the skill is loaded and describes correct capabilities
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../test-helpers.sh"

echo "=== Test: gmail skill ==="
echo ""

# Test 1: Skill recognition and auth
echo "Test 1: Skill loading and auth gate..."

output=$(run_claude "What is the gmail skill? Describe its authentication requirements briefly." 30)

assert_contains "$output" "gmail|Gmail" "Skill is recognized" || true
assert_contains "$output" "gws|auth|authenticated" "Mentions authentication" || true

echo ""

# Test 2: Tool preference
echo "Test 2: Tool preference..."

output=$(run_claude "In the gmail skill, what tool does it use to interact with Gmail? What are helper commands?" 30)

assert_contains "$output" "gws" "Mentions gws CLI" || true
assert_contains "$output" "helper|\+send|\+triage|\+read" "Mentions helper commands" || true

echo ""

# Test 3: Operations coverage
echo "Test 3: Operations coverage..."

output=$(run_claude "What operations can the gmail skill perform? List the main categories." 30)

assert_contains "$output" "triage|inbox|unread" "Mentions triage/inbox" || true
assert_contains "$output" "send|email|message" "Mentions sending" || true
assert_contains "$output" "read|search|list" "Mentions reading/searching" || true
assert_contains "$output" "label|filter|manage" "Mentions management" || true

echo ""

# Test 4: Supporting references
echo "Test 4: Supporting references..."

output=$(run_claude "Does the gmail skill reference any supporting files for search queries? What are they?" 30)

assert_contains "$output" "search|recipe|operator" "Mentions search recipes" || true

echo ""

echo "=== gmail skill tests complete ==="
```

- [ ] **Step 2: Make executable**

Run: `chmod +x tests/unit/test-gmail-skill.sh`

- [ ] **Step 3: Commit**

```bash
git add tests/unit/test-gmail-skill.sh
git commit -m "test: add Gmail skill unit tests"
```

---

### Task 8: Calendar unit tests

**Files:**
- Create: `tests/unit/test-calendar-skill.sh`

- [ ] **Step 1: Write test-calendar-skill.sh**

```bash
#!/usr/bin/env bash
# Test: calendar skill
# Verifies the skill is loaded and describes correct capabilities
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../test-helpers.sh"

echo "=== Test: calendar skill ==="
echo ""

# Test 1: Skill recognition and auth
echo "Test 1: Skill loading and auth gate..."

output=$(run_claude "What is the calendar skill? Describe its authentication requirements briefly." 30)

assert_contains "$output" "calendar|Calendar" "Skill is recognized" || true
assert_contains "$output" "gws|auth|authenticated" "Mentions authentication" || true

echo ""

# Test 2: Tool preference
echo "Test 2: Tool preference..."

output=$(run_claude "In the calendar skill, what tool does it use to interact with Google Calendar? What are helper commands?" 30)

assert_contains "$output" "gws" "Mentions gws CLI" || true
assert_contains "$output" "helper|\+agenda|\+insert" "Mentions helper commands" || true

echo ""

# Test 3: Operations coverage
echo "Test 3: Operations coverage..."

output=$(run_claude "What operations can the calendar skill perform? List the main categories." 30)

assert_contains "$output" "agenda|events|schedule" "Mentions agenda/events" || true
assert_contains "$output" "create|insert|add" "Mentions event creation" || true
assert_contains "$output" "delete|manage|calendar" "Mentions management" || true
assert_contains "$output" "free|busy|availability" "Mentions availability" || true

echo ""

# Test 4: Supporting references
echo "Test 4: Supporting references..."

output=$(run_claude "Does the calendar skill reference any supporting files for common patterns? What are they?" 30)

assert_contains "$output" "recipe|pattern|example" "Mentions recipes/patterns" || true

echo ""

echo "=== calendar skill tests complete ==="
```

- [ ] **Step 2: Make executable**

Run: `chmod +x tests/unit/test-calendar-skill.sh`

- [ ] **Step 3: Commit**

```bash
git add tests/unit/test-calendar-skill.sh
git commit -m "test: add Calendar skill unit tests"
```

---

### Task 9: Gmail integration tests

**Files:**
- Create: `tests/integration/test-gmail-integration.sh`

- [ ] **Step 1: Write test-gmail-integration.sh**

```bash
#!/usr/bin/env bash
# Test: Gmail integration (live API)
# Requires gws auth (gws auth login -s gmail)
# Captures stream-json to verify which tools Claude uses
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../test-helpers.sh"
cd "$(cd "$SCRIPT_DIR/../.." && pwd)"

LOG_DIR=$(mktemp -d)
trap "rm -rf $LOG_DIR" EXIT

echo "=== Test: Gmail integration (live API) ==="

# Skip if no gws auth available
if ! check_gws_auth; then
    echo "  [SKIP] No gws auth configured (run 'gws auth login -s gmail')"
    exit 0
fi

# Test 1: Triage inbox
echo ""
echo "Test 1: Triage inbox"
output=$(run_claude_logged "Triage my Gmail inbox using the gws CLI. Show a summary of unread messages." "$LOG_DIR/triage.json" 120)
assert_contains "$output" "inbox|unread|message|subject|from" "Triage returned results" || true
show_tools_used "$LOG_DIR/triage.json"

# Test 2: Search messages
echo ""
echo "Test 2: Search messages"
output=$(run_claude_logged "Search my Gmail for messages from the last 7 days using the gws CLI." "$LOG_DIR/search.json" 120)
assert_contains "$output" "message|result|email|subject" "Search returned results" || true
show_tools_used "$LOG_DIR/search.json"

# Test 3: Read a message
echo ""
echo "Test 3: Read a message (most recent)"
output=$(run_claude_logged "Use gws to find my most recent Gmail message and read its content." "$LOG_DIR/read.json" 120)
assert_not_contains "$output" "unauthorized|403|401" "No auth errors" || true
show_tools_used "$LOG_DIR/read.json"

# Test 4: Send email (to self)
echo ""
echo "Test 4: Send email to self"
TIMESTAMP=$(date +%s)
output=$(run_claude_logged "Use gws to send an email to me (my own address) with subject 'Integration test $TIMESTAMP' and body 'Automated test from spycner-tools'." "$LOG_DIR/send.json" 120)
assert_not_contains "$output" "unauthorized|403|401" "Send without auth errors" || true
show_tools_used "$LOG_DIR/send.json"

# Test 5: Create and delete a label
echo ""
echo "Test 5: Create and delete a label"
output=$(run_claude_logged "Use gws to create a Gmail label called 'test-label-$TIMESTAMP', then immediately delete it." "$LOG_DIR/label.json" 180)
assert_not_contains "$output" "unauthorized|403|401" "Label ops without auth errors" || true
show_tools_used "$LOG_DIR/label.json"

echo ""
echo "=== Gmail integration tests complete ==="
```

- [ ] **Step 2: Make executable**

Run: `chmod +x tests/integration/test-gmail-integration.sh`

- [ ] **Step 3: Commit**

```bash
git add tests/integration/test-gmail-integration.sh
git commit -m "test: add Gmail integration tests"
```

---

### Task 10: Calendar integration tests

**Files:**
- Create: `tests/integration/test-calendar-integration.sh`

- [ ] **Step 1: Write test-calendar-integration.sh**

```bash
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
```

- [ ] **Step 2: Make executable**

Run: `chmod +x tests/integration/test-calendar-integration.sh`

- [ ] **Step 3: Commit**

```bash
git add tests/integration/test-calendar-integration.sh
git commit -m "test: add Calendar integration tests"
```

---

### Task 11: Skill triggering tests

**Files:**
- Create: `tests/skill-triggering/prompts/gmail-send.txt`
- Create: `tests/skill-triggering/prompts/gmail-triage.txt`
- Create: `tests/skill-triggering/prompts/gmail-search.txt`
- Create: `tests/skill-triggering/prompts/calendar-agenda.txt`
- Create: `tests/skill-triggering/prompts/calendar-create.txt`
- Create: `tests/skill-triggering/prompts/calendar-availability.txt`

- [ ] **Step 1: Create prompt files**

Each file contains a single line — the prompt to test:

`tests/skill-triggering/prompts/gmail-send.txt`:
```
Send an email to bob@example.com about the project update
```

`tests/skill-triggering/prompts/gmail-triage.txt`:
```
What's in my inbox?
```

`tests/skill-triggering/prompts/gmail-search.txt`:
```
Find emails from alice about the report
```

`tests/skill-triggering/prompts/calendar-agenda.txt`:
```
What meetings do I have today?
```

`tests/skill-triggering/prompts/calendar-create.txt`:
```
Schedule a meeting with the team tomorrow at 2pm
```

`tests/skill-triggering/prompts/calendar-availability.txt`:
```
When am I free this week?
```

- [ ] **Step 2: Verify the existing run-test.sh works with google-workspace plugin**

The existing `run-test.sh` uses `PLUGIN_DIR` env var. To run these tests, set:
```bash
PLUGIN_DIR=plugins/google-workspace bash tests/skill-triggering/run-test.sh gmail tests/skill-triggering/prompts/gmail-send.txt
```

Verify the script doesn't have hardcoded paths that break with a different plugin.

- [ ] **Step 3: Commit**

```bash
git add tests/skill-triggering/prompts/gmail-send.txt tests/skill-triggering/prompts/gmail-triage.txt tests/skill-triggering/prompts/gmail-search.txt tests/skill-triggering/prompts/calendar-agenda.txt tests/skill-triggering/prompts/calendar-create.txt tests/skill-triggering/prompts/calendar-availability.txt
git commit -m "test: add skill triggering prompts for Gmail and Calendar"
```

---

### Task 12: Update README.md

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update README**

Update `README.md` to add the Google Workspace plugin. The final README should be:

```markdown
# spycner-tools

A personal Claude Code plugin marketplace.

## Plugins

### atlassian

Jira and Confluence skills for the Atlassian suite — search, create, update, and manage work items and pages.

**Skills:**
- `/spycner-tools:jira` — Search issues, create/update tickets, transition status, add comments, manage sprints
- `/spycner-tools:confluence` — Search pages, read documentation, create/update pages, browse spaces

### google-workspace

Gmail and Calendar skills for Google Workspace — powered by the `gws` CLI.

**Skills:**
- `/spycner-tools:gmail` — Search, read, send, and manage Gmail messages, drafts, labels, and filters
- `/spycner-tools:calendar` — View agenda, create and manage events, check availability, manage calendars

## Installation

```
/plugin marketplace add Spycner/spycner-tools
/plugin install atlassian@spycner-tools
/plugin install google-workspace@spycner-tools
```

## Setup

### Atlassian

The plugin supports two authentication paths:

**Option 1 — Atlassian CLI (recommended):**
```bash
brew install atlassian/tap/acli
acli auth login
```

**Option 2 — API token (for curl fallback):**

Generate a token at https://id.atlassian.com/manage/api-tokens, then set:

```bash
export ATLASSIAN_DOMAIN="your-domain"    # e.g. mycompany (for mycompany.atlassian.net)
export ATLASSIAN_EMAIL="you@company.com"
export ATLASSIAN_API_TOKEN="your-token"
```

### Google Workspace

Install and authenticate the `gws` CLI:

```bash
npm i -g @anthropic-ai/gws
gws auth login -s gmail,calendar
```

For full setup instructions, see: https://github.com/googleworkspace/cli
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add Google Workspace plugin to README"
```

---

### Task 13: Final verification

- [ ] **Step 1: Verify complete directory structure**

Run: `find plugins/google-workspace -type f | sort`

Expected:
```
plugins/google-workspace/.claude-plugin/plugin.json
plugins/google-workspace/skills/calendar/SKILL.md
plugins/google-workspace/skills/calendar/calendar-recipes.md
plugins/google-workspace/skills/gmail/SKILL.md
plugins/google-workspace/skills/gmail/gmail-search-recipes.md
```

- [ ] **Step 2: Verify marketplace.json**

Run: `cat .claude-plugin/marketplace.json | python3 -m json.tool`

Expected: Valid JSON with `atlassian` and `google-workspace` in `plugins` array.

- [ ] **Step 3: Verify all test files exist and are executable**

Run: `ls -la tests/unit/test-gmail-skill.sh tests/unit/test-calendar-skill.sh tests/integration/test-gmail-integration.sh tests/integration/test-calendar-integration.sh`

Expected: All files exist with execute permission.

Run: `ls tests/skill-triggering/prompts/gmail-*.txt tests/skill-triggering/prompts/calendar-*.txt`

Expected: 6 prompt files.

- [ ] **Step 4: Run unit tests (if Claude CLI available)**

```bash
PLUGIN_DIR=plugins/google-workspace bash tests/unit/test-gmail-skill.sh
PLUGIN_DIR=plugins/google-workspace bash tests/unit/test-calendar-skill.sh
```

- [ ] **Step 5: Verify git log**

Run: `git log --oneline feat/google-workspace-skill`

Expected: Clean sequence of commits from the spec through all implementation tasks.
