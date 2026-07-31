---
Subject: issue-7
---

# Proposal — plugin set for methodology enforcement in `data-modeling` (phase 1)

Phase 1 only. No plugin/test edits in this PR — this document is the plan
phase 2 will execute once approved (`APPROVE issue-7/data-modeling`,
single-account mode per `docs/specs/approvers.md`).

Backed by `docs/issue-7/reports/data-modeling/survey.md` (current-state
gaps) and `docs/issue-7/reports/data-modeling/scout-brief.md` (sibling
rulebook precedent). Revised per the approver's phase-1 feedback on PR #8:
the prior draft deepened one directive + one monolithic gate; this draft
restructures the same enforcement content into an explicit **plugin set**
— one independent plugin per adopted methodology, plus phase-1/phase-2
norms expressed as which plugins combine, matching the `core`/`freelunch`/
`scout` precedent (a rulebook is several self-contained plugins, not one).

## 1. Plugin list (required)

| Plugin | Methodology owned | Components | Registration |
|---|---|---|---|
| `data-modeling` (existing) | role identity itself — decides/use_when/produces/hand-off | `hooks/directive.sh` (`SessionStart`), `hooks/hooks.json` | already in `./.claude-plugin/marketplace.json` |
| `data-modeling-structure` (new) | phase-shape, methodology-agnostic — the step order + required sections every proposal/record must have regardless of which methodology fits | `hooks/structure-gate.sh` (`PreToolUse`, path-scoped to this role's proposal/record surfaces), `hooks/hooks.json`, own `tests/structure-gate-tests.sh` | new entry in `./.claude-plugin/marketplace.json`, `source: "./data-modeling-structure"` |
| `data-modeling-inmon` (new) | Inmon/3NF — transactional-source-of-truth schemas | `hooks/inmon-gate.sh` (`PreToolUse`, fires only when structure-gate has already matched a methodology-fit line naming `inmon`/`3nf`), `tests/inmon-gate-tests.sh` | new entry, `source: "./data-modeling-inmon"` |
| `data-modeling-kimball` (new) | Kimball dimensional/star-schema — BI/reporting consumption | `hooks/kimball-gate.sh` (fires on `kimball`/`dimensional model`/`star schema`), `tests/kimball-gate-tests.sh` | new entry, `source: "./data-modeling-kimball"` |
| `data-modeling-datavault` (new) | Data Vault — raw multi-source ingestion under schema drift | `hooks/datavault-gate.sh` (fires on `data vault`), `tests/datavault-gate-tests.sh` | new entry, `source: "./data-modeling-datavault"` |

Each methodology plugin is self-contained (own `.claude-plugin/plugin.json`,
own `hooks/`, own `tests/`) and owns exactly one methodology's checks —
the same shape as `core`'s `freelunch`/`scout`: independently
enable/disable-able, independently testable, no shared mutable state
between them. None vendors a copy of `core/hooks/*` (canon-reference-only,
`docs/handbooks/canon-scripts.md` unchanged).

## 2. Why five plugins, not one gate

The rejected prior draft folded "which methodology fits" and "did the
methodology's own required elements show up" into one script's five
generic element-checks (`methodology-fit-named`, `layers-named`, …). That
conflates two different lifetimes: the **shape** every proposal/record
must have (steps 1–5, layers, alternatives — true regardless of which
methodology this decision uses) is stable across all three adopted
methodologies, while **what counts as "done" for Inmon** (3NF + deviations
named) is not the same content check as **what counts as "done" for
Kimball** (dimensional model + grain statement) or **Data Vault** (hub/
satellite/link vocabulary + auditability rationale). Splitting them into
separate plugins means adding a fourth methodology later (e.g. Anchor
Modeling) is a new plugin registration, not an edit to a growing
if/elif chain inside one script — the same reason `core` ships `scout` and
`freelunch` as separate plugins instead of one "role behavior" plugin.

## 3. Phase 1 (proposal) norm = plugin combination

The proposal-writing norm is not a single artifact; it is what fires when
**`data-modeling-structure`'s proposal gate always runs, plus exactly one
methodology plugin's proposal gate runs conditionally** on which fit the
author named:

- `data-modeling-structure/hooks/structure-gate.sh` (always, on any write
  to `docs/issue-<n>/proposals/*.md` under `CLAUDE_ROLE=data-modeling`):
  checks the methodology-agnostic shape —
  1. `survey-referenced` (must name `docs/issue-<n>/reports/data-modeling/survey`).
  2. `layers-named` (at least one of conceptual/logical/physical).
  3. `alternatives-considered`.
  4. `open-questions`.
  5. `methodology-fit-named` — exactly one of `inmon`/`3nf`, `kimball`/
     `dimensional model`/`star schema`, `data vault`, **or** an explicit
     no-fit statement (`no schema decision`, `routed to`).
- Whichever methodology token element 5 matched, that methodology
  plugin's own proposal gate runs next in the same `PreToolUse` batch and
  checks its methodology-specific criterion:
  - `data-modeling-inmon`: normalization target (`1nf`..`bcnf`) named as
    the *intended* form, not just mentioned.
  - `data-modeling-kimball`: a grain statement (`grain:` or `grain is`)
    present.
  - `data-modeling-datavault`: at least one of `hub`/`satellite`/`link`
    named alongside an auditability or schema-drift rationale.
- A no-fit statement short-circuits: no methodology plugin fires (nothing
  to check), matching the escape hatch pattern from the prior draft's
  gate design.

The proposal is complete only when the structure gate's five elements
**and** the matched methodology plugin's own element all pass — the norm
*is* this combination, not a single script's checklist.

## 4. Phase 2 (record) norm = plugin combination

Same shape, on `docs/issue-<n>/reports/data-modeling.md`:

- `data-modeling-structure/hooks/structure-gate.sh` (always):
  1. `layers-or-justified-skip` (conceptual/logical/physical all named, or
     fewer + explicit skip justification).
  2. `data-dictionary` (named as a section distinct from ERD).
  3. `migration-rollback` (`migration plan` + `rollback`).
- The methodology plugin matching the proposal's already-decided fit
  (read back from the approved proposal file, not re-decided) runs its
  record-side check:
  - `data-modeling-inmon`: normalization rationale states deviations *or*
    "no deviations" explicitly (never silent).
  - `data-modeling-kimball`: fact/dimension table split named.
  - `data-modeling-datavault`: hub/satellite/link structure named in the
    record, matching what the proposal committed to.

## 5. Hand-off facet (unchanged, methodology-agnostic — belongs to `data-modeling-structure`)

The `decides`-boundary check (schema-shape decisions vs. pipeline-movement
scope, hand-off to `data-engineering`) is not methodology-specific — it
lives in `data-modeling-structure`'s gate as a role-boundary check, not in
any of the three methodology plugins.

## 6. Marketplace registration (phase-2 preview)

`./.claude-plugin/marketplace.json` gains four entries (`data-modeling-
structure`, `-inmon`, `-kimball`, `-datavault`) alongside the existing
`data-modeling` entry, each `source` pointing at its own top-level
directory — mirrors `tokenmaxxxer-core`'s marketplace listing `core`,
`terse`, `freelunch`, `scout` as siblings.

## 7. Gate tests (phase-2 preview)

Each plugin ships its own `tests/<plugin>-gate-tests.sh` (own allow/deny
cases for its own script only) — no single shared test file spanning all
five, matching "each plugin independently testable." A repo-root
`tests/run-all-gate-tests.sh` (new) sources and runs all five, mirroring
core's `run-role-gates-tests.sh` aggregator pattern.

## 8. Kill switches

Each plugin's own gate honors its own namespaced kill switch:
`DATA_MODELING_STRUCTURE_GATE_OFF`, `DATA_MODELING_INMON_GATE_OFF`,
`DATA_MODELING_KIMBALL_GATE_OFF`, `DATA_MODELING_DATAVAULT_GATE_OFF` —
independently disable-able, consistent with "self-contained."

## 9. Net file diff (phase 2 preview, not executed here)

- New dir `data-modeling-structure/` (`.claude-plugin/plugin.json`,
  `hooks/structure-gate.sh`, `hooks/hooks.json`, `tests/structure-gate-tests.sh`).
- New dir `data-modeling-inmon/` (plugin.json, `hooks/inmon-gate.sh`,
  `hooks/hooks.json`, `tests/inmon-gate-tests.sh`).
- New dir `data-modeling-kimball/` (same shape, kimball-gate.sh).
- New dir `data-modeling-datavault/` (same shape, datavault-gate.sh).
- Edit `./.claude-plugin/marketplace.json` (+4 plugin entries).
- New `tests/run-all-gate-tests.sh` (aggregator).
- No change to `data-modeling/hooks/directive.sh` (role identity plugin
  untouched — its `PRODUCES` line already names the five record
  components from issue-1; the new plugins enforce them, they don't
  restate them).
- No `core/hooks/` file touched or copied (canon-reference-only preserved).
