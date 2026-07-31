---
Subject: issue-7
---

# Proposal — directive depth + methodology gate for `data-modeling` (phase 1)

Phase 1 only. No plugin/test edits in this PR — this document is the plan
phase 2 will execute once approved (`APPROVE issue-7/data-modeling`,
single-account mode per `docs/specs/approvers.md`).

Backed by `docs/issue-7/reports/data-modeling/survey.md` (current-state
gaps) and `docs/issue-7/reports/data-modeling/scout-brief.md` (sibling
rulebook precedent — `pricing`'s `methodology-gate.sh`, `implementation`'s
state-tracking pair).

## 1. Directive depth (phase 1 / phase 2, per facet)

`data-modeling/hooks/directive.sh` calls core's `core_role_directive` with
four fixed args (decides/use_when/produces/hand-off); the template has no
phase slot, so today's `PRODUCES` line is a one-line summary regardless of
phase. Per the survey, the fixable surface is the `README.md` "Methodology"
section (already the precedent from issue-1, which put the fit table there
because the 4-arg template had no room for it). This proposal adds a
**"Directive detail"** section to `README.md` with the following content —
the directive.sh call itself is unchanged (still points to the `PRODUCES`
summary + `RECORD:` line; the depth lives one level down, same relocation
pattern issue-1 already established for the fit table).

### Phase 1 (proposal) — steps, judgment criteria, prohibitions

**Steps** (already the required-sections list from `docs/issue-1/proposals/rulebook-maturation.md`
(a), restated here as the enforceable step order):
1. Problem statement.
2. Current-state survey reference (must exist as a sibling file before the
   proposal is drafted — SURVEY-FIRST, not a phase-2 afterthought).
3. Proposed design: name the methodology-fit row (OLTP/Inmon-3NF,
   analytics/Kimball, raw-ingestion/Data-Vault) and which model layer(s)
   this decision touches.
4. Alternatives considered (at least one rejected option + reason).
5. Open questions / risks for the approver.

**Judgment criteria** (facet: `decides`) — before step 3, decide the
methodology-fit row by asking: is this schema the single source of truth
for a transactional workload (→ Inmon/3NF), primarily BI/reporting
consumption (→ Kimball), or raw multi-source ingestion under schema drift
needing auditability (→ Data Vault)? A decision that fits none of the
three names why not, explicitly — it does not default silently to one row.

**Prohibitions**:
- No proposal that jumps to step 3 without a step-2 survey file existing
  first (survey-before-proposal is load-bearing, not stylistic).
- No proposal presenting only the chosen design with no step-4 alternative.
- No methodology/pattern claim without a source trace to the survey or a
  scout brief — matches the evidence-form rule already adopted in issue-1
  (c), restated here as a phase-1 prohibition rather than a rationale note.

### Phase 2 (record) — steps, judgment criteria, prohibitions

**Steps** (from issue-1 (b), restated as the record-writing step order):
1. Produce conceptual, logical, and physical artifacts, in that order —
   or an explicit statement of which layer(s) this specific change doesn't
   touch and why (e.g. "physical-only index tuning; conceptual/logical
   unchanged because no entity/attribute/relationship changes").
2. State the normalization rationale: target normal form named, every
   deviation named with a reason.
3. Data dictionary, as a component distinct from the ERD (per-column
   type/nullability/meaning/constraints) — not folded into the ERD
   caption.
4. Migration plan, including a rollback path.

**Judgment criteria** (facet: `produces`) — a layer is "untouched" only
when the change introduces no new/changed entity, attribute, relationship,
or key; anything narrower (e.g. "we didn't touch the ERD file") is not a
valid skip justification on its own — the record must say *why* in
schema-decision terms.

**Prohibitions**:
- No record that presents physical DDL with no conceptual/logical trace
  and no explicit skip justification.
- No "normalization rationale" field left as a bare mention of a normal
  form with no deviations discussion (even "no deviations" must be stated,
  not implied by silence).
- No migration plan without a rollback path — an irreversible migration
  plan is incomplete, full stop, mirroring `docs/issue-1/proposals/rulebook-maturation.md`
  (c)'s reasoning on Data-Vault-class ingestion risk.

### Hand-off facet (`decides` boundary, both phases)

**Criteria**: the moment a change requires moving/transforming data
between existing schemas (not deciding what a schema *is*), it crosses into
`data-engineering`'s `decides`, not this role's.

**Prohibition**: do not silently absorb pipeline-movement scope into a
schema-modeling record — per `README.md`'s existing BOUNDARY CASE clause,
record the hand-off point in this role's record before opening the next
role's session; this proposal does not change that clause, only cites it
as the facet-level rule the phase-2 gate below also checks for.

## 2. Methodology gate — `data-modeling/hooks/methodology-gate.sh`

**Adopted from `pricing/hooks/methodology-gate.sh`'s structural shape**
(fail-closed trap-at-top, path-scoped `PreToolUse` on `Write|Edit|MultiEdit`,
resolves `Edit`/`MultiEdit` diffs against current file content rather than
checking raw tool args, role-labeled deny message, namespaced kill switch,
fails closed on unparseable payload / unresolvable diff / internal error).
Adoption reasoning is in the scout brief; this is canon-referenced
structure, not a canon file — `pricing`'s script is a sibling *role's own*
file, not something under `core/hooks/`, so `docs/handbooks/canon-scripts.md`'s
never-copy clause does not apply to reusing its shape, only to core-owned
scripts (`trailer-gate.sh`, `record-fields-gate.sh`,
`handbook-trigger-gate.sh`, `stub-check.sh`), none of which this file
touches or duplicates.

**One deviation from pricing's path-scope regex, stated explicitly per the
`canon-scripts.md` convention of naming exceptions rather than defaulting**:
pricing scopes proposals by filename substring (`*pricing*.md`). This
repo's own proposal filenames carry no role substring (`rulebook-maturation.md`,
`core-canon-switch.md`) — a contract-v3 branch is one-role-per-branch, so
every file under `docs/issue-<n>/proposals/` on this role's branch already
belongs to this role. The gate therefore scopes by **path pattern +
`CLAUDE_ROLE=data-modeling`** (matching the kill-switch's own role check)
instead of filename substring:

- Proposal surface: `docs/issue-[0-9]+/proposals/*.md`
- Record surface: `docs/issue-[0-9]+/reports/data-modeling\.md` (exact —
  this filename already carries the role name, no ambiguity)

**Required elements** (phase-2 preview of `methodology-gate.sh`'s checks,
mirroring the six-element pattern in `pricing`'s gate but scoped to this
role's own norms from (1) above):

For a **proposal** write (path matches the proposals surface):
1. `methodology-fit-named` — one of `inmon`, `3nf`, `kimball`, `dimensional
   model`, `star schema`, `data vault` appears, OR an explicit no-fit
   statement (`no schema decision`, `not applicable`, `routed to`) is
   present.
2. `layers-named` — at least one of `conceptual`, `logical`, `physical`
   appears (which layer(s) this decision touches).
3. `alternatives-considered` — the phrase `alternative` (or `대안`) appears.
4. `survey-referenced` — the phrase `survey` (or a path containing
   `reports/data-modeling/survey`) appears.
5. `open-questions` — `open question`, `risk`, or `open decision` (or
   Korean equivalents `열린 질문`/`리스크`) appears.

For a **record** write (path matches the record surface):
1. `layers-or-justified-skip` — `conceptual`, `logical`, and `physical` all
   appear, OR fewer appear alongside an explicit skip justification phrase
   (`unchanged because`, `no schema decision`, `not applicable`).
2. `normalization-rationale` — a normal-form token (`1nf`, `2nf`, `3nf`,
   `bcnf`, `denormalized`) appears alongside `deviation` or `no deviation`.
3. `data-dictionary` — the phrase `data dictionary` appears as a heading or
   named section distinct from `erd`/`entity relationship`.
4. `migration-rollback` — `migration plan` appears alongside `rollback`.

Fails closed (deny) listing every missing element by name, mirroring
`pricing`'s deny-message format, if any required element for the matched
surface is absent. Non-matching paths and non-`Write|Edit|MultiEdit` tools
exit 0 immediately (not this gate's business).

**Kill switch**: `DATA_MODELING_METHODOLOGY_GATE_OFF=1` (role uppercased,
same convention as `core_role_directive`'s per-role `_CYCLE_OFF`).

**No state-tracking mechanism** — per the survey's ordering-constraint
finding: this role's methodology resolves survey→proposal→record within
same-turn writes the content gate can check directly (proposal must
reference the survey file by name/path — element 4 above), not across
persisted hook invocations the way `coding`'s hunt-lock tracks subagent
dispatch across turns. Adding a state file here would enforce an ordering
constraint this role's methodology does not actually have.

**`hooks.json` addition** (phase-2 preview):
```json
"PreToolUse": [
  {
    "matcher": "Write|Edit|MultiEdit",
    "hooks": [
      { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/methodology-gate.sh" }
    ]
  }
]
```
(appended alongside the existing `SessionStart` entry, not replacing it.)

## 3. Gate tests — `tests/data-modeling-gate-tests.sh`

New repo-root `tests/` directory (none exists today). Structure follows
core's `core/hooks/tests/run-role-gates-tests.sh` subprocess-invocation
pattern (spawn the real script with a synthetic `PreToolUse` JSON payload
on stdin, assert exit code + role-labeled deny string), scoped to cases
this role's gate actually needs:

1. Proposal missing `alternatives-considered` → deny, message names
   `alternatives-considered`.
2. Proposal with all five elements present → allow.
3. Proposal with an explicit no-fit statement instead of a named
   methodology → allow (escape hatch works).
4. Record missing `migration-rollback` → deny.
5. Record with an explicit layer-skip justification instead of all three
   layers → allow (escape hatch works).
6. Write to a path outside both surfaces (e.g. `docs/issue-7/reports/data-modeling/survey.md`
   itself) → allow, gate does not fire.
7. `Edit` whose `old_string` does not match current file content → deny
   (unresolvable diff, fail-closed).
8. `DATA_MODELING_METHODOLOGY_GATE_OFF=1` → allow regardless of content.
9. Malformed JSON on stdin → deny (fail-closed).

Phase 2 will write the actual script content executing this list; this
proposal fixes the case list and expected verdicts so phase 2 has no
discretion to under-test.

## 4. Agents / checklist (issue #7 item 4)

**Not needed.** Per the survey's ordering-constraint analysis: this role's
methodology has no repeated multi-step procedure that needs an agent or
checklist artifact beyond what the phase-1/phase-2 step lists in (1) above
and the gate in (2) already enforce mechanically. Stated explicitly per
issue #7's own "필요 시" (if needed) conditioning — this is the "not
needed, and here is why" answer rather than a silent omission.

## 5. Net file diff (phase 2 preview, not executed here)

- Edit: `README.md` (new "Directive detail" section, §1 above).
- New: `data-modeling/hooks/methodology-gate.sh` (§2).
- Edit: `data-modeling/hooks/hooks.json` (add `PreToolUse` entry, §2).
- New: `tests/data-modeling-gate-tests.sh` (§3).
- No change to `data-modeling/hooks/directive.sh` — its `PRODUCES` line
  already names the five record components (issue-1); depth lives in
  `README.md`, not the 4-arg template.
- No new `agents/` or checklist files (§4).
- No `core/hooks/` file touched or copied (canon-reference-only preserved).
