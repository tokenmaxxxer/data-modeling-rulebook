#!/usr/bin/env bash
# PreToolUse gate: Data Vault methodology content check for data-modeling.
# Contract (frozen, shared by data-modeling-{inmon,kimball,datavault} gates):
#   - reads the tool-call JSON from stdin (Claude Code PreToolUse hook payload)
#   - only acts on Write calls whose file_path matches this role's proposal or
#     record surface; any other path is a silent allow (exit 0)
#   - fail-closed: unparseable input on an in-scope path blocks (exit 2)
#   - kill switch: DATA_MODELING_DATAVAULT_GATE_OFF=1 skips the check (exit 0)
#   - only fires its methodology-specific check when the content names the
#     Data Vault token (case-insensitive "data vault"); otherwise exit 0
set -u

if [ "${DATA_MODELING_DATAVAULT_GATE_OFF:-}" = "1" ]; then
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
  echo "data-modeling-datavault gate: could not parse tool_input.file_path/content (fail-closed)" >&2
  exit 2
fi

lc="$(printf '%s' "$content" | tr '[:upper:]' '[:lower:]')"

echo "$lc" | grep -q 'data vault' || exit 0

missing=()

if [ "$is_proposal" = "1" ]; then
  echo "$lc" | grep -qE 'hub|satellite|link' || missing+=("hub-satellite-link (name at least one of hub/satellite/link)")
  echo "$lc" | grep -qE 'auditability|schema drift|audit trail' || missing+=("rationale (auditability, schema drift, or audit trail)")
elif [ "$is_record" = "1" ]; then
  echo "$lc" | grep -qE 'hub|satellite|link' || missing+=("hub-satellite-link (name at least one of hub/satellite/link)")
fi

if [ "${#missing[@]}" -gt 0 ]; then
  {
    echo "data-modeling-datavault gate: blocked write to $file_path — missing:"
    for m in "${missing[@]}"; do echo "  - $m"; done
  } >&2
  exit 2
fi

exit 0
