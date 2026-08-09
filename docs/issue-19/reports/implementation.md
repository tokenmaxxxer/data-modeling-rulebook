---
code_under_review:
  - tests/env_resolve.py
  - tests/resolve-core.sh
  - tests/run-all-gate-tests.sh
  - tests/missing-core-test.sh
  - data-modeling-structure/tests/structure-gate-tests.sh
  - data-modeling-inmon/tests/inmon-gate-tests.sh
  - data-modeling-kimball/tests/kimball-gate-tests.sh
  - data-modeling-datavault/tests/datavault-gate-tests.sh
type: chore
breaking: false
verdict: PENDING
loop_state: landed
---

## Phase 2 continuation (2026-08-09)
A live check running every script under `tests/`, `*/tests/`,
`*/hooks/tests/` with `CLAUDE_PLUGIN_ROOT_CORE` unset found the four
per-plugin gate-test suites and `tests/run-all-gate-tests.sh` failing
non-SKIP: `AttributeError("module 'gate_lib' has no attribute
'gate_bash_write_targets'")`, surfaced as `FAIL: Bash write to an
out-of-scope path still passes through`.

Root cause was NOT a convention gap in any test script — all eight
already implement the SKIP contract correctly. It was a real defect in
`tests/resolve-core.sh`'s repo-local network-cache fallback: once
`${TMPDIR:-/tmp}/tokenmaxxxer-core-canon-cache` exists, the script never
refreshed it, so a cache cloned before core's `gate_bash_write_targets`
was added (core issue-75, landed after core issue-72's
2026-08-01 gate-lib canonization) kept resolving as "reachable" forever,
turning a real upstream addition into a misleading FAIL instead of the
convention's SKIP-or-pass-through. This directly violates issue #19's
"zero misleading failures" acceptance criterion, so it is fixed here
rather than left as an open finding: `resolve-core.sh` now always
discards and re-clones the cache instead of trusting a pre-existing one
(a `git pull` was tried first but silently no-ops on the shallow
detached-HEAD clone this cache is left in — re-clone is the reliable
fix). No assertion that runs when core is reachable was touched or
weakened.

Verified: (1) full suite green with the stale cache cleared; (2) full
suite still green after deliberately re-pinning the cache to the
pre-issue-75 commit `22a7cadef5c1389433d130bb4c9742863fbe47c0` and
re-running — `resolve-core.sh` now self-heals; (3) `missing-core-test.sh`
(genuine non-resolution, no sibling/cache/network reachable) still exits
75 with the SKIP message, unchanged.

# Implementation record — issue #19

## What was done
Adopting the canonical test-env resolution convention (on-the-record
`docs/specs/test-env-resolution.md`, issue #551) across this repo's
gate-test scripts, per the approved phase-1 proposal at
`docs/issue-19/proposals/test-env-resolution-adoption.md`.

## Why
Gate-test scripts currently fail misleadingly on a plain checkout outside
the spawn env (no `CLAUDE_PLUGIN_ROOT_CORE`). Adopting the convention's
resolution order and SKIP contract (exit 75, explicit message) fixes
that without weakening any assertion that runs when core is reachable.

## Basis
docs/issue-19/proposals/test-env-resolution-adoption.md

## Doc-placement ladder
- [x] `docs/issue-19/reports/implementation.md` — this record.
- No handbook/decisions/reports doc-placement triggers apply beyond the
  proposal itself (no new env var, dep, migration, or public
  signature/wire-format change; the vendored module is a straight port).

## What did not work
None.

## Open findings
None. Before-landing warrant-hunt dispatch (stance: "assume this change
and another plugin's rule cancel each other") returned NO FINDING;
recorded in `docs/reports/2026-08-09-hunt-test-env-resolution-adoption.md`.

## Closed checks
- `tests/run-all-gate-tests.sh` and each of the four per-plugin suites
  exit 75 with the convention's SKIP message when core is genuinely
  unresolved (verified with an isolated `TMPDIR` and a stub `git` that
  always fails, network otherwise reachable in this sandbox).
- With core reachable (network-clone fallback populating the cache),
  running `tests/run-all-gate-tests.sh` executes every suite's real
  assertions unchanged — confirmed a pre-existing, unrelated
  `gate_bash_write_targets` AttributeError in `gate_lib` surfaces as a
  FAIL (not masked by SKIP), matching the proposal's "real defect surfaces"
  constraint.
- `tests/missing-core-test.sh` passes against the new exit-75 contract
  (isolated the same way, to force genuine non-resolution rather than
  relying on ambient sibling/cache state).
- `grep -rl "test-env-resolution" tests/ data-modeling-*/tests/` matches
  all eight touched scripts.

## Next steps
None — record is landing in this session.

## Resolution path
N/A — no open findings.
