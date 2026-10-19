# The skills' own text: handover renames and model invocation
test_skill_text() {
# handover renames: the successor renames itself (#204)
ho="$here/../skills/handing-over"
self='herdr agent prompt <new name> "/rename <project>-orchestrator-main"'
tmpl=$(grep '^> /issue-loop:running-the-loop' "$ho/SKILL.md")
has "first message names the self-rename" "$tmpl" "$self"
has "the self-rename sits next to closing the old tab" "$tmpl" '"/rename <project>-orchestrator-main". Then close my tab'
step5=$(sed -n '/^\*\*5\. /,/^\*\*6\. /p' "$ho/SKILL.md")
hasnt "step 5 does not rename the successor" "$step5" 'herdr agent prompt <new name>'
has "step 5 renames the outgoing session" "$step5" 'herdr agent prompt <old name> "/rename <project>-orchestrator-<n>"'
has "step 5 keeps the first orchestrator's rename" "$step5" 'renames itself `<project>-orchestrator-main`'
first=$(sed -n '/^## First steps/,$p' "$ho/references/handoff-template.md")
has "handoff template names the self-rename" "$first" "$self"
ok "first-message copies start with the command" "$(grep -c '^> /issue-loop:running-the-loop ' "$ho/SKILL.md")$(grep -c '^/issue-loop:running-the-loop ' "$here/../evals/06-takeover-with-standing-order/prompt.md")" 11
takeover=$(grep '^\*\*If you were started in the loop folder' "$skill/SKILL.md")
has "running-the-loop takeover names the title" "$takeover" '<project>-orchestrator-main'
hasnt "running-the-loop takeover holds no herdr command" "$takeover" 'herdr agent prompt'

# every skill is model-invocable, so a successor can load running-the-loop
hasnt "running-the-loop leaves model invocation on" "$(cat "$skill/SKILL.md")" 'disable-model-invocation'
ok "no skill turns off implicit invocation for Codex" "$(grep -rl allow_implicit_invocation "$here/../skills" 2>/dev/null)" ""
has "first message loads the skill with the Skill tool" "$tmpl" 'load it with the Skill tool'
hasnt "first message names no skill file" "$tmpl" '<skill file>'
}
