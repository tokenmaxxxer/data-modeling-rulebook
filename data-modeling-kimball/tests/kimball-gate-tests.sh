#!/usr/bin/env bash
# Allow/deny cases for data-modeling-kimball/hooks/kimball-gate.sh
set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../hooks" && pwd -P)"
GATE="$DIR/kimball-gate.sh"
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

run "token-absent proposal passthrough" "docs/issue-9/proposals/foo.md" "nothing relevant here" 0

GOOD_PROPOSAL='Methodology: kimball. Grain: one row per order line item.'
run "complete proposal with grain passes" "docs/issue-9/proposals/foo.md" "$GOOD_PROPOSAL" 0
run "proposal with kimball token but no grain blocks" "docs/issue-9/proposals/foo.md" "We will use a star schema for this." 2

GOOD_RECORD='Fact table: fct_orders. Dimension table: dim_customer.'
run "complete record with fact/dimension split passes" "docs/issue-9/reports/data-modeling.md" "$GOOD_RECORD" 0
run "record missing the split blocks" "docs/issue-9/reports/data-modeling.md" "Using a dimensional model here." 2

run "unrelated path is untouched" "src/app.py" "kimball star schema" 0

DATA_MODELING_KIMBALL_GATE_OFF=1 run "kill switch allows everything" "docs/issue-9/proposals/foo.md" "star schema, no grain" 0

if [ "$fail" = "1" ]; then
  echo "kimball-gate-tests: FAILED"
  exit 1
fi
echo "kimball-gate-tests: all passed"
