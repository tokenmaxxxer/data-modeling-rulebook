#!/usr/bin/env bash
# Allow/deny cases for data-modeling-datavault/hooks/datavault-gate.sh
set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../hooks" && pwd -P)"
GATE="$DIR/datavault-gate.sh"
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

run "token-absent proposal passes through" "docs/issue-9/proposals/foo.md" "no methodology token here at all" 0
run "token-absent record passes through" "docs/issue-9/reports/data-modeling.md" "nothing relevant here" 0

GOOD_PROPOSAL='We chose Data Vault. Hub, satellite, and link tables are defined. This gives us strong auditability and resilience to schema drift.'
run "complete proposal passes" "docs/issue-9/proposals/foo.md" "$GOOD_PROPOSAL" 0
run "proposal missing hub/satellite/link blocks" "docs/issue-9/proposals/foo.md" "We chose Data Vault for its auditability." 2
run "proposal missing rationale blocks" "docs/issue-9/proposals/foo.md" "We chose Data Vault. Hub, satellite, and link tables are defined." 2

GOOD_RECORD='Data Vault model implemented with hub, satellite, and link tables.'
run "complete record passes" "docs/issue-9/reports/data-modeling.md" "$GOOD_RECORD" 0
run "record missing hub/satellite/link blocks" "docs/issue-9/reports/data-modeling.md" "Data Vault model implemented." 2

run "unrelated path is untouched" "src/app.py" "data vault hub satellite link" 0

DATA_MODELING_DATAVAULT_GATE_OFF=1 run "kill switch allows incomplete proposal" "docs/issue-9/proposals/foo.md" "Data Vault chosen" 0

if [ "$fail" = "1" ]; then
  echo "datavault-gate-tests: FAILED"
  exit 1
fi
echo "datavault-gate-tests: all passed"
