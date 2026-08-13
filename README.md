# data-modeling-rulebook

Rulebook for the `data-modeling` role (contract v3 role-handoff protocol), split off
per `docs/issue-160/proposals/role-taxonomy.md`'s round-3 promotion and
generated as skeleton scaffolding by issue-170.

- **decides**: 데이터를 어떤 관계/스키마로 모델링할지
- **use_when**: 스키마 신설/변경이 걸릴 때
- **produces**: conceptual/logical/physical model, ERD, data dictionary,
  normalization rationale (target form + deviations), migration plan
  (with rollback path)
- **write_scope**: ["src/**"] (migrations only)
- **hand-off**: 파이프라인 이동/변환이 걸리면 → data-engineering

## Methodology

Phase-1 proposals for schema/relationship decisions must name which row
applies and why (see `docs/issue-1/proposals/rulebook-maturation.md`):

| Decision shape | Methodology |
|---|---|
| OLTP / transactional schema, single source of truth | 3NF-normalized, Inmon-style subject-oriented modeling |
| Analytics / reporting / BI consumption | Kimball dimensional modeling (star/snowflake, fact + dimension tables) |
| Raw multi-source ingestion, heavy schema evolution, auditability requirement | Data Vault (hubs/links/satellites) |

Every phase-2 deliverable must produce conceptual, logical, and physical
model artifacts (or an explicit, justified statement of which layer(s) a
specific change doesn't touch) — a deliverable that jumps straight to
physical DDL with no conceptual/logical trace does not satisfy this norm.

### Spec fields

Layered onto this rulebook from the realized marketplace spec
`roles/specs/data-modeling.spec.json` (program #521-#525, on-the-record).
Every phase-2 record (`docs/issue-<n>/reports/data-modeling.md`) must
carry these four required fields:

| Field | Type/enum |
|---|---|
| `table_name` | string |
| `table_type` | `fact` \| `dimension` \| `n/a` (Inmon/Data-Vault records, which have no fact/dimension distinction, must still declare `n/a` explicitly rather than omit the field) |
| `grain` | string |
| `verdict` | `pass` \| `fail` |

`loop_state` vocabulary (spec-exact, no stale/extra states):

| State | Kind | When |
|---|---|---|
| `modeling` | progress | actively drafting conceptual/logical/physical artifacts |
| `reviewing` | progress | artifacts drafted, awaiting review before landing |
| `landed` | terminal | record merged, deliverable complete |
| `grain-undeclared` | refusal | the record cannot state a `grain` — refuse rather than guess one |
| `table-unreachable` | error | the target table/schema cannot be reached to verify against (e.g. connection/permission failure) |

## Install

```
claude plugin marketplace add tokenmaxxxer/data-modeling-rulebook
claude plugin install data-modeling
claude plugin install data-modeling-structure
claude plugin install data-modeling-inmon
claude plugin install data-modeling-kimball
claude plugin install data-modeling-datavault
claude plugin install core@tokenmaxxxer-core
claude plugin install warrant@tokenmaxxxer-core
```

`core@tokenmaxxxer-core` is a hard dependency of the four gate plugins below
(they source `core/hooks/lib/gate-lib.sh` — never vendored locally, per
`docs/handbooks/canon-scripts.md`) — install it before enabling any gate.

## Layout

Five plugins, each independently installable/kill-switchable
(`.claude-plugin/marketplace.json`):

- `data-modeling/` — the role itself.
  - `.claude-plugin/plugin.json` — plugin manifest
  - `hooks/hooks.json` — `SessionStart` wiring
  - `hooks/directive.sh` — `SessionStart` role directive (core-canon stub)
- `data-modeling-structure/` — methodology-agnostic phase-shape gate.
  - `hooks/structure-gate.sh` — `PreToolUse` on `Write|Edit|MultiEdit|Bash`,
    scoped to `docs/issue-<n>/proposals/*.md` and
    `docs/issue-<n>/reports/data-modeling.md`. A `Bash` write reaching an
    in-scope path is content-blind: denied outright (use Write/Edit
    instead), never reconstructed-and-checked. Kill switch:
    `DATA_MODELING_STRUCTURE_GATE_OFF`.
- `data-modeling-inmon/` — Inmon/3NF methodology content gate (fires only
  when the write names `inmon`/`3nf`).
  - `hooks/inmon-gate.sh`. Kill switch: `DATA_MODELING_INMON_GATE_OFF`.
- `data-modeling-kimball/` — Kimball dimensional/star-schema methodology
  content gate (fires only when the write names
  `kimball`/`dimensional model`/`star schema`).
  - `hooks/kimball-gate.sh`. Kill switch: `DATA_MODELING_KIMBALL_GATE_OFF`.
- `data-modeling-datavault/` — Data Vault methodology content gate (fires
  only when the write names `data vault`).
  - `hooks/datavault-gate.sh`. Kill switch: `DATA_MODELING_DATAVAULT_GATE_OFF`.
- `playbook/` — operational decision-rule content (issue #1174): one
  file per decision axis — `structure.md`, `inmon.md`, `kimball.md`,
  `datavault.md` — each a condition -> choice -> source rule table with
  a front-matter `axis:`/`rule_count_floor:` pair.
- `docs/specs/approvers.md` — Approve-authority allowlist (see below)
- `tests/run-all-gate-tests.sh` — aggregator: runs all four gate plugins'
  own test suites plus core's `compliance-check.sh` against each
  (`docs/handbooks/run-all-gate-tests.md`).

Every kill switch above recognizes only `1`/`true`/`yes`/`on`
(case-insensitive) as "disable" — any other value, including a typo, keeps
the gate active (gate-house standard, core issue-72).

The role-agnostic gates (trailer/record-fields/handbook-trigger) and the
warrant-hunt agent are core canon (core issue #63/#66): fired/installed
globally by `core@tokenmaxxxer-core` and `warrant@tokenmaxxxer-core` — this
repo carries no local copy of either, nor of `gate-lib.sh`/`gate-lib.py`
(canon-reference-only, never vendored).

BOUNDARY CASE: if the work in front of you drifts outside `decides` above,
stop and hand off per the arrow — do not silently absorb another role's
scope. Record the hand-off point in this role's record before opening the
next role's session.
