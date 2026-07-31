---
Subject: issue-7
---

# Record — plugin set for methodology enforcement (phase 2)

loop_state: landed

## What was done

Executed the approved phase-1 proposal
(`docs/issue-7/proposals/methodology-enforcement.md`, approved via the
issue comment `APPROVE issue-7/data-modeling`, single-account mode per
`docs/specs/approvers.md`) exactly per its plugin list:

1. Added `data-modeling-structure/` — the methodology-agnostic phase-shape
   gate (`hooks/structure-gate.sh`, `PreToolUse` on `Write`, scoped to
   `docs/issue-<n>/proposals/*.md` and `docs/issue-<n>/reports/data-modeling.md`).
   Checks the five proposal elements and three record elements from the
   proposal's sections 3-4, plus the `decides`-boundary hand-off check from
   section 5. Fail-closed on unparseable in-scope input; kill switch
   `DATA_MODELING_STRUCTURE_GATE_OFF`. Own test suite,
   `tests/structure-gate-tests.sh`, 10 allow/deny cases.
2. Added `data-modeling-inmon/`, `data-modeling-kimball/`,
   `data-modeling-datavault/` — one plugin per methodology, each firing its
   own `PreToolUse` gate only when its own methodology token is present in
   the write content (independent detection, no shared state with
   `data-modeling-structure` or each other). Each checks the
   methodology-specific criterion from the proposal's sections 3-4 (Inmon:
   normalization target / deviations; Kimball: grain statement / fact-
   dimension split; Data Vault: hub/satellite/link + auditability
   rationale / hub-satellite-link in records). Each has its own kill
   switch (`DATA_MODELING_{INMON,KIMBALL,DATAVAULT}_GATE_OFF`) and its own
   test suite (7-9 cases each).
3. Registered all four new plugins in `.claude-plugin/marketplace.json`
   alongside the existing `data-modeling` entry, each `source` pointing at
   its own top-level directory — matches the proposal's section 6 and the
   `tokenmaxxxer-core` `core`/`terse`/`freelunch`/`scout` sibling-listing
   precedent cited in the scout brief.
4. Added `tests/run-all-gate-tests.sh` (repo root) — sources and runs all
   four plugin test suites, mirroring `core`'s aggregator pattern per the
   proposal's section 7.
5. No change to `data-modeling/hooks/directive.sh` or `plugin.json` — its
   `PRODUCES` line already names the five record components from issue-1;
   these plugins enforce them, they don't restate them (proposal section
   9). No `core/hooks/*` file touched or copied — every new gate is
   original role-owned content, not a vendored copy of a core script, so
   the canon-reference-only constraint from issue-2's record
   (`docs/issue-2` — no local copies of core-owned generic gates) is
   unaffected.

## Why

The approver's phase-1 correction (issue-7 comment) rejected the prior
single-directive/single-gate draft and required a plugin *set*: one
self-contained plugin per adopted methodology, matching the
`core`/`freelunch`/`scout` shape where a rulebook is several independently
enable/disable-able plugins rather than one monolith. The proposal's
section 2 argues this concretely: the methodology-agnostic *shape* check
(steps 1-5, layers, alternatives) has a different lifetime than
what-counts-as-"done" per methodology (Inmon's 3NF+deviations vs.
Kimball's grain+fact/dimension vs. Data Vault's hub/satellite/link+
auditability) — splitting them means a future fourth methodology is a new
plugin registration, not a growing if/elif chain in one script. This
record reflects that approved plan into five live plugins (one existing,
four new), each independently testable and independently kill-switchable.

## Upstream basis

- `docs/issue-7/proposals/methodology-enforcement.md` (this repo, approved
  via issue-7 comment `APPROVE issue-7/data-modeling`)
- `docs/issue-7/reports/data-modeling/survey.md`,
  `docs/issue-7/reports/data-modeling/scout-brief.md` (phase-1 evidence
  base the proposal cites)
- `docs/issue-1/reports/data-modeling.md` (prior phase-2 record — the
  three-layer/ERD/data-dictionary/normalization/migration norm these
  gates now enforce)

## Conceptual / logical / physical model artifacts

Not applicable this iteration — issue-7's phase 2 is a rulebook
enforcement-tooling change (gate plugins), not a schema/relationship
decision. No entities, attributes, or DDL are introduced or changed.

## Normalization rationale

Not applicable — no schema changed in this issue.

## Migration plan

Not applicable — no schema changed in this issue; nothing to migrate or
roll back.

## Gate tests (verification)

`bash tests/run-all-gate-tests.sh` — all four suites pass:
`structure-gate-tests: all passed` (10 cases),
`inmon-gate-tests: all passed` (9 cases),
`kimball-gate-tests: all passed` (7 cases),
`datavault-gate-tests: all passed` (9 cases).

## Net file diff (as executed)

- New `data-modeling-structure/` (`.claude-plugin/plugin.json`,
  `hooks/structure-gate.sh`, `hooks/hooks.json`,
  `tests/structure-gate-tests.sh`, `README.md`).
- New `data-modeling-inmon/` (same shape, `inmon-gate.sh`).
- New `data-modeling-kimball/` (same shape, `kimball-gate.sh`).
- New `data-modeling-datavault/` (same shape, `datavault-gate.sh`).
- Edited `.claude-plugin/marketplace.json` (+4 plugin entries).
- New `tests/run-all-gate-tests.sh` (aggregator).
- New `docs/issue-7/reports/data-modeling.md` (this record).

## Open findings

None — the proposal's plugin list, combination rules, marketplace
registration, test shape, and kill-switch naming are all executed as
specified with no deviation.
