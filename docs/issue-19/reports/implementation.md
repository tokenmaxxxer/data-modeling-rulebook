---
code_under_review: PENDING
type: chore
breaking: false
verdict: PENDING
loop_state: committing
---

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
