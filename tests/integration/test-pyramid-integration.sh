#!/usr/bin/env bash
# Integration test: pyramid skill (greenfield end-to-end)
# Runs the full five-phase pipeline on a fixture topic and verifies artifacts
# NOTE: dispatches one construct + four audits + one opener; expect 4-8 minutes
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../test-helpers.sh"

echo "=== Integration Test: pyramid skill (greenfield end-to-end) ==="
echo ""

TEST_DIR=$(mktemp -d)
LOG_FILE=$(mktemp)
trap 'rm -rf "$TEST_DIR" "$LOG_FILE"' EXIT

echo "Working dir: $TEST_DIR"
echo ""

echo "Test 1: Full pipeline runs end-to-end..."
# Intake answers are embedded in the prompt so the pipeline runs non-interactively.
PROMPT="Run the full pyramid skill pipeline in greenfield mode in $TEST_DIR. Use --phase intake to start. Topic: 'We should raise Series B in Q1 2027.' Audience: 'board of directors.' Reader question: 'should we raise now or wait?' Genre: 'recommendation.' Do not ask me any follow-up questions; proceed with the answers given. When you reach the domain-limits gate, proceed anyway (this IS a recommendation document, so it should pass the gate). Continue through construct, audit, opener, and render."

output=$(run_claude_logged "$PROMPT" "$LOG_FILE" 600)

echo ""
echo "Test 2: All nine artifacts exist..."
for artifact in intake.md construction.md audit-mece.md audit-so-what.md audit-qa.md audit-logic.md audit-summary.md opener.md pyramid.md; do
    if [ -f "$TEST_DIR/$artifact" ]; then
        echo "  [PASS] $artifact created"
    else
        echo "  [FAIL] $artifact not found"
    fi
done

echo ""
echo "Test 3: pyramid.md contains required top-level sections..."
if [ -f "$TEST_DIR/pyramid.md" ]; then
    for section in 'Opener (SCQA)' '## Apex' '## Supporting findings' '## Audit notes'; do
        if grep -qF "$section" "$TEST_DIR/pyramid.md"; then
            echo "  [PASS] pyramid.md contains: $section"
        else
            echo "  [FAIL] pyramid.md missing: $section"
        fi
    done
else
    echo "  [FAIL] pyramid.md does not exist; cannot check sections"
fi

echo ""
echo "Test 4: audit-summary.md has verdicts table with four rows..."
if [ -f "$TEST_DIR/audit-summary.md" ]; then
    verdict_rows=$(grep -cE '\| (MECE|So-What|Q-A|Inductive)' "$TEST_DIR/audit-summary.md" || true)
    if [ "$verdict_rows" -ge 4 ]; then
        echo "  [PASS] audit-summary.md has 4+ verdict rows ($verdict_rows found)"
    else
        echo "  [FAIL] audit-summary.md has only $verdict_rows verdict rows; expected 4"
    fi
fi

echo ""
echo "Test 5: Each audit file starts with a Verdict line..."
for audit in mece so-what qa logic; do
    file="$TEST_DIR/audit-${audit}.md"
    if [ -f "$file" ]; then
        first_verdict=$(grep -m1 -E '^\*\*Verdict:\*\*' "$file" || true)
        if [ -n "$first_verdict" ]; then
            echo "  [PASS] audit-${audit}.md has Verdict line: $first_verdict"
        else
            echo "  [FAIL] audit-${audit}.md missing Verdict line"
        fi
    fi
done

echo ""
echo "Test 6: State file records last_completed_phase=render..."
STATE_FILE="$HOME/.claude/projects/$(echo "$TEST_DIR" | sed 's|/|-|g; s|^-||')/pyramid-skill-state.json"
if [ -f "$STATE_FILE" ]; then
    if grep -q '"last_completed_phase": "render"' "$STATE_FILE"; then
        echo "  [PASS] state file records last_completed_phase=render"
    else
        echo "  [FAIL] state file does not record render as last phase"
        cat "$STATE_FILE" | sed 's/^/    /'
    fi
else
    echo "  [WARN] state file not found at $STATE_FILE (orchestrator may use different path)"
fi

echo ""
echo "Test 7: Apex in pyramid.md is a finding, not a label..."
if [ -f "$TEST_DIR/pyramid.md" ]; then
    apex_line=$(grep -A1 '^## Apex' "$TEST_DIR/pyramid.md" | tail -1)
    if echo "$apex_line" | grep -qiE "raise|Series B|Q1 2027"; then
        echo "  [PASS] Apex names the finding (contains raise/Series B/Q1 2027)"
    else
        echo "  [FAIL] Apex does not contain the expected topic keywords"
        echo "    Apex line: $apex_line"
    fi
fi

echo ""
echo "=== pyramid integration test complete ==="
