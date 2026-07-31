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

## Install

```
claude plugin marketplace add tokenmaxxxer/data-modeling-rulebook
claude plugin install data-modeling
claude plugin install warrant@tokenmaxxxer-core
```

## Layout

- `data-modeling/.claude-plugin/plugin.json` — plugin manifest
- `data-modeling/hooks/hooks.json` — SessionStart wiring
- `data-modeling/hooks/directive.sh` — SessionStart role directive (core-canon stub)
- `docs/specs/approvers.md` — Approve-authority allowlist (see below)

The role-agnostic gates (trailer/record-fields/handbook-trigger) and the
warrant-hunt agent are core canon now (core issue #63/#66): fired/installed
globally by `core@tokenmaxxxer-core` and `warrant@tokenmaxxxer-core` — this
repo carries no local copy of either.

This is scaffolding, not a finished rulebook: fill in doctrine detail,
handoff enforcement, and any role-specific progress gate before treating
it as load-bearing.

BOUNDARY CASE: if the work in front of you drifts outside `decides` above,
stop and hand off per the arrow — do not silently absorb another role's
scope. Record the hand-off point in this role's record before opening the
next role's session.
