---
status: proposed
files:
  - README.md
  - data-modeling/hooks/directive.sh
  - data-modeling-structure/hooks/structure-gate.sh
  - data-modeling-structure/tests/structure-gate-tests.sh
  - docs/specs/record-fields-terminal-states.json
  - docs/handbooks/run-all-gate-tests.md
---

Subject: issue-16

# Proposal — align rulebook with `data-modeling.spec.json` (phase 1)

Basis: `docs/issue-16/reports/implementation/survey.md`.

## Request

Layer the realized marketplace spec `roles/specs/data-modeling.spec.json`
(program #521-#525, on-the-record) onto this rulebook's docs and hooks:
its four required record fields (`table_name`, `table_type`, `grain`,
`verdict`) and its `loop_state` vocabulary (`modeling`, `reviewing`,
`landed`, `grain-undeclared`, `table-unreachable`). Strengthen existing
methodology content, never delete it. Phase 1 only — no code/hook
behavior changes land in this PR.

## Constraints

- Existing gate architecture (four content-triggered methodology gates +
  one always-on structure gate, fail-closed, kill-switched) stays as-is —
  this issue strengthens field vocabulary, not the gate shape
  (issue-7/-10/-13 precedent).
- `write_scope` in the spec (`docs/issue-<n>/reports/data-modeling.md`)
  already matches this repo exactly — no path change needed.
- `reference_resolution` and `recomputation` enforcement are explicitly
  out of scope: the spec itself names `role-spec-reference-guard.sh` (an
  on-the-record hook, not this rulebook) for the former, and marks the
  latter `checked_by: TBD` as an issue-521 follow-up not yet assigned to
  any role.
- Per contract v3, a proposal never edits code/behavior — only phase 2
  (after approval) touches the hook scripts and test file for real; this
  PR's write set lists them because the survey already located the exact
  edits, but no phase-2 code lands until `APPROVE issue-16/implementation`.

## Rationale

**Where do `table_type`/`grain`/`verdict` get enforced?**
Considered: extending each of the three methodology gates
(`kimball-gate.sh`, `inmon-gate.sh`, `datavault-gate.sh`) to each check
their own subset of the four fields, since `kimball-gate.sh` already
partially covers `grain` and `table_type` (as separate fact/dimension
labels). Rejected: those three gates are content-triggered (fire only
when their methodology's vocabulary appears in the text) — spec's four
fields are unconditionally required on every record, so a
content-triggered gate would silently skip the check on any record that
doesn't happen to name its methodology by name. `data-modeling-structure`'s
gate already fires unconditionally on every in-scope record write, so it
is the correct, single home for the four required fields; the
methodology gates keep their narrower, methodology-specific checks
unchanged.

**How does `loop_state` vocabulary get declared?**
Considered: hard-coding the spec's five states directly into
`data-modeling/hooks/directive.sh` prose only, with no core-consumed
config. Rejected: core's generic `record-fields-gate.sh` (this repo's
hard dependency, `core@tokenmaxxxer-core`) already reads a
`docs/specs/record-fields-terminal-states.json` per-kind override at
write time — prose alone would describe the vocabulary without making
core's own terminal-state check enforce it, leaving a documentation/
enforcement split identical to the gap this issue is trying to close.
Three sibling rulebooks doing this same spec-alignment task
(`content-design`, `release-engineering`, `api-design`, each issue-16's
counterpart in their own repos) landed exactly this file shape, so this
proposal follows established convention rather than inventing a new one.

## What will be done

1. **README.md** — add a "Spec fields" subsection under `## Methodology`
   naming the four required record fields (`table_name`, `table_type`,
   `grain`, `verdict`) with their type/enum, and a `loop_state` table
   (progress: `modeling`, `reviewing`; terminal: `landed`; refusal:
   `grain-undeclared`; error: `table-unreachable`) with one line each on
   when a record should carry the refusal/error states.
2. **data-modeling/hooks/directive.sh** — extend the `PRODUCES` string to
   name the four required fields alongside the existing artifact list
   (conceptual/logical/physical model, ERD, data dictionary, etc.), so
   the SessionStart directive itself carries the vocabulary a session
   sees before writing anything.
3. **data-modeling-structure/hooks/structure-gate.sh** — on a record
   write (`is_record` branch), add a check requiring `table_name:`,
   `table_type:` (value one of `fact`/`dimension`), `grain:`, and
   `verdict:` (value one of `pass`/`fail`) as labeled lines or headings,
   alongside the existing conceptual/logical/physical + data-dictionary +
   migration-plan + rollback checks (additive, none removed). Missing or
   out-of-enum values are named in the `missing` list the same way
   existing checks are, keeping the fail-closed/deny-with-reason shape.
4. **data-modeling-structure/tests/structure-gate-tests.sh** — add cases:
   a record missing each of the four fields individually is denied; a
   record with an out-of-enum `table_type`/`verdict` value is denied; a
   record with all four present and in-enum passes (alongside its
   existing required content).
5. **docs/specs/record-fields-terminal-states.json** (new file) —
   core's `record-fields-gate.sh` reads this file as `{kind: [terminal
   states]}` (a flat list per kind, validated as such — confirmed against
   the file's actual shape once written, matching the three sibling
   rulebooks doing this same task, e.g.
   `api-design-rulebook-issue-17-implementation/docs/specs/record-fields-terminal-states.json`
   after normalization: `{"coding-record": ["landed"]}`). This gate only
   overrides the *terminal* set — `progress`/`refusal`/`error` states
   have no core-side mechanical check today, so the spec's full
   five-state vocabulary is documented (step 1/2 above) but only its
   terminal member is config-enforced:
   ```json
   {
     "coding-record": ["landed"]
   }
   ```
   (`data-modeling` has no dedicated kind in core's `ROLE_TO_KIND`
   mapping, so records fall back to self-declared `kind:` frontmatter;
   `coding-record` is the closest generic build-artifact kind and is
   what this rulebook's records already implicitly resolve to via the
   `implementation` role alias. Since the spec's terminal state
   (`landed`) already matches `coding-record`'s core default exactly,
   this file may turn out to be a no-op confirmation rather than an
   actual override — phase 2 verifies this against the live
   `record-fields-gate.sh` before deciding whether the file is still
   worth adding solely for explicitness.)
6. **docs/handbooks/run-all-gate-tests.md** — update the
   structure-gate-tests coverage note only if the new test count in step
   4 changes a stated number in this doc (mechanical, checked at
   write time, not a design decision).

## Out of scope

- `reference_resolution` enforcement (`table_name` orphan-reference
  checking) — belongs to on-the-record's `role-spec-reference-guard.sh`,
  not this rulebook.
- `recomputation` enforcement for `verdict` — spec marks this `TBD`,
  explicitly deferred past issue-521.
- Any change to the Inmon/Kimball/Data-Vault methodology gates' existing
  content checks (grain-in-proposal, fact/dimension-table-in-record) —
  those stay as additional, methodology-specific checks layered on top
  of the new unconditional structure-gate checks, not replaced by them.
- Any phase-2 code edit in this PR — phase 1 is proposal only.

## How you'll know it worked

- `grep -ri 'table_name\|table_type\|grain\|verdict' docs/ README.md`
  finds all four field names after phase 2 (issue's own acceptance
  check).
- `grep -n 'modeling\|reviewing\|landed\|grain-undeclared\|table-unreachable'
  README.md data-modeling/hooks/directive.sh
  docs/specs/record-fields-terminal-states.json` shows the loop_state set
  matches the spec exactly, no stale/extra states.
- `bash tests/run-all-gate-tests.sh` (or
  `data-modeling-structure/tests/structure-gate-tests.sh` directly) runs
  green after phase 2, including the new field-presence/enum test cases.
- If no test suite runner applies to a given change (e.g. the README
  prose addition), that fact is stated plainly in the phase-2 record
  rather than silently skipped, per the issue's `unverifiable` acceptance
  clause.
