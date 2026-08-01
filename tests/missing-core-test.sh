#!/usr/bin/env bash
# Dedicated test for run-all-gate-tests.sh's missing-core path (issue-13
# §4): a run where compliance-check.sh never executed must fail, not print
# "all suites passed". Not part of the default run-all-gate-tests.sh run —
# invoked separately so the missing-core fail-path is exercised on its own,
# not as the default (real-core) run path.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

out="$(mktemp)"
CLAUDE_PLUGIN_ROOT_CORE="/nonexistent/stub-core-$$" bash "$ROOT/tests/run-all-gate-tests.sh" >"$out" 2>&1
got=$?

if [ "$got" = "0" ]; then
  echo "FAIL: run-all-gate-tests.sh exited 0 with an unresolved CLAUDE_PLUGIN_ROOT_CORE (missing-core is a failure, not a silent pass)"
  cat "$out"
  rm -f "$out"
  exit 1
fi

echo "ok: run-all-gate-tests.sh fails (exit $got) when CLAUDE_PLUGIN_ROOT_CORE is unresolved"
rm -f "$out"
