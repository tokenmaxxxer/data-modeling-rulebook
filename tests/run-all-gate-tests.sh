#!/usr/bin/env bash
# Aggregator: runs every data-modeling-* plugin's own gate test suite, plus
# core's gate-house compliance detector against each plugin's hooks/ dir
# (issue-72 canon, reference-only — resolved the same way the gate scripts
# themselves resolve gate-lib.sh, via tests/resolve-core.sh).
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
. "$ROOT/tests/resolve-core.sh"
fail=0

if [ -n "${TEST_ENV_SKIP:-}" ]; then
  echo "SKIP: core plugin unreachable — unverifiable outside spawn env (see docs/specs/test-env-resolution.md)" >&2
  exit 75
fi

if [ -n "${CLAUDE_PLUGIN_ROOT_CORE:-}" ] && [ -f "$CLAUDE_PLUGIN_ROOT_CORE/hooks/tests/compliance-check.sh" ]; then
  for plugin in data-modeling-structure data-modeling-inmon data-modeling-kimball data-modeling-datavault; do
    echo "== compliance-check: $plugin =="
    if ! bash "$CLAUDE_PLUGIN_ROOT_CORE/hooks/tests/compliance-check.sh" "$ROOT/$plugin"; then
      fail=1
    fi
  done
else
  echo "run-all-gate-tests: FAILED — CLAUDE_PLUGIN_ROOT_CORE unresolved, cannot run compliance-check.sh (core canon unavailable); export a pre-resolved CLAUDE_PLUGIN_ROOT_CORE or allow tests/resolve-core.sh's network clone" >&2
  fail=1
fi

for suite in \
  data-modeling-structure/tests/structure-gate-tests.sh \
  data-modeling-inmon/tests/inmon-gate-tests.sh \
  data-modeling-kimball/tests/kimball-gate-tests.sh \
  data-modeling-datavault/tests/datavault-gate-tests.sh
do
  echo "== $suite =="
  if ! bash "$ROOT/$suite"; then
    fail=1
  fi
done

if [ "$fail" = "1" ]; then
  echo "run-all-gate-tests: FAILED"
  exit 1
fi
echo "run-all-gate-tests: all suites passed"
