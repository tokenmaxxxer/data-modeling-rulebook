---
Subject: issue-1
---

# Proposal — rulebook maturation for `data-modeling` (phase 1)

Phase 1 only. No plugin edits in this PR — this document is the plan phase
2 will execute once approved (`APPROVE issue-1/data-modeling`, single-account
mode per `docs/specs/approvers.md`).

Backed by `docs/issue-1/reports/data-modeling/survey.md` (current-state gaps)
and `docs/issue-1/reports/data-modeling/scout-brief.md` (field must-bes).

## (a) Phase-1 proposal norm — methodology, required sections, evidence form

**Methodology: RFC-shaped design proposal.** Scout brief's sweep found
convergent agreement across every RFC/design-doc source that a proposal
lacking an alternatives-considered section is under-baked; this matches
contract v3's own phase-1/phase-2 split closely enough to adopt directly
rather than invent a role-specific format.

Required sections for every future `data-modeling` phase-1 proposal:

1. **Problem statement** — what schema/relationship decision is being made
   and why now (not "what" the schema will be — that's section 3).
2. **Current-state survey reference** — link to the accompanying
   `docs/issue-<n>/reports/data-modeling/survey.md`; a proposal is never the
   first place current state gets described.
3. **Proposed design** — for a schema decision, this means: which model
   layer(s) are affected (conceptual/logical/physical — see (b)), the
   methodology-fit call (see (b) decision rule) with the reasoning for why
   this class of decision falls where it does, and the normalization
   target with any deviations named and justified.
4. **Alternatives considered** — at least one rejected alternative, with the
   reason for rejection. A proposal presenting only the chosen design fails
   this norm.
5. **Open questions / risks** — anything left for the approver to weigh in
   on before Approve (mirrors the "Open decision for the approver" pattern
   already used in `docs/issue-2/proposals/core-canon-switch.md`).

**Evidence form**: every methodology/pattern claim in the proposal must
trace to the scout brief's `Sources:` list or the survey's file citations —
no unsourced "best practice" assertions, matching the scout-directive's
source-or-assumption rule already enforced on this pass.

## (b) Phase-2 deliverable norm — methodology, required components

**Three model layers are mandatory, not optional**, for any schema/relationship
decision this role produces:

- **Conceptual** — entities and relationships in business language,
  stakeholder-readable, no attributes/types yet.
- **Logical** — full attribute list, relationships, keys, normalized to the
  stated target form, still platform-independent.
- **Physical** — concrete types, indexes, partitioning, constraints, for the
  actual target platform.

A deliverable that jumps straight to physical (raw DDL with no conceptual/logical
trace) does not satisfy this norm, even if the DDL itself is correct.

**Methodology-fit decision rule** (adopted instead of one fixed methodology —
scout brief explicitly flags mandating a single warehouse methodology as a
skip, since this role's `WRITE_SCOPE` spans `src/**` migrations broadly, not
warehouse-only):

| Decision shape | Methodology |
|---|---|
| OLTP / transactional schema, single source of truth | 3NF-normalized, Inmon-style subject-oriented modeling |
| Analytics / reporting / BI consumption | Kimball dimensional modeling (star/snowflake, fact + dimension tables) |
| Raw multi-source ingestion, heavy schema evolution, auditability requirement | Data Vault (hubs/links/satellites) |

The proposal's "Proposed design" section (a.3) must name which row applies
and why; picking a row is itself part of the phase-1 deliverable, not
deferred to phase 2.

**Required components of every phase-2 record** (`docs/issue-<n>/reports/data-modeling.md`),
on top of the generic contract §20 shape (what/why/upstream/loop_state/open-findings,
already enforced by core's `record-fields-gate.sh` and explicitly preserved
per this issue's constraint):

1. Conceptual, logical, and physical model artifacts (or an explicit,
   justified statement of which layer(s) this specific change doesn't touch —
   e.g. a physical-only index tuning still names why conceptual/logical are
   unchanged).
2. **Normalization rationale** — target normal form stated explicitly, every
   deviation named with a reason. (This is already a named `PRODUCES` field;
   this proposal defines what must be *inside* it.)
3. **Data dictionary**, as a component distinct from the ERD — per-column
   type/nullability/meaning/constraints. Scout brief flags conflating these
   two as a common documentation failure.
4. **Migration plan** — already a named `PRODUCES` field; this proposal adds
   that it must include a rollback path, since none of the current free-text
   wording requires one and an irreversible migration plan is a real risk
   this role can introduce.

## (c) Adoption rationale

- **Three-layer requirement**: every deliverable-focused source in the scout
  sweep (DAMA-DMBOK, ERD best-practice writeups) treated skipping a layer as
  a documentation gap, not a style choice — this is as close to a field
  consensus as the sweep found. Rejecting it would mean this rulebook
  diverges from the one point every source agreed on.
- **Methodology-fit table over a single fixed methodology**: the fit
  argument is intrinsic to why the methodologies exist as three separate
  things in the field at all — Kimball optimizes for query speed off a known
  BI workload, Inmon optimizes for consistency across an enterprise's whole
  data estate, Data Vault optimizes for raw auditable ingestion under
  schema drift. This role's own `WRITE_SCOPE` (`src/**`, migrations) is
  workload-agnostic, so binding it to one methodology would force wrong-fit
  designs on whichever workload the methodology doesn't suit — the opposite
  of "the intended value this role provides" (correct schema decisions,
  not decisions that happen to match one committed style).
- **RFC shape for phase 1**: this role's phase-1 output already sits inside
  contract v3's phase-1/phase-2 gate; RFC's problem/design/alternatives/open-
  questions shape is the same decision-under-review structure the contract
  already assumes (a human Approve gates phase 2), so adopting it costs
  nothing structurally and closes the "no alternatives" failure mode the
  scout brief flagged as the field's most common design-doc defect.
- **Data dictionary as separate required component**: directly closes a
  named gap in current state (survey: `PRODUCES` lists "schema/ERD" as one
  item, with no data-dictionary concept at all) using a distinction the
  scout brief sourced as an explicit best-practice call-out, not an
  invented addition.
- **Rollback path added to migration plan**: not sourced from the sweep
  directly, but is the direct consequence of adopting a methodology-fit
  model that includes Data Vault-style raw-ingestion migrations, which
  compound risk under schema drift — a migration plan without a rollback
  path is incomplete for exactly the higher-risk case this proposal's own
  methodology table introduces.

## (d) Plugin reflection plan (phase 2 execution preview, not executed here)

Per survey: this repo carries **no local gate files** post-issue-2 (core
canon owns trailer/record-fields/handbook-trigger globally); any enforcement
here must ride the canon-stub's existing extension points, not a new hook.

1. **`data-modeling/hooks/directive.sh`** — rewrite the `PRODUCES` arg from
   free text to name the three layers and the two new/clarified components
   explicitly:
   `"PRODUCES (required record fields): conceptual/logical/physical model, ERD, data dictionary, normalization rationale (target form + deviations), migration plan (with rollback path)"`
   Still passes `stub-check.sh`'s structural check — this is a value change
   inside the existing 4-arg call, not new logic.
2. **`data-modeling/.claude-plugin/plugin.json`** — update `description` to
   match the new `PRODUCES` wording (kept in sync today; this proposal
   doesn't change that convention).
3. **`README.md`** — add the methodology-fit table from (b) as a new
   section (e.g. "## Methodology"), since `core_role_directive`'s 4-arg
   template has no slot for a decision table — this mirrors how issue-2's
   proposal relocated BOUNDARY CASE to README for the same structural
   reason.
4. **Record-fields enforcement** — core's `record-fields-gate.sh` checks the
   generic contract §20 shape only; it does not know this role's specific
   required components. Two options for phase 2 to choose between, left as
   an open question for phase-2 execution (not blocking this Approve):
   - (i) rely on documentation-only enforcement (README + directive.sh state
     the requirement; no automated gate checks record *content* beyond
     presence) — lowest implementation cost, matches how `normalization
     rationale`/`migration plan` are already unenforced beyond presence
     today;
   - (ii) if stricter enforcement is wanted later, it would require a core-
     level change (a new generic content-check primitive `record-fields-gate.sh`
     could take role-specific keyword lists via env, similar to
     `RECORD_FIELDS_TERMINAL_STATES`) — out of this repo's own `hooks/`
     tree and out of this issue's scope to build unilaterally.
   Recommendation: (i) for this issue's phase 2, since building (ii) would
   mean either a new local gate (fails `stub-check.sh`) or a core-canon
   change (belongs to a separate core-facing issue, not this rulebook's).
5. **No change to `hooks.json`** — no new hooks are introduced; wiring stays
   `SessionStart` → `directive.sh` only, per the canon-stub constraint.

## Net file diff (phase 2 preview, not executed here)

- Rewrite: `data-modeling/hooks/directive.sh` (`PRODUCES` arg value only).
- Edit: `data-modeling/.claude-plugin/plugin.json` (`description`),
  `README.md` (new Methodology section).
- New (phase 2, when a real schema decision arrives): `docs/issue-<n>/reports/data-modeling.md`
  following the required-components list in (b), and its accompanying
  conceptual/logical/physical/ERD/data-dictionary artifacts.
