---
Subject: issue-1
---

# Scout brief — issue-1 (data-modeling methodology + deliverable norms)

Scope: this is a doctrine question (which textbook/industry norms should this
role's phase-1 proposals and phase-2 deliverables follow), not a product to
benchmark — scouting means a broad literature/standards sweep, not exemplar
apps.

## Sweep (1 stage, 4 parallel angles, saturated on judge point 1)

1. Data-warehouse modeling methodology comparison (Kimball / Inmon / Data Vault).
2. Enterprise data-modeling body-of-knowledge deliverables (DAMA-DMBOK, model layers).
3. Data-model documentation best practice (ERD / data dictionary / normalization).
4. Design-proposal document norms (RFC/technical-design-doc required sections).

All 4 angles converged with no contradiction; a second round would not have
changed any adoption call, so deepening stopped at judge point 1.

## Must-bes (Kano — what the field treats as baseline, not optional)

- **Three model layers are non-negotiable**: conceptual (business
  entities/relationships, stakeholder-facing) → logical (attributes,
  relationships, normalized, platform-independent) → physical (types,
  keys, indexes, partitioning, platform-specific). Every source that
  discussed deliverables treated skipping a layer as a documentation gap,
  not a style choice.
- **Normalization target must be explicit and justified**, not implicit.
  3NF is the default floor for OLTP/transactional schemas; deviations
  (denormalization for a star schema, raw Data Vault hubs/links/satellites)
  must be argued, not assumed.
- **A data dictionary is a distinct artifact from the ERD**, not a caption
  on it — ERD communicates structure/relationships at a glance, data
  dictionary carries per-column detail (type, nullability, meaning,
  constraints). Conflating them was called out as a common mistake.
- **RFC-style proposals require, at minimum**: problem statement (why now),
  proposed design with reasoning/tradeoffs, alternatives considered, and
  open questions/risks. A proposal that jumps straight to "the schema" with
  no alternatives-considered section was treated as under-baked by every
  RFC-template source.

## Performance axes (where strong practice visibly differentiates)

1. **Methodology fit-to-purpose** — the field does not have one winning
   methodology; it has a fit function (Kimball for analytics/BI delivery
   speed, Inmon/3NF for single-source-of-truth OLTP and regulated
   consistency, Data Vault for raw multi-source historized ingestion with
   heavy schema evolution). A rulebook that mandates one methodology for
   every schema decision would be picking a hammer for every screw.
2. **Traceability of the normalization/denormalization call** — strong
   deliverables state the target normal form and name every deliberate
   deviation with a reason; weak ones leave the reader to infer it from the
   DDL.
3. **Alternatives-considered depth** — RFC sources repeatedly flagged
   "one option presented as the only option" as the single most common
   design-doc failure mode.

## Adopt / skip

- **Adopt**: three-layer model requirement (conceptual/logical/physical) as
  the phase-2 deliverable's structural backbone.
- **Adopt**: methodology-selection-by-fit (not a single fixed methodology)
  — the proposal must name the decision rule (OLTP → 3NF/Inmon-style;
  analytics/reporting → Kimball dimensional; raw multi-source ingestion →
  Data Vault), so a future schema decision picks the right one instead of
  the role defaulting to whichever the last modeler happened to know.
- **Adopt**: RFC shape (problem / proposed design+tradeoffs / alternatives
  considered / open questions) for phase-1 proposal norm — matches this
  repo's own contract v3 phase-1/phase-2 split almost exactly already.
- **Adopt**: data dictionary as a separate required component from the ERD.
- **Skip**: mandating a single warehouse methodology (pure Kimball or pure
  Inmon) role-wide — the survey shows this role's `WRITE_SCOPE` is
  `src/**` migrations broadly, not warehouse-only, so a warehouse-specific
  methodology would over-fit a role that also does OLTP schema work.
- **Skip**: inventing a new local gate script to enforce any of this —
  survey confirms this repo carries no local gates post-issue-2; enforcement
  must route through `core_role_directive` args / `RECORD_FIELDS_*` env,
  not a new hook file (would fail `stub-check.sh`).

## Gap line (survey → scout)

Survey found `PRODUCES` names artifacts but no methodology or layer
requirement, and no phase-1 proposal-writing norm exists in this repo for
data-modeling deliverables specifically (issue-2's proposal is an
infra-migration doc, not a schema-design doc). The field's must-bes above —
three layers, explicit normalization target, separate data dictionary,
RFC-shaped proposal — are exactly what's missing; nothing in current state
already satisfies any of them.

Sources:
- https://medium.com/@lgsoliveira/exploring-data-warehouse-modeling-methodologies-kimball-inmon-and-data-vault-c46f0a253190
- https://medium.com/@amarrjoshi/understanding-the-differences-between-inmon-kimball-and-data-vault-data-models-79868aa99525
- https://www.analyticscreator.com/blog/how-to-choose-the-right-data-modeling-techniques-for-your-data-warehouse
- https://medium.com/dama-dmbok-data-modeling/dama-dmbok-deliverables-steps-of-the-data-modeling-process-5cdc4b33ecf
- https://www.damadmbok.org/copy-of-about-dama-dmbok
- https://dataedo.com/blog/er-diagram-vs-data-dictionary-documenting-data-models
- https://opentextbc.ca/dbdesign01/chapter/chapter-12-normalization/
- https://duketechsolutions.com/wp-content/uploads/2022/02/Data-Modeling-Best-Practices.pdf
- https://www.hashicorp.com/en/how-hashicorp-works/articles/rfc-template
- https://betterprogramming.pub/goals-and-failure-modes-for-rfcs-and-technical-design-documents-c4ee1d1da6ff
- https://fuchsia.dev/fuchsia-src/contribute/governance/rfcs/TEMPLATE

Stages used: 1 (sweep, 4 parallel angles) + judge point 1 (saturated, no
deepening round run). Mode: parallel (4 concurrent WebSearch calls in one
turn).
