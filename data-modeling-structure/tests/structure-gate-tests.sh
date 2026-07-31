#!/usr/bin/env bash
# Allow/deny cases for data-modeling-structure/hooks/structure-gate.sh
set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../hooks" && pwd -P)"
GATE="$DIR/structure-gate.sh"
fail=0

run() {
  local desc="$1" path="$2" content="$3" want="$4"
  local payload
  payload="$(jq -n --arg fp "$path" --arg c "$content" '{tool_name:"Write", tool_input:{file_path:$fp, content:$c}}')"
  local got out
  out="$(mktemp)"
  echo "$payload" | "$GATE" >"$out" 2>&1
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

GOOD_PROPOSAL='Backed by docs/issue-9/reports/data-modeling/survey.md. Layers: conceptual, logical, physical. Alternatives considered: X vs Y. Open questions: none. Methodology fit: kimball, star schema.'
run "complete proposal passes" "docs/issue-9/proposals/foo.md" "$GOOD_PROPOSAL" 0
run "proposal missing survey ref blocks" "docs/issue-9/proposals/foo.md" "Layers: conceptual logical physical. Alternatives considered. Open questions. kimball" 2
run "proposal missing methodology-fit blocks" "docs/issue-9/proposals/foo.md" "docs/issue-9/reports/data-modeling/survey Layers: conceptual logical physical. Alternatives considered. Open questions." 2
run "no-fit statement satisfies methodology-fit" "docs/issue-9/proposals/foo.md" "docs/issue-9/reports/data-modeling/survey Layers: conceptual logical physical. Alternatives considered. Open questions. no schema decision" 0

GOOD_RECORD='Layers: conceptual, logical, physical. Data dictionary is a separate section from the ERD. Migration plan includes a rollback path.'
run "complete record passes" "docs/issue-9/reports/data-modeling.md" "$GOOD_RECORD" 0
run "record missing data dictionary blocks" "docs/issue-9/reports/data-modeling.md" "Layers: conceptual logical physical. Migration plan and rollback." 2
run "record with pipeline mention but no hand-off blocks" "docs/issue-9/reports/data-modeling.md" "$GOOD_RECORD pipeline movement is also handled here" 2
run "record with pipeline mention and hand-off passes" "docs/issue-9/reports/data-modeling.md" "$GOOD_RECORD pipeline movement: hand-off to data-engineering" 0

run "unrelated path is untouched" "src/app.py" "anything" 0

DATA_MODELING_STRUCTURE_GATE_OFF=1 run "kill switch allows incomplete proposal" "docs/issue-9/proposals/foo.md" "incomplete" 0

if [ "$fail" = "1" ]; then
  echo "structure-gate-tests: FAILED"
  exit 1
fi
echo "structure-gate-tests: all passed"
