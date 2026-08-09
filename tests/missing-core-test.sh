#!/usr/bin/env bash
# Dedicated test for run-all-gate-tests.sh's missing-core path (issue-13
# §4): a run where compliance-check.sh never executed must fail, not print
# "all suites passed". Not part of the default run-all-gate-tests.sh run —
# invoked separately so the missing-core fail-path is exercised on its own,
# not as the default (real-core) run path.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

# Force genuine non-resolution, not just an env-var override: the
# canonical resolver (tests/env_resolve.py) re-validates
# CLAUDE_PLUGIN_ROOT_CORE and falls back to sibling/cache candidates and a
# best-effort network clone, so a bogus env var alone would not reproduce
# "unresolved" on a machine that happens to have a sibling checkout, a
# stale cache, or network access. A fresh empty TMPDIR neutralizes the
# cache candidate; a stub `git` on PATH that always fails neutralizes the
# network-clone extension.
work="$(mktemp -d)"
mkdir -p "$work/bin" "$work/tmp"
printf '#!/bin/sh\nexit 1\n' >"$work/bin/git"
chmod +x "$work/bin/git"

out="$(mktemp)"
env -i PATH="$work/bin:/usr/bin:/bin" TMPDIR="$work/tmp" HOME="${HOME:-}" \
  CLAUDE_PLUGIN_ROOT_CORE="/nonexistent/stub-core-$$" \
  bash "$ROOT/tests/run-all-gate-tests.sh" >"$out" 2>&1
got=$?
rm -rf "$work"

if [ "$got" = "0" ]; then
  echo "FAIL: run-all-gate-tests.sh exited 0 with an unresolved CLAUDE_PLUGIN_ROOT_CORE (missing-core is a failure, not a silent pass)"
  cat "$out"
  rm -f "$out"
  exit 1
fi

if [ "$got" != "75" ]; then
  echo "FAIL: run-all-gate-tests.sh exited $got, expected the SKIP contract's exit 75 (docs/specs/test-env-resolution.md) when CLAUDE_PLUGIN_ROOT_CORE is unresolved"
  cat "$out"
  rm -f "$out"
  exit 1
fi

echo "ok: run-all-gate-tests.sh exits 75 (SKIP contract) when CLAUDE_PLUGIN_ROOT_CORE is unresolved"
rm -f "$out"
