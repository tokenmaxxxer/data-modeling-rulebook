---
code_under_review:
  - README.md
  - data-modeling/hooks/directive.sh
  - data-modeling-structure/hooks/structure-gate.sh
  - data-modeling-structure/tests/structure-gate-tests.sh
  - docs/specs/record-fields-terminal-states.json
type: docs+hooks
breaking: false
verdict: pass
loop_state: landed
---

Subject: issue-16

# Implementation record — spec-field alignment (phase 2)

## What was done

Applied `docs/issue-16/proposals/spec-field-alignment.md` verbatim against
its frozen write set:

1. `README.md` — added a "Spec fields" subsection under `## Methodology`
   naming the four required record fields (`table_name`, `table_type`,
   `grain`, `verdict`) with type/enum, and a `loop_state` table covering
   the spec's five states (`modeling`, `reviewing`, `landed`,
   `grain-undeclared`, `table-unreachable`).
2. `data-modeling/hooks/directive.sh` — extended the `PRODUCES` string to
   name the four required record fields alongside the existing artifact
   list.
3. `data-modeling-structure/hooks/structure-gate.sh` — added an
   unconditional check in the `is_record` branch requiring `table_name:`,
   `table_type:` (`fact`/`dimension`), `grain:`, and `verdict:`
   (`pass`/`fail`) as labeled lines, additive to the existing
   layers/data-dictionary/migration/rollback checks.
4. `data-modeling-structure/tests/structure-gate-tests.sh` — added cases:
   each of the four fields missing individually denies; out-of-enum
   `table_type`/`verdict` denies; all four present and in-enum (added to
   `GOOD_RECORD`) passes.
5. `docs/specs/record-fields-terminal-states.json` — added
   `{"coding-record": ["landed"]}`, matching the sibling rulebooks' shape
   and core's `record-fields-gate.sh` per-kind terminal-state override
   format.
6. `docs/handbooks/run-all-gate-tests.md` — no stated test count needed
   updating (the doc names suite files, not a case count), so left
   unchanged; confirmed at write time per the proposal's own instruction.

## Why

Basis: `docs/issue-16/proposals/spec-field-alignment.md`, approved via
`APPROVE issue-16/implementation` (issue-16 comment). Layers the realized
`roles/specs/data-modeling.spec.json` (program #521-#525) required fields
and `loop_state` vocabulary onto this rulebook without deleting existing
methodology content, per the issue's Acceptance criteria.

## Upstream

Basis: `docs/issue-16/proposals/spec-field-alignment.md`

## What did not work

None.

## Rationale for deviations

The proposal's step 3 named `table_type`'s enum as `fact`/`dimension`
only (matching the survey's read of the spec). The before-landing
warrant hunt (stance: assume this change and another plugin's rule
cancel each other) found this makes every well-formed Data Vault record
undeliverable: `data-modeling-datavault/hooks/datavault-gate.sh` accepts
hub/link/satellite-shaped records with no fact/dimension distinction,
while the new unconditional `table_type` check in
`data-modeling-structure/hooks/structure-gate.sh` denied them outright.
Widened the enum to `fact`/`dimension`/`n/a`, keeping the field always
required (an explicit `n/a` declaration, never a silent omission) per
this repo's existing "layers-or-justified-skip" convention. Within the
frozen write set (`structure-gate.sh` and its test file were already
listed) — not a scope-exceeded stop, a within-scope correction to a
proposal detail that turned out to conflict with another gate.

## Verification run

`bash tests/run-all-gate-tests.sh` from repo root — all four plugin
suites plus `compliance-check.sh` passed, including the six new
`table_name`/`table_type`/`grain`/`verdict` cases added to
`structure-gate-tests.sh` (missing-each-field and out-of-enum
`table_type`/`verdict` denies; complete `GOOD_RECORD` with all four
fields passes). Both acceptance greps confirmed: all four field names
present in `docs/`/`README.md`; `loop_state` vocabulary greps match the
spec's five states exactly.

## Open findings

None. `docs/reports/2026-08-09-hunt-spec-field-alignment.md` (after-
proposal warrant hunt) returned NO FINDING.

## Doc placement (ladder)

- [x] `README.md` — spec fields + loop_state vocabulary documented
      (public-surface doc, same turn).
- [x] `docs/specs/record-fields-terminal-states.json` — core-consumed
      per-kind terminal-state config (same turn, matches sibling
      rulebooks' convention).
- [x] `docs/handbooks/run-all-gate-tests.md` — checked for a stale count;
      none found, left as-is.
