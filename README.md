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

Every phase-2 deliverable must also state its grain and constraints as
at least one machine-checkable assertion (a `not_null`/`unique`/
`relationships`-style column check, a row-count or referential-integrity
check, or an equivalent executable assertion) — prose normalization
rationale alone does not satisfy this norm; the assertion is what a
reviewer or gate actually runs, not just reads.

Any ERD/diagram artifact a deliverable ships must be reproducible from
its own source: either generated directly from the DDL/migration it
accompanies, or committed as a diffable text format (e.g. DBML or an
equivalent markup) alongside the migration it documents. A standalone
image with no reproducible source does not satisfy this norm.

For the Data Vault row specifically, hub/link/satellite columns follow
a fixed naming floor so artifacts from different deliverables stay
structurally comparable: hash keys as `<entity>_hk`, hash diffs (on
satellites) as `<entity>_hd`, and load metadata as `load_date` +
`record_source` at minimum. A deliverable may add columns but must not
rename or drop these four.

### Tool-learnings (Claude Code plugins)

Bounded fold-in from a Claude Code plugin/skill-ecosystem survey
(issue-1199, 2026-08-14 amendment; adoption-evidence method — stars,
multi-source mentions). Each entry: tool, adoption evidence, problem,
how, and which rule above it upgrades. This section stays capped at
four entries; a fifth candidate replaces the weakest existing one
rather than growing the list.

1. **anthropics/claude-plugins-official** (33,504 GitHub stars —
   `gh api repos/anthropics/claude-plugins-official`, checked
   2026-08-14) — its bundled "Data Engineering for Apache Airflow" and
   "Google Cloud Data Engineering" plugins. Problem: migrations authored
   in isolation lose lineage/impact visibility. How: both plugins ship
   lineage-tracing and table-profiling as first-class commands
   alongside migration authoring, not as a separate manual step.
   Learning → upgrades the machine-checkable-assertion rule above: a
   migration's assertion set must include at least one referential/
   lineage-impact check (what downstream reads this table), not only
   local `not_null`/`unique` checks.

2. **rohitg00/awesome-claude-code-toolkit** (2,501 stars —
   `gh api repos/rohitg00/awesome-claude-code-toolkit`, checked
   2026-08-14), specifically its `schema-designer` plugin's
   `generate-erd` command. Problem: hand-drawn ERDs drift from the
   schema they document. How: generates a Mermaid ERD directly from
   live DB/ORM models/migrations into a diffable `docs/erd.md`, so the
   diagram regenerates instead of being hand-maintained. Learning →
   sharpens the reproducible-ERD rule above: the default diffable
   format is Mermaid (or DBML) committed at a fixed path alongside the
   migration, not an arbitrary text format left to the deliverable.

3. **Prisma ORM Development skill** (multi-source: listed on
   claudedirectory.org, mcpmarket.com, and superchargeclaudecode.com —
   checked 2026-08-14; Prisma itself is a widely-adopted TypeScript
   ORM). Problem: a schema and its consuming type-safe client drift
   apart when the client isn't regenerated with the schema change. How:
   couples schema edits to an atomic type-safe client/migration
   regeneration step rather than treating codegen as a manual follow-up.
   Learning → new rule: every phase-2 schema deliverable must name its
   consuming codegen/type-safe boundary (what regenerates from this
   schema, e.g. an ORM client or a typed query layer) so drift surfaces
   at build time, not at review time.

4. **jeremylongshore/claude-code-plugins-plus-skills** (2,630 stars —
   `gh api repos/jeremylongshore/claude-code-plugins-plus-skills`,
   checked 2026-08-14), representative of the marketplace's database-
   migration skill pattern (paired with MariaDB's own skills repo for
   the same pattern). Problem: forward-only migrations leave rollback
   as an afterthought, undermining the rollback path this rulebook's
   `produces` line already promises. How: these skills generate a
   rollback script paired with every forward migration script as one
   atomic artifact, not a prose rollback plan. Learning → new rule:
   a migration plan's rollback path must be a runnable script/step
   committed alongside the forward migration, not prose describing how
   to roll back; "revert this commit" alone satisfies it only when the
   commit contains no data-destructive step.

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
