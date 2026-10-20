#!/bin/bash
# Sourced by next.sh, upgrade.sh and the tests. Source it, do not run it.
# It builds the brief's rules: the plugin's rules.md plus the loop's own
# rules.local.md. Every global here starts with _rl_, so the script that
# sources it keeps its own names.
_rl_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# _rl_trim TEXT: TEXT without its blank lines at the top and the bottom, in _rl_t.
_rl_trim() {
  local t=$1 nl=$'\n'
  while [[ $t == "$nl"* ]]; do t=${t#"$nl"}; done
  while [[ $t == *"$nl" ]]; do t=${t%"$nl"}; done
  _rl_t=$t
}

# _rl_split FILE: the lines above rule 1 go to _rl_hdr, rule N to _rl_rule[N].
_rl_split() {
  local -a lines=()
  local line n=""
  mapfile -t lines <"$1" || return 1
  declare -gA _rl_rule=()
  _rl_hdr=""
  for line in "${lines[@]}"; do
    [[ $line =~ ^([0-9]+)\. ]] && n=$((10#${BASH_REMATCH[1]}))
    if [ -z "$n" ]; then _rl_hdr+="$line"$'\n'; else _rl_rule[$n]+="$line"$'\n'; fi
  done
  _rl_trim "$_rl_hdr"; _rl_hdr=$_rl_t
  for n in "${!_rl_rule[@]}"; do _rl_trim "${_rl_rule[$n]}"; _rl_rule[$n]=$_rl_t; done
}

# _rl_put SEC BODY: stores one section of rules.local.md. "N.K" goes to
# _rl_ans, "N" and "0" (the header) to _rl_whole. An empty SEC is a note.
_rl_put() {
  [ -z "$1" ] && return 0
  _rl_trim "$2"
  case $1 in
    *.*) _rl_ans[$1]=$_rl_t ;;
    *) _rl_whole[$1]=$_rl_t ;;
  esac
}

# _rl_local FILE: reads the sections of a rules.local.md. A missing file is empty.
_rl_local() {
  local -a lines=()
  local line sec="" body=""
  declare -gA _rl_ans=() _rl_whole=()
  if [ -f "$1" ]; then mapfile -t lines <"$1"; fi
  for line in "${lines[@]}"; do
    if [[ $line == "## "* ]]; then
      _rl_put "$sec" "$body"
      sec=${line#"## "}; body=""
      [[ $sec =~ ^[0-9]+(\.[0-9]+)?$ ]] || { echo "rules.local.md: '$line' is not a ## N, ## N.K or ## 0 line" >&2; return 1; }
    else
      body+="$line"$'\n'
    fi
  done
  _rl_put "$sec" "$body"
}

# _rl_build TEMPLATE LOCAL: sets _rl_hdr and _rl_rule with every FILL answered
# from LOCAL. _rl_missing gets one "## N.K   <FILL: ...>" line per FILL still open.
_rl_build() {
  local n k m rest out ans
  local re='(<FILL:[^>]*>)'
  _rl_split "$1" || return 1
  _rl_local "$2" || return 1
  if [ -n "${_rl_whole[0]+x}" ]; then _rl_hdr=${_rl_whole[0]}; fi
  for ((n = 1; n < 1000; n++)); do
    [ -n "${_rl_whole[$n]+x}" ] || continue
    if [ -z "${_rl_whole[$n]}" ]; then unset "_rl_rule[$n]"; else _rl_rule[$n]=${_rl_whole[$n]}; fi
  done
  _rl_missing=""
  for ((n = 1; n < 1000; n++)); do
    [ -n "${_rl_rule[$n]+x}" ] || continue
    rest=${_rl_rule[$n]} out="" k=0
    while [[ $rest =~ $re ]]; do
      m=${BASH_REMATCH[1]}; k=$((k + 1))
      out+=${rest%%"$m"*}
      ans=${_rl_ans[$n.$k]:-}
      if [ -n "$ans" ]; then out+=$ans; else out+=$m; _rl_missing+="## $n.$k   $m"$'\n'; fi
      rest=${rest#*"$m"}
    done
    _rl_rule[$n]=$out$rest
  done
}

# assemble_rules TEMPLATE LOCAL: the header, a blank line, then every rule in
# number order, one blank line apart. FILL markers stay in it when unanswered.
assemble_rules() {
  local n sep=""
  _rl_build "$1" "$2" || return 1
  printf '%s\n\n' "$_rl_hdr"
  for ((n = 1; n < 1000; n++)); do
    [ -n "${_rl_rule[$n]+x}" ] || continue
    printf '%s%s\n' "$sep" "${_rl_rule[$n]}"; sep=$'\n'
  done
}

# missing_answers TEMPLATE LOCAL: one line per FILL with no answer, nothing when all are answered.
missing_answers() {
  _rl_build "$1" "$2" || return 1
  printf '%s' "$_rl_missing"
}

# _rl_match N TEMPLATE OLD: the "## N.K" sections of the answers in OLD, when
# OLD is TEMPLATE with only its FILL markers changed. Else returns 1.
_rl_match() {
  local n=$1 i k=0 t o pre post rest m ans out=""
  local -a tl=() ol=()
  mapfile -t tl < <(printf '%s\n' "$2")
  mapfile -t ol < <(printf '%s\n' "$3")
  [ "${#tl[@]}" = "${#ol[@]}" ] || return 1
  for ((i = 0; i < ${#tl[@]}; i++)); do
    t=${tl[i]} o=${ol[i]}
    if [[ $t != *"<FILL:"* ]]; then [ "$t" = "$o" ] || return 1; continue; fi
    pre=${t%%"<FILL:"*}
    rest=${t#"$pre"}; m=${rest%%">"*}">"; post=${rest#"$m"}
    [[ $post != *"<FILL:"* ]] || return 1
    k=$((k + 1))
    [ "${#o}" -ge $((${#pre} + ${#post})) ] && [[ $o == "$pre"* && $o == *"$post" ]] || return 1
    ans=${o:${#pre}:${#o}-${#pre}-${#post}}
    [[ $ans == *"<FILL:"* ]] && continue
    out+="## $n.$k"$'\n'"$ans"$'\n\n'
  done
  [ -n "$out" ] || return 1
  printf '%s' "$out"
}

# extract_local TEMPLATE OLD: a rules.local.md for OLD, an old full rules.md:
# the notes of rules.local.md, then the header if it differs, then per rule the
# answers of its FILL markers, or the whole rule when it differs beyond them.
# Says on stderr what it kept whole or left out.
extract_local() {
  local -A tpl=() old=()
  local n line sec
  _rl_split "$1" || return 1
  local tpl_hdr=$_rl_hdr
  for n in "${!_rl_rule[@]}"; do tpl[$n]=${_rl_rule[$n]}; done
  _rl_split "$2" || return 1
  local old_hdr=$_rl_hdr
  for n in "${!_rl_rule[@]}"; do old[$n]=${_rl_rule[$n]}; done
  while IFS= read -r line; do
    [[ $line == "## "* ]] && break
    printf '%s\n' "$line"
  done <"$_rl_dir/rules.local.md"
  echo
  [ "$tpl_hdr" = "$old_hdr" ] || printf '## 0\n%s\n\n' "$old_hdr"
  for ((n = 1; n < 1000; n++)); do
    if [ -z "${tpl[$n]+x}" ] && [ -z "${old[$n]+x}" ]; then continue; fi
    if [ -z "${old[$n]+x}" ]; then
      printf '## %s\n\n' "$n"
      echo "rule $n: not in the old rules.md, left out (an empty ## $n)" >&2
    elif [ -z "${tpl[$n]+x}" ]; then
      printf '## %s\n%s\n\n' "$n" "${old[$n]}"
      echo "rule $n: not in the plugin's rules.md, kept whole as ## $n" >&2
    elif [ "${tpl[$n]}" != "${old[$n]}" ]; then
      if sec=$(_rl_match "$n" "${tpl[$n]}" "${old[$n]}"); then
        printf '%s\n\n' "$sec"
      else
        printf '## %s\n%s\n\n' "$n" "${old[$n]}"
        echo "rule $n: kept whole as ## $n (it differs from the plugin's rule beyond its FILL answers)" >&2
      fi
    fi
  done
}
