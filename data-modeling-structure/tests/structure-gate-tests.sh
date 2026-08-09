#!/usr/bin/env bash
# Allow/deny cases for data-modeling-structure/hooks/structure-gate.sh
set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../hooks" && pwd -P)"
GATE="$DIR/structure-gate.sh"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)/tests/resolve-core.sh"
if [ -n "${TEST_ENV_SKIP:-}" ]; then
  echo "SKIP: core plugin unreachable — unverifiable outside spawn env (see docs/specs/test-env-resolution.md)" >&2
  exit 75
fi
fail=0

TMPROOT="$(mktemp -d)"
cleanup() { rm -rf "$TMPROOT"; }
trap cleanup EXIT

run_raw() {
  local desc="$1" want="$2" payload="$3" env_extra="${4:-}"
  local out got
  out="$(mktemp)"
  if [ -n "$env_extra" ]; then
    env "$env_extra" CLAUDE_PROJECT_DIR="$TMPROOT" "$GATE" <<<"$payload" >"$out" 2>&1
  else
    CLAUDE_PROJECT_DIR="$TMPROOT" "$GATE" <<<"$payload" >"$out" 2>&1
  fi
  got=$?
  if [ "$got" != "$want" ]; then
    echo "FAIL: $desc (want exit $want, got $got)"
    cat "$out"
    fail=1
  else
    echo "ok: $desc"
  fi
  rm -f "$out"
}

write_case() {
  local desc="$1" path="$2" content="$3" want="$4"
  local payload
  payload="$(jq -n --arg fp "$path" --arg c "$content" '{tool_name:"Write", tool_input:{file_path:$fp, content:$c}}')"
  run_raw "$desc" "$want" "$payload"
}

edit_case() {
  local desc="$1" path="$2" current="$3" old="$4" new="$5" ra="$6" want="$7"
  mkdir -p "$TMPROOT/$(dirname "$path")"
  printf '%s' "$current" >"$TMPROOT/$path"
  local payload
  payload="$(jq -n --arg fp "$path" --arg o "$old" --arg n "$new" --argjson ra "$ra" \
    '{tool_name:"Edit", tool_input:{file_path:$fp, old_string:$o, new_string:$n, replace_all:$ra}}')"
  run_raw "$desc" "$want" "$payload"
}

multiedit_case() {
  local desc="$1" path="$2" current="$3" edits_json="$4" want="$5"
  mkdir -p "$TMPROOT/$(dirname "$path")"
  printf '%s' "$current" >"$TMPROOT/$path"
  local payload
  payload="$(jq -n --arg fp "$path" --argjson edits "$edits_json" \
    '{tool_name:"MultiEdit", tool_input:{file_path:$fp, edits:$edits}}')"
  run_raw "$desc" "$want" "$payload"
}

GOOD_PROPOSAL='Backed by docs/issue-9/reports/data-modeling/survey.md.

## Layers
conceptual, logical, physical.

## Alternatives Considered
X vs Y.

## Open Questions
None.

## Methodology Fit
kimball, star schema.'

write_case "complete proposal passes" "docs/issue-9/proposals/foo.md" "$GOOD_PROPOSAL" 0
write_case "proposal missing survey ref blocks" "docs/issue-9/proposals/foo.md" \
  "## Layers
conceptual logical physical.
## Alternatives Considered
x
## Open Questions
none
## Methodology Fit
kimball" 2
write_case "proposal missing methodology-fit blocks" "docs/issue-9/proposals/foo.md" \
  "docs/issue-9/reports/data-modeling/survey
## Layers
conceptual logical physical.
## Alternatives Considered
x
## Open Questions
none" 2
write_case "no-fit statement satisfies methodology-fit" "docs/issue-9/proposals/foo.md" \
  "docs/issue-9/reports/data-modeling/survey
## Layers
conceptual logical physical.
## Alternatives Considered
x
## Open Questions
none
## Methodology Fit
no schema decision" 0
write_case "bare mention of inmon outside fit section no longer satisfies methodology-fit (semantic upgrade)" \
  "docs/issue-9/proposals/foo.md" \
  "docs/issue-9/reports/data-modeling/survey
## Layers
conceptual logical physical.
## Alternatives Considered
we are not using inmon here, considered X vs Y instead.
## Open Questions
none" 2

GOOD_RECORD='## Layers
conceptual, logical, physical.

## Data Dictionary
separate section from the ERD.

## Migration Plan
steps here.

## Rollback
rollback path.

table_name: orders_fact
table_type: fact
grain: one row per order line
verdict: pass'

write_case "complete record passes" "docs/issue-9/reports/data-modeling.md" "$GOOD_RECORD" 0
write_case "record missing data dictionary blocks" "docs/issue-9/reports/data-modeling.md" \
  "## Layers
conceptual logical physical.
## Migration Plan
plan
## Rollback
rollback" 2
write_case "record with pipeline mention but no nearby hand-off blocks" "docs/issue-9/reports/data-modeling.md" \
  "$GOOD_RECORD

pipeline movement is also handled here, unrelated section far below.

## Hand-off note
a hand-off occurs in this project sometimes.
line 2
line 3
line 4
line 5
line 6

## Unrelated later section
data-engineering is a different team entirely, mentioned here only." 2
write_case "record with pipeline mention and nearby hand-off passes" "docs/issue-9/reports/data-modeling.md" \
  "$GOOD_RECORD

## Hand-off
pipeline movement: hand-off to data-engineering" 0
write_case "hand-off and data-engineering in separate unrelated sections no longer satisfies decides-boundary (semantic upgrade)" \
  "docs/issue-9/reports/data-modeling.md" \
  "$GOOD_RECORD

## Pipeline note
some pipeline etl movement happens, and there is a hand-off mentioned here.

line 2
line 3
line 4
line 5
line 6
line 7

## Unrelated org note
data-engineering is a different team entirely, mentioned only here." 2

write_case "record missing table_name blocks" "docs/issue-9/reports/data-modeling.md" \
  "$(printf '%s' "$GOOD_RECORD" | grep -v '^table_name:')" 2
write_case "record missing table_type blocks" "docs/issue-9/reports/data-modeling.md" \
  "$(printf '%s' "$GOOD_RECORD" | grep -v '^table_type:')" 2
write_case "record missing grain blocks" "docs/issue-9/reports/data-modeling.md" \
  "$(printf '%s' "$GOOD_RECORD" | grep -v '^grain:')" 2
write_case "record missing verdict blocks" "docs/issue-9/reports/data-modeling.md" \
  "$(printf '%s' "$GOOD_RECORD" | grep -v '^verdict:')" 2
write_case "record with out-of-enum table_type blocks" "docs/issue-9/reports/data-modeling.md" \
  "$(printf '%s' "$GOOD_RECORD" | sed 's/^table_type: fact/table_type: bridge/')" 2
write_case "record with out-of-enum verdict blocks" "docs/issue-9/reports/data-modeling.md" \
  "$(printf '%s' "$GOOD_RECORD" | sed 's/^verdict: pass/verdict: maybe/')" 2
write_case "Data Vault record with table_type: n/a passes (no fact/dimension distinction)" \
  "docs/issue-9/reports/data-modeling.md" \
  "$(printf '%s' "$GOOD_RECORD" | sed 's/^table_type: fact/table_type: n\/a/')" 0

write_case "unrelated path is untouched" "src/app.py" "anything" 0

DATA_MODELING_STRUCTURE_GATE_OFF=1 write_case "kill switch (on-spelling) allows incomplete proposal" "docs/issue-9/proposals/foo.md" "incomplete" 0
DATA_MODELING_STRUCTURE_GATE_OFF=maybe write_case "kill switch unrecognized value stays active (denies same as unset)" "docs/issue-9/proposals/foo.md" "incomplete" 2

edit_case "Edit with replace_all against multiply-occurring old_string" \
  "docs/issue-9/proposals/foo.md" \
  "TOKEN TOKEN TOKEN
$GOOD_PROPOSAL" \
  "TOKEN" "REPLACED" true 0
multiedit_case "MultiEdit with mixed replace_all true/false edits" \
  "docs/issue-9/proposals/foo.md" \
  "QQQ QQQ QQQ
## Layers
PPP
$GOOD_PROPOSAL" \
  '[{"old_string":"QQQ","new_string":"ZZZ","replace_all":true},{"old_string":"PPP","new_string":"conceptual","replace_all":false}]' \
  0

run_raw "malformed JSON (truncated) fails closed" 2 '{"tool_name":"Write","tool_input":{'
run_raw "malformed JSON (non-object top level) fails closed" 2 '"just a string"'
run_raw "malformed JSON (empty payload) fails closed" 2 ''

abs_path="$TMPROOT/docs/issue-9/proposals/abs.md"
mkdir -p "$(dirname "$abs_path")"
write_case "absolute file_path matches the same scope a relative fixture matches" "$abs_path" "$GOOD_PROPOSAL" 0
write_case "./-prefixed file_path matches the same scope" "./docs/issue-9/proposals/foo.md" "$GOOD_PROPOSAL" 0

bash_payload="$(jq -n --arg cmd 'echo bad >> docs/issue-9/proposals/foo.md' '{tool_name:"Bash", tool_input:{command:$cmd}}')"
run_raw "Bash write reaching an in-scope path is denied (content-blind)" 2 "$bash_payload"

bash_oos_payload="$(jq -n --arg cmd 'echo ok >> src/app.py' '{tool_name:"Bash", tool_input:{command:$cmd}}')"
run_raw "Bash write to an out-of-scope path still passes through" 0 "$bash_oos_payload"

if [ -n "${CLAUDE_PLUGIN_ROOT_CORE:-}" ] && [ -f "$CLAUDE_PLUGIN_ROOT_CORE/hooks/tests/compliance-check.sh" ]; then
  if bash "$CLAUDE_PLUGIN_ROOT_CORE/hooks/tests/compliance-check.sh" "$DIR/.."; then
    echo "ok: compliance-check.sh clean against this plugin"
  else
    echo "FAIL: compliance-check.sh reported violations"
    fail=1
  fi
else
  echo "FAIL: CLAUDE_PLUGIN_ROOT_CORE unresolved — cannot run compliance-check.sh"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "structure-gate-tests: FAILED"
  exit 1
fi
echo "structure-gate-tests: all passed"
