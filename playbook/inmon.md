---
axis: inmon
rule_count_floor: 10
---

# Inmon — subject-oriented, 3NF enterprise warehouse modeling

Decision rules for when and how to apply Bill Inmon's top-down,
subject-oriented, centrally-normalized warehouse methodology, as
distinct from Kimball's bottom-up bus architecture.

## Rules

1. When the requirement is a single enterprise-wide source of truth
   that many downstream marts must derive from consistently, model the
   central warehouse in Inmon's subject-oriented style (entities
   grouped by real-world subject — customer, product, order — not by
   department or report) rather than building department-local stars
   directly.
   source: https://medium.com/@goyalarchana17/data-warehouse-architecture-approaches-inmon-vs-kimball-0bd8f04bb5cf

2. When choosing the central warehouse's normal form, target 3NF (not a
   dimensional/star shape) — Inmon's central repository is explicitly
   structured in 3NF so that atomic, non-redundant data feeds every
   downstream mart from one consistent source.
   source: https://www.computerweekly.com/tip/Inmon-or-Kimball-Which-approach-is-suitable-for-your-data-warehouse

3. When the business is stable and can afford longer upfront design
   time and cost, choose Inmon's top-down build — the central warehouse
   is designed once for the whole enterprise before any mart is built,
   which pays off exactly when requirements do not shift under the
   design.
   source: https://www.ismll.uni-hildesheim.de/lehre/bi-10s/script/Inmon-vs-Kimball.pdf

4. When a business condition changes, extend the existing Inmon model
   to accommodate it rather than redesigning — Inmon's practitioner
   guidance is that a changing business condition is absorbed into the
   existing subject-oriented structure, not treated as a trigger to
   re-architect.
   source: https://www.ismll.uni-hildesheim.de/lehre/bi-10s/script/Inmon-vs-Kimball.pdf

5. When a downstream data mart is needed, derive it FROM the central
   3NF warehouse (dimensional marts built only after the enterprise
   warehouse exists) rather than building the mart first and
   back-filling the warehouse from it — building marts before the
   central store inverts Inmon's top-down guarantee that atomic
   enterprise data exists independent of any one mart's shape.
   source: https://medium.com/@goyalarchana17/data-warehouse-architecture-approaches-inmon-vs-kimball-0bd8f04bb5cf

6. When two OLTP source systems feed the same subject area (e.g.
   "customer") with conflicting attribute definitions, resolve the
   conflict once in the central subject-oriented model — Inmon's model
   organizes data so all related elements link to the same real-world
   object, which only holds if conflicting source definitions are
   reconciled centrally instead of per-mart.
   source: https://medium.com/@goyalarchana17/data-warehouse-architecture-approaches-inmon-vs-kimball-0bd8f04bb5cf

7. REMOVAL: when a subject area in the central warehouse has no OLTP
   source system feeding it and no mart consuming it, drop the subject
   area from the model rather than pre-building it speculatively —
   Inmon's warehouse is fed by actual OLTP systems; a subject with
   neither an inbound feed nor a downstream consumer is unmodeled
   scope, not future-proofing.
   source: https://www.computerweekly.com/tip/Inmon-or-Kimball-Which-approach-is-suitable-for-your-data-warehouse
   source: https://www.nature.com/articles/s41586-021-03380-y (Adams, Converse, Hales & Klotz, *Nature* 592, 2021 — modelers default to keeping speculative structure unless removal is an explicit, checked step)

8. When the project needs a fast, narrow win rather than an
   enterprise-wide store, do NOT default to Inmon — the practitioner
   guidance is explicit that Inmon fits stable, well-resourced
   enterprise builds, and a team that needs local optimization quickly
   should reach for Kimball's bottom-up approach instead.
   source: https://www.ismll.uni-hildesheim.de/lehre/bi-10s/script/Inmon-vs-Kimball.pdf

9. REMOVAL: when a data mart derived from the central warehouse
   duplicates an attribute's transformation logic that the central
   model already computes, delete the duplicated logic from the mart
   and reference the central computation — recomputing the same
   derived attribute per mart reintroduces the inconsistency Inmon's
   single-source-of-truth design exists to prevent.
   source: https://www.computerweekly.com/tip/Inmon-or-Kimball-Which-approach-is-suitable-for-your-data-warehouse

10. When documenting an Inmon-methodology deliverable, name which
    subject area(s) the change touches explicitly (not just which
    tables) — subject-orientation is Inmon's organizing principle, so a
    change description that only lists table names loses the
    traceability back to the enterprise subject model the methodology
    is built around.
    source: https://medium.com/@goyalarchana17/data-warehouse-architecture-approaches-inmon-vs-kimball-0bd8f04bb5cf

11. When atomic (lowest-grain, undeleted, unsummarized) data is
    required for a future unknown query, keep it in the Inmon central
    warehouse at full grain rather than only at the mart's pre-aggregated
    grain — Inmon's warehouse stores atomic data at the lowest level of
    detail specifically so a not-yet-anticipated query can still be
    answered without re-ingesting from source.
    source: https://medium.com/@goyalarchana17/data-warehouse-architecture-approaches-inmon-vs-kimball-0bd8f04bb5cf
