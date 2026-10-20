# test_rules: rules.sh builds the brief from the plugin's rules.md and the
# loop's rules.local.md: the answers, the whole-rule overrides, the missing
# report, the special characters, and a plugin edit that reaches the brief.
test_rules() {
  local tpl=$skill/assets/rules.md d=$T/rules tpl_text plus out miss
  mkdir -p "$d"
  . "$skill/assets/rules.sh"
  tpl_text=$(cat "$tpl")

  printf '%s\n' "The answers of this loop." "## 1.1" "it does what the issue asks" "" \
    "## 5.1" "run one test" "" "## 5.2" "run the full suite" "" "## 5.3" "run the lint" "" \
    "## 9.1" "ten minutes" "" "## 13.1" "every runtime" "" "## 14.1" "the live data is in one folder" >"$d/all.md"

  ok "template notes have no ## line" "$(grep -c '^## ' "$skill/assets/rules.local.md")" 0

  out=$(assemble_rules "$tpl" "$d/all.md")
  ok "every marker answered" "$(missing_answers "$tpl" "$d/all.md")" ""
  hasnt "every marker answered: no FILL left" "$out" "<FILL:"

  grep -v -e '^## 5.2$' -e '^run the full suite$' "$d/all.md" >"$d/no52.md"
  miss=$(missing_answers "$tpl" "$d/no52.md")
  has "missing 5.2 is named with its question" "$miss" "## 5.2   <FILL: the command that runs the full suite>"
  ok "only 5.2 is missing" "$(grep -c . <<<"$miss")" 1

  printf '%s\n' "## 1.1" "x" "## 5.1" "x" "## 5.2" "x" "## 5.3" "x" "## 9" "9. No deploy here." \
    "## 13" "" "## 14.1" "x" "## 20" "20. Last rule." >"$d/ov.md"
  out=$(assemble_rules "$tpl" "$d/ov.md")
  has "## 9 replaces rule 9" "$out" "9. No deploy here."
  hasnt "## 9 replaces rule 9: old text gone" "$out" "Merge and deploy without standing by"
  hasnt "empty ## 13 drops rule 13" "$out" "13. Every kind."
  ok "## 20 adds a rule last" "$(printf '%s\n' "$out" | grep -E '^[0-9]+\. ' | tail -n 1)" "20. Last rule."

  printf '%s\n' "## 1.1" 'a & b | c / d \ e {{BASE}}' >"$d/special.md"
  out=$(assemble_rules "$tpl" "$d/special.md")
  has "answer keeps & | / \\ and {{BASE}}" "$out" 'a & b | c / d \ e {{BASE}}'

  plus=${tpl_text/"It does not cover the rest of the product."/"It does not cover the rest of the product. A new plugin sentence."}
  ok "the copy of rules.md changed" "$([ "$plus" != "$tpl_text" ]; echo $?)" 0
  printf '%s\n' "$plus" >"$d/plus.md"
  out=$(assemble_rules "$d/plus.md" "$d/all.md")
  has "a plugin edit reaches the brief with no merge" "$out" "A new plugin sentence."
}
