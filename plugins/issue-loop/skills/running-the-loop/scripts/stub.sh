#!/bin/bash
# The stub: one copy in each loop folder, under the name of the script it runs
# (lib.sh too, for the orchestrator's ". ./lib.sh"). It runs the plugin's script
# of that name from the installed issue-loop (or the version loop.env pins), with
# this folder as the loop's state. Run, it replaces itself with that script;
# sourced, it loads that script. next.sh resolves the plugin once per task and
# writes its folder to task.plugin; the other stubs use that folder, so a plugin
# update in the middle of a task changes no script under it.
# Written by init.sh and upgrade.sh. Never edit it by hand.
_il_stub() {
  local _il_self=${BASH_SOURCE[0]} _il_dir="" _il_name="" _il_v="" _il_root="" _il_reg="" _il_f="" _il_p=""
  _il_dir=$(cd "$(dirname "$_il_self")" && pwd -P)
  _il_name=$(basename "$_il_self")
  _il_v=$(. "$_il_dir/loop.env"; echo "${ISSUE_LOOP_VERSION:-latest}")
  [ "$_il_name" != next.sh ] && [ -s "$_il_dir/task.plugin" ] && _il_root=$(head -1 "$_il_dir/task.plugin" || true)
  if [ -z "$_il_root" ]; then
    _il_reg="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/installed_plugins.json"
    # several entries (other scopes, other marketplaces): the newest version wins
    _il_root=$(jq -r '.plugins | to_entries[] | select(.key | startswith("issue-loop@")) | .value[].installPath' "$_il_reg" 2>/dev/null | while read -r _il_p; do printf '%s\t%s\n' "$(basename "$_il_p")" "$_il_p"; done | sort -V | tail -1 | cut -f2 || true)
    if [ -z "$_il_root" ]; then
      echo "issue-loop: no installed issue-loop plugin in $_il_reg" >&2
      return 3
    fi
    [ "$_il_v" = latest ] || _il_root="$(dirname "$_il_root")/$_il_v"
  fi
  _il_f="$_il_root/skills/running-the-loop/assets/$_il_name"
  if [ ! -f "$_il_f" ]; then
    echo "issue-loop: no $_il_name in $_il_root (ISSUE_LOOP_VERSION=$_il_v in $_il_dir/loop.env; versions there: $(ls "$(dirname "$_il_root")" | tr '\n' ' '))" >&2
    return 3
  fi
  # a folder from before 0.9.0 has no rules.sh: its lib.sh would take the cache for the loop folder
  if [ ! -f "$_il_root/skills/running-the-loop/assets/rules.sh" ]; then
    echo "issue-loop: $_il_root is from before 0.9.0 and cannot run a loop folder of stubs: pin 0.9.0 or later" >&2
    return 3
  fi
  export ISSUE_LOOP_DIR=$_il_dir ISSUE_LOOP_ROOT=$_il_root
  if [ "${BASH_SOURCE[0]}" = "$0" ]; then exec bash "$_il_f" "$@"; fi
  . "$_il_f"
}
_il_stub "$@"
