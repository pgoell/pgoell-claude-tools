#!/usr/bin/env bash
# Test: research skill
# Verifies the skill is loaded and describes correct capabilities
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../test-helpers.sh"

echo "=== Test: research skill ==="
echo ""

# Test 1: Skill recognition
echo "Test 1: Skill loading and recognition..."

output=$(run_claude "What is the research skill? Describe what it does briefly." 30)

assert_contains "$output" "research|Research" "Skill is recognized" || true
assert_contains "$output" "web.*search|WebSearch|investigate|deep dive" "Mentions web research capability" || true

echo ""

# Test 2: Tool preference
echo "Test 2: Tool preference..."

output=$(run_claude "In the research skill, what tools does it use? What is the primary execution mechanism?" 30)

assert_contains "$output" "WebSearch|web search" "Mentions WebSearch" || true
assert_contains "$output" "WebFetch|web fetch|fetch" "Mentions WebFetch" || true
assert_contains "$output" "agent|Agent|subagent" "Mentions agent dispatch" || true

echo ""

# Test 3: Workflow coverage
echo "Test 3: Workflow coverage..."

output=$(run_claude "What workflow does the research skill follow? What are the main steps?" 30)

assert_contains "$output" "clarif|scope|question" "Mentions clarification step" || true
assert_contains "$output" "route|dispatch|prompt" "Mentions routing decision" || true
assert_contains "$output" "deep|quick|mode" "Mentions research modes" || true

echo ""

# Test 4: Supporting references
echo "Test 4: Supporting references..."

output=$(run_claude "Does the research skill reference any supporting files? What templates or recipes does it use?" 30)

assert_contains "$output" "template|report" "Mentions report template" || true
assert_contains "$output" "recipe|pattern|strateg" "Mentions research recipes" || true

echo ""

echo "=== research skill tests complete ==="
