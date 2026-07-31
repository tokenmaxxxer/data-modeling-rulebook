#!/usr/bin/env bash
# PreToolUse gate: Kimball dimensional-modeling / star-schema content check.
# Contract (shared shape with data-modeling-structure and sibling gates):
#   - reads the tool-call JSON from stdin (Claude Code PreToolUse hook payload)
#   - only acts on Write calls whose file_path matches this role's proposal or
#     record surface; any other path is a silent allow (exit 0)
#   - only fires its methodology-specific check when the content actually
#     names the Kimball token (kimball, dimensional model, star schema);
#     otherwise it is a silent allow (exit 0)
#   - fail-closed: unparseable input on an in-scope path blocks (exit 2)
#   - kill switch: DATA_MODELING_KIMBALL_GATE_OFF=1 skips the check (exit 0)
set -u

if [ "${DATA_MODELING_KIMBALL_GATE_OFF:-}" = "1" ]; then
  exit 0
fi

input="$(cat)"

file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"

is_proposal=0
is_record=0
case "$file_path" in
  docs/issue-*/proposals/*.md) is_proposal=1 ;;
  docs/issue-*/reports/data-modeling.md) is_record=1 ;;
  *) exit 0 ;;
esac

content="$(printf '%s' "$input" | jq -r '.tool_input.content // empty' 2>/dev/null)"
if [ -z "$file_path" ] || [ "$content" = "null" ]; then
  echo "data-modeling-kimball gate: could not parse tool_input.file_path/content (fail-closed)" >&2
  exit 2
fi

if ! echo "$content" | grep -qiE 'kimball|dimensional model|star schema'; then
  exit 0
fi

missing=()

if [ "$is_proposal" = "1" ]; then
  echo "$content" | grep -qiE 'grain:|grain is' || missing+=("grain-statement (must state the fact table grain, e.g. 'grain:' or 'grain is')")
elif [ "$is_record" = "1" ]; then
  echo "$content" | grep -qiE 'fact table' || missing+=("fact-table (must name the fact table)")
  echo "$content" | grep -qiE 'dimension table' || missing+=("dimension-table (must name the dimension table)")
fi

if [ "${#missing[@]}" -gt 0 ]; then
  {
    echo "data-modeling-kimball gate: blocked write to $file_path — missing:"
    for m in "${missing[@]}"; do echo "  - $m"; done
  } >&2
  exit 2
fi

exit 0
