---
Subject: issue-16
---

# Survey — align rulebook with data-modeling.spec.json (phase 1)

## Spec read

`roles/specs/data-modeling.spec.json` (on-the-record marketplace, program
#521-#525):

- `required_fields`: `table_name` (ref), `table_type` (enum:
  fact/dimension), `grain` (string), `verdict` (enum: pass/fail).
- `reference_resolution`: `table_name` must resolve to an actual modeled
  table definition — no orphan references.
- `recomputation`: `verdict` is recomputed from `table_name`'s declared
  grain vs. current columns, never a standalone asserted field — checker
  is `TBD` (explicit out-of-scope follow-up per issue-521; not this
  issue's job to build).
- `write_scope`: `["docs/issue-<n>/reports/data-modeling.md"]` — matches
  this repo's existing record path exactly.
- `loop_state`: progress `[modeling, reviewing]`, terminal `[landed]`,
  refusal `[grain-undeclared]`, error `[table-unreachable]`.
- `use_when`: a new fact/dimension table is proposed on the branch and no
  data-modeling record exists yet for it.

## Current rulebook state (this repo)

Five plugins: `data-modeling` (role directive), `data-modeling-structure`
(phase-shape gate), `data-modeling-{inmon,kimball,datavault}`
(methodology content gates). All four gate scripts share one frozen
contract (in-scope paths: `docs/issue-<n>/proposals/*.md` and
`docs/issue-<n>/reports/data-modeling.md`; fail-closed; Bash-write
content-blind refusal; kill switches).

- `data-modeling-structure/hooks/structure-gate.sh`: on a **record**
  write, requires conceptual/logical/physical (or a justified skip),
  `data dictionary`, `migration plan`, `rollback`, and a hand-off note
  when pipeline/ETL is mentioned. It does **not** check for
  `table_name`, `table_type`, or `verdict` by name anywhere. On a
  **proposal** write it requires survey-reference,
  conceptual/logical/physical, alternatives, open questions, and a named
  methodology fit.
- `data-modeling-kimball/hooks/kimball-gate.sh` (fires only when the
  write names kimball/dimensional model/star schema): on a proposal,
  requires a `grain` statement (`grain:` / `grain is`) — this is the
  closest existing hook to spec's `grain` field, but it only fires when
  Kimball vocabulary is present in the text, not unconditionally. On a
  record, requires `fact table` and `dimension table` headings/lines —
  the closest existing anchor to spec's `table_type` enum
  (fact/dimension), but expressed as two separate required labels, not
  one `table_type:` field with an enum value.
- `data-modeling-inmon/hooks/inmon-gate.sh` and
  `data-modeling-datavault/hooks/datavault-gate.sh`: same shape,
  methodology-specific vocabulary only (3NF/normal form;
  hub/link/satellite). Neither touches `table_name`, `table_type`,
  `grain`, or `verdict`.
- `README.md`: documents `decides`/`use_when`/`produces`/`write_scope`/
  `hand-off` and the methodology-selection table (Inmon/Kimball/Data
  Vault). No mention of `table_name`, `table_type`, `grain`, `verdict`,
  or any `loop_state` vocabulary.
- `data-modeling/hooks/directive.sh`: role directive text — lists
  `PRODUCES` fields (conceptual/logical/physical model, ERD, data
  dictionary, normalization rationale, migration plan+rollback). No
  `table_name`/`table_type`/`grain`/`verdict`/`loop_state` mention.
- `docs/handbooks/run-all-gate-tests.md`: gate-test runbook, no field
  vocabulary content.
- No `docs/specs/record-fields-terminal-states.json` exists in this repo
  — the per-kind `loop_state` terminal-state override this repo's core
  dependency (`tokenmaxxxer-core`) supports is currently unset for
  `data-modeling`, so core's generic default states apply globally,
  not the spec's kind-specific vocabulary
  (`modeling`/`reviewing`/`landed`/`grain-undeclared`/
  `table-unreachable`).
- Prior `loop_state:` values actually used in this repo's own records
  (`docs/issue-1`, `-7`, `-10`, `-13`): all `landed` — no prior record
  used `modeling`, `reviewing`, `grain-undeclared`, or
  `table-unreachable`, so there is no existing usage to conflict with.

## Gaps against the spec (write-surface candidates)

| Spec field/vocabulary | Existing rulebook anchor | Gap |
|---|---|---|
| `table_name` (ref, must resolve — no orphans) | none | not named anywhere; no reference-resolution rule in any gate |
| `table_type` (enum: fact/dimension) | kimball-gate's `fact table`/`dimension table` labels (record-only, Kimball-triggered only) | not a named `table_type:` field; not enum-checked; not required for Inmon/Data-Vault-shaped records |
| `grain` (string, required) | kimball-gate's grain check (proposal-only, Kimball-triggered only) | not required on records; not required for non-Kimball methodology fits |
| `verdict` (enum: pass/fail) | none | not named anywhere in any gate or doc |
| `loop_state` vocabulary (`modeling`, `reviewing`, `landed`, `grain-undeclared`, `table-unreachable`) | core's generic default (unoverridden) | no per-kind override file in this repo; spec's refusal/error states have no rulebook-side documentation of when to use them |
| `reference_resolution` rule (table_name must resolve) | none | not documented; enforcement explicitly named as a separate on-the-record hook (`role-spec-reference-guard.sh`), not this rulebook's job to build |
| `recomputation` rule | none | spec itself marks `checked_by: TBD` — explicit issue-521 follow-up, out of scope here too |
| `write_scope` | `docs/issue-<n>/reports/data-modeling.md` | already matches exactly — no gap |
| `use_when` | README's methodology table implies this but doesn't state the board-condition trigger explicitly | soft gap — not a required field, lower priority |

## Write-set candidates for phase-1 proposal

- `README.md` — add spec-field vocabulary + loop_state table.
- `data-modeling/hooks/directive.sh` — extend `PRODUCES` to name the four
  required fields.
- `data-modeling-structure/hooks/structure-gate.sh` — record-shape check
  is the natural home for `table_name`/`table_type`/`grain`/`verdict`
  since it already fires unconditionally on every in-scope record write
  (unlike the methodology gates, which are content-triggered only).
- `data-modeling-structure/tests/structure-gate-tests.sh` — test
  coverage for whatever the gate change adds.
- `docs/specs/record-fields-terminal-states.json` — new file to declare
  the spec's exact `loop_state` set as this repo's `data-modeling` kind
  override (progress/terminal/refusal/error, matching the spec's four
  buckets).
- `docs/handbooks/run-all-gate-tests.md` — update if the structure-gate
  test file's coverage table needs a new row (mechanical, only if the
  test count changes).

## Prior decisions this issue must not undo

- `docs/issue-7/proposals/methodology-enforcement.md` and
  `docs/issue-10`/`docs/issue-13` gate-remediation proposals established
  the current fail-closed, content-triggered, four-plugin gate shape.
  This issue strengthens field vocabulary, not the gate architecture.
- Issue-13's record explicitly calls out that naming all sibling plugins
  in a structural/tooling record (not a real methodology decision) trips
  the per-methodology gates' allowlist checks and requires the
  "not applicable" labeled-line technique — the same technique will
  likely be needed again in this issue's own phase-2 record.
