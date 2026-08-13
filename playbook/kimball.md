---
axis: kimball
rule_count_floor: 10
---

# Kimball — dimensional modeling, star schema, SCD selection

Decision rules for fact/dimension design, grain declaration, and
slowly-changing-dimension (SCD) type selection under Ralph Kimball's
bus architecture.

## Rules

1. When starting any fact table design, declare the grain (the exact
   business event/measurement one row represents) before adding a
   single column — the star schema's fact table records business
   events at a declared grain, and every dimension and measure choice
   downstream depends on that grain being fixed first.
   source: https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/star-schema-olap-cube/

2. When a dimension attribute must reflect the value at the time of the
   fact event and history has no business value, use SCD Type 1
   (overwrite) — Type 1 is correct exactly when no historical trace of
   the prior value is needed, not as a universal default.
   source: https://en.wikipedia.org/wiki/Slowly_changing_dimension

3. When a dimension attribute change must be attributable to specific
   historical facts (e.g. "which region was this customer in when this
   order was placed"), use SCD Type 2 (new row + effective-dated
   validity) — Type 2 is the only SCD type that preserves full
   point-in-time history joinable to facts.
   source: https://www.holistics.io/blog/scd-cloud-data-warehouse/

4. When only the immediately-prior value of an attribute matters (not
   full history), use SCD Type 3 (add a "previous value" column)
   instead of Type 2 — Type 3 is bounded by the number of columns
   reserved for history, so it only fits when the business need is "one
   step back," not an unbounded audit trail.
   source: https://en.wikipedia.org/wiki/Slowly_changing_dimension

5. When different attributes of the SAME dimension have different
   history requirements (e.g. customer email changes need no history,
   customer region changes need full history), apply SCD type per
   attribute, not per dimension — SCD handling is an attribute-level
   decision, so one dimension can mix Type 1 on one column and Type 2 on
   another.
   source: https://www.holistics.io/blog/scd-cloud-data-warehouse/

6. When two or more data marts must support cross-functional queries
   spanning different business processes, build the shared dimensions
   as conformed dimensions (identical structure/keys/values across
   marts) — conformed dimensions are Kimball's integration mechanism in
   place of a centralized normalized repository, so an unconformed
   duplicate dimension breaks cross-mart analysis.
   source: https://medium.com/@goyalarchana17/data-warehouse-architecture-approaches-inmon-vs-kimball-0bd8f04bb5cf

7. When the project needs a fast, narrow win on one business process
   rather than an enterprise-wide model, build that process's data mart
   bottom-up first (Kimball's approach) and integrate marts later via
   conformed dimensions — the bottom-up order is the point: build the
   mart, then broaden, rather than waiting on a central warehouse.
   source: https://www.ismll.uni-hildesheim.de/lehre/bi-10s/script/Inmon-vs-Kimball.pdf

8. REMOVAL: when a dimension attribute currently tracked at SCD Type 2
   has never once been queried for its historical value across the
   lookback window your BI platform's usage logs cover, collapse it to
   Type 1 — carrying unused Type 2 history multiplies row count and
   join complexity for a history nobody reads.
   source: https://en.wikipedia.org/wiki/Slowly_changing_dimension
   source: https://www.nature.com/articles/s41586-021-03380-y (Adams, Converse, Hales & Klotz, *Nature* 592, 2021 — the SCD type applied at dimension creation tends to stay by default rather than being periodically re-checked for removal)

9. REMOVAL: when a fact table carries a degenerate or junk dimension
   column that duplicates an attribute already available via a
   conformed dimension join, drop the duplicated column from the fact
   table — Kimball's own technique catalog (junk/degenerate dimensions)
   exists for attributes that genuinely have no home dimension, not as
   license to duplicate a joinable attribute onto the fact row.
   source: https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/star-schema-olap-cube/

10. When a reporting requirement needs drill-down through a
    hierarchical attribute set that is rarely queried and rarely
    changes, prefer a snowflaked (normalized) branch of that one
    dimension over flattening it into the star — snowflaking trades
    query-time join cost for storage/update efficiency, which is the
    right trade only for low-cardinality-change, low-query-frequency
    hierarchies, not the whole schema.
    source: https://datadef.io/guides/en/dimensional-modeling

11. When choosing between Type 6 (hybrid: overwrite + add-column +
    new-row combined) and a plain Type 2 for a dimension attribute,
    reserve Type 6 for the case where BOTH "current value on old facts"
    and "full history" are simultaneously required — Type 6 exists
    specifically to serve both query patterns from one dimension row
    set; applying it when only one pattern is needed adds schema
    complexity with no corresponding query benefit.
    source: https://www.holistics.io/blog/scd-cloud-data-warehouse/
