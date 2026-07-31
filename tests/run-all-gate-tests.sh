#!/usr/bin/env bash
# Aggregator: runs every data-modeling-* plugin's own gate test suite.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
fail=0

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
