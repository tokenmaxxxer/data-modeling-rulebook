#!/usr/bin/env bash
# PreToolUse gate: methodology-agnostic proposal/record shape for data-modeling.
# Contract (frozen, shared by data-modeling-{inmon,kimball,datavault} gates):
#   - reads the tool-call JSON from stdin (Claude Code PreToolUse hook payload)
#   - only acts on Write calls whose file_path matches this role's proposal or
#     record surface; any other path is a silent allow (exit 0)
#   - fail-closed: unparseable input on an in-scope path blocks (exit 2)
#   - kill switch: DATA_MODELING_STRUCTURE_GATE_OFF=1 skips the check (exit 0)
set -u

if [ "${DATA_MODELING_STRUCTURE_GATE_OFF:-}" = "1" ]; then
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
  echo "data-modeling-structure gate: could not parse tool_input.file_path/content (fail-closed)" >&2
  exit 2
fi

lc="$(printf '%s' "$content" | tr '[:upper:]' '[:lower:]')"
missing=()

if [ "$is_proposal" = "1" ]; then
  echo "$lc" | grep -q 'reports/data-modeling/survey' || missing+=("survey-referenced (must cite docs/issue-<n>/reports/data-modeling/survey)")
  echo "$lc" | grep -qE 'conceptual|logical|physical' || missing+=("layers-named (at least one of conceptual/logical/physical)")
  echo "$lc" | grep -q 'alternative' || missing+=("alternatives-considered")
  echo "$lc" | grep -q 'open question' || missing+=("open-questions")
  echo "$lc" | grep -qE 'inmon|3nf|kimball|dimensional model|star schema|data vault|no schema decision|routed to' || missing+=("methodology-fit-named (inmon/3nf, kimball/dimensional model/star schema, data vault, or an explicit no-fit statement)")
elif [ "$is_record" = "1" ]; then
  if echo "$lc" | grep -qE 'conceptual' && echo "$lc" | grep -qE 'logical' && echo "$lc" | grep -qE 'physical'; then
    : # all three layers named
  else
    echo "$lc" | grep -qE 'skip|not applicable|n/a' || missing+=("layers-or-justified-skip (name conceptual/logical/physical, or justify skipping one)")
  fi
  echo "$lc" | grep -q 'data dictionary' || missing+=("data-dictionary (named as a section distinct from ERD)")
  echo "$lc" | grep -q 'migration plan' || missing+=("migration-rollback: migration plan")
  echo "$lc" | grep -q 'rollback' || missing+=("migration-rollback: rollback")
  if echo "$lc" | grep -qE 'pipeline|\betl\b'; then
    echo "$lc" | grep -q 'hand-off' && echo "$lc" | grep -q 'data-engineering' || missing+=("decides-boundary: pipeline/ETL movement mentioned without a hand-off note to data-engineering")
  fi
fi

if [ "${#missing[@]}" -gt 0 ]; then
  {
    echo "data-modeling-structure gate: blocked write to $file_path — missing:"
    for m in "${missing[@]}"; do echo "  - $m"; done
  } >&2
  exit 2
fi

exit 0
