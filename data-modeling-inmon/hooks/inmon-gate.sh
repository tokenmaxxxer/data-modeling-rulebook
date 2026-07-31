#!/usr/bin/env bash
# PreToolUse gate: Inmon/3NF methodology-specific content for data-modeling.
# Contract (frozen, shared by data-modeling-{inmon,kimball,datavault} gates):
#   - reads the tool-call JSON from stdin (Claude Code PreToolUse hook payload)
#   - only acts on Write calls whose file_path matches this role's proposal or
#     record surface; any other path is a silent allow (exit 0)
#   - fail-closed: unparseable input on an in-scope path blocks (exit 2)
#   - kill switch: DATA_MODELING_INMON_GATE_OFF=1 skips the check (exit 0)
#   - only fires its methodology-specific check when the content actually
#     names the Inmon/3NF token (inmon or 3nf, case-insensitive); if that
#     token is absent, this methodology wasn't the one picked, so exit 0
#     immediately (data-modeling-structure already required some
#     methodology-fit token to be present)
set -u

if [ "${DATA_MODELING_INMON_GATE_OFF:-}" = "1" ]; then
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
  echo "data-modeling-inmon gate: could not parse tool_input.file_path/content (fail-closed)" >&2
  exit 2
fi

lc="$(printf '%s' "$content" | tr '[:upper:]' '[:lower:]')"

echo "$lc" | grep -qE 'inmon|3nf' || exit 0

missing=()

if [ "$is_proposal" = "1" ]; then
  # Intended normalization target form: require a 1NF/2NF/3NF/BCNF token
  # near "target" or "form" language.
  echo "$lc" | grep -qE 'target[^.]*\b(1nf|2nf|3nf|bcnf)\b|\b(1nf|2nf|3nf|bcnf)\b[^.]*form' \
    || missing+=("normalization-target-named (intended normalization form: target ... 1nf/2nf/3nf/bcnf, or 1nf/2nf/3nf/bcnf ... form)")
elif [ "$is_record" = "1" ]; then
  echo "$lc" | grep -q 'deviation' \
    || missing+=("normalization-deviations-stated (state normalization deviations, or explicitly state \"no deviations\")")
fi

if [ "${#missing[@]}" -gt 0 ]; then
  {
    echo "data-modeling-inmon gate: blocked write to $file_path — missing:"
    for m in "${missing[@]}"; do echo "  - $m"; done
  } >&2
  exit 2
fi

exit 0
