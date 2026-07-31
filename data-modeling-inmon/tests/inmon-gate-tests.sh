#!/usr/bin/env bash
# Allow/deny cases for data-modeling-inmon/hooks/inmon-gate.sh
set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../hooks" && pwd -P)"
GATE="$DIR/inmon-gate.sh"
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

run "token-absent proposal passthrough" "docs/issue-9/proposals/foo.md" "kimball star schema, nothing else here" 0
run "token-absent record passthrough" "docs/issue-9/reports/data-modeling.md" "kimball star schema, nothing else here" 0

GOOD_PROPOSAL='Methodology fit: inmon/3nf. Target normalization form: 3nf.'
run "complete proposal with inmon token and target passes" "docs/issue-9/proposals/foo.md" "$GOOD_PROPOSAL" 0
run "proposal with inmon token but no target blocks" "docs/issue-9/proposals/foo.md" "Methodology fit: inmon/3nf. No target mentioned here." 2

GOOD_RECORD='Methodology: inmon 3nf. Normalization deviations: customer table denormalized for read performance.'
run "complete record with deviations passes" "docs/issue-9/reports/data-modeling.md" "$GOOD_RECORD" 0
run "record with explicit no deviations passes" "docs/issue-9/reports/data-modeling.md" "Methodology: inmon 3nf. No deviations from 3nf were made." 0
run "record missing deviations blocks" "docs/issue-9/reports/data-modeling.md" "Methodology: inmon 3nf. Nothing else stated." 2

run "unrelated path is untouched" "src/app.py" "anything inmon 3nf" 0

DATA_MODELING_INMON_GATE_OFF=1 run "kill switch allows incomplete proposal" "docs/issue-9/proposals/foo.md" "inmon 3nf incomplete" 0

if [ "$fail" = "1" ]; then
  echo "inmon-gate-tests: FAILED"
  exit 1
fi
echo "inmon-gate-tests: all passed"
