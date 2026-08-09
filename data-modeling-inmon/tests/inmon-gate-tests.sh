#!/usr/bin/env bash
# Allow/deny cases for data-modeling-inmon/hooks/inmon-gate.sh
set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../hooks" && pwd -P)"
GATE="$DIR/inmon-gate.sh"
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
  local desc="$1" want="$2" payload="$3"
  local out got
  out="$(mktemp)"
  CLAUDE_PROJECT_DIR="$TMPROOT" "$GATE" <<<"$payload" >"$out" 2>&1
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

write_case "token-absent proposal passthrough" "docs/issue-9/proposals/foo.md" "kimball star schema, nothing else here" 0
write_case "token-absent record passthrough" "docs/issue-9/reports/data-modeling.md" "kimball star schema, nothing else here" 0

GOOD_PROPOSAL='## Methodology Fit
inmon/3nf.

## Normalization Target
3nf.'
write_case "complete proposal with inmon token and target passes" "docs/issue-9/proposals/foo.md" "$GOOD_PROPOSAL" 0
write_case "proposal with inmon token but no target blocks" "docs/issue-9/proposals/foo.md" \
  "## Methodology Fit
inmon/3nf. No target mentioned here." 2
write_case "3nf mentioned only in an unrelated aside no longer satisfies normalization-target-named (semantic upgrade)" \
  "docs/issue-9/proposals/foo.md" \
  "## Methodology Fit
inmon/3nf.

## Aside
some other systems use 3nf but that's not our target here." 2

GOOD_RECORD='## Methodology
inmon 3nf.

## Normalization Deviations
customer table denormalized for read performance.'
write_case "complete record with deviations passes" "docs/issue-9/reports/data-modeling.md" "$GOOD_RECORD" 0
write_case "record with explicit no deviations passes" "docs/issue-9/reports/data-modeling.md" \
  "## Methodology
inmon 3nf.

## Normalization Deviations
no deviations from 3nf were made." 0
write_case "record missing deviations blocks" "docs/issue-9/reports/data-modeling.md" \
  "## Methodology
inmon 3nf. Nothing else stated." 2

write_case "unrelated path is untouched" "src/app.py" "anything inmon 3nf" 0

DATA_MODELING_INMON_GATE_OFF=1 write_case "kill switch (on-spelling) allows incomplete proposal" "docs/issue-9/proposals/foo.md" "inmon 3nf incomplete" 0
DATA_MODELING_INMON_GATE_OFF=maybe write_case "kill switch unrecognized value stays active" "docs/issue-9/proposals/foo.md" "inmon 3nf incomplete" 2

edit_case "Edit with replace_all against multiply-occurring old_string" \
  "docs/issue-9/proposals/foo.md" \
  "TOKEN TOKEN TOKEN
$GOOD_PROPOSAL" \
  "TOKEN" "REPLACED" true 0
multiedit_case "MultiEdit with mixed replace_all true/false edits" \
  "docs/issue-9/proposals/foo.md" \
  "QQQ QQQ QQQ
## Normalization Target
PPP
$GOOD_PROPOSAL" \
  '[{"old_string":"QQQ","new_string":"ZZZ","replace_all":true},{"old_string":"PPP","new_string":"3nf","replace_all":false}]' \
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
  echo "inmon-gate-tests: FAILED"
  exit 1
fi
echo "inmon-gate-tests: all passed"
