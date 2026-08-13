---
axis: structure
rule_count_floor: 10
---

# Structure — normalization, keys, and index design

Methodology-agnostic decisions that apply before choosing Inmon,
Kimball, or Data Vault: what normal form to target, when to break it,
and how to key and index the result.

## Rules

1. When the target is an OLTP/transactional table whose writes must
   stay consistent under concurrent updates, normalize to 3NF (every
   non-key attribute depends on the key, the whole key, and nothing but
   the key) — 3NF keeps each fact in exactly one place so INSERT/UPDATE
   touches one row and locks stay narrow.
   source: https://www.velodb.io/glossary/normalization-vs-denormalization

2. When a table has two or more overlapping composite candidate keys
   (a determinant that is not itself a full candidate key), push past
   3NF to BCNF — 3NF alone still allows anomalies from overlapping
   composite keys; BCNF requires every determinant to be a superkey.
   source: https://www.scaler.com/topics/bcnf-in-dbms/

3. When read-path latency is the measured bottleneck (not a guess) on a
   normalized OLTP table, denormalize selectively — duplicate or
   pre-join only the specific columns the slow query needs, after query
   profiling identifies the bottleneck, not before.
   source: https://www.techmixing.com/2025/12/database-normalization-vs-denormalization-when-to-use-each.html

4. REMOVAL: when a normalized schema has a join path that no current or
   planned query traverses, drop that relationship's supporting index
   and any denormalized copy of columns kept "for that join" — an
   unused join path is dead schema weight, not future-proofing; keeping
   it costs write-time index maintenance for zero read benefit.
   source: https://www.solarwinds.com/database-optimization/normalize-vs-denormalize-database
   source: https://www.nature.com/articles/s41586-021-03380-y (Adams, Converse, Hales & Klotz, *Nature* 592, 2021 — schema authors systematically default to additive fixes and overlook subtractive ones without a deliberate removal check)

5. When no natural attribute is both guaranteed-unique and immutable
   for an entity, assign a surrogate key (system-generated, no business
   meaning) as the primary key — a 4-byte integer/UUID surrogate joins
   and indexes faster than a wide or composite natural key, and never
   forces a cascading key change when a business attribute is corrected.
   source: https://www.baeldung.com/sql/keys-natural-vs-surrogate

6. When a natural key exists and is stable, still enforce it as a
   UNIQUE constraint alongside the surrogate primary key rather than
   dropping it — this keeps the business-rule integrity a natural key
   provides while the surrogate carries the join/index performance.
   source: https://www.analyticsengineering.com/resources/surrogate-vs-natural-keys-choosing-the-right-primary-key

7. When a composite natural key is used as a foreign key on a child
   table, index the leading column(s) applications actually filter by,
   not the full composite — queries filtering on only part of a
   composite key do not benefit from an index that requires the full
   key prefix to be useful.
   source: https://www.mssqltips.com/sqlservertip/5431/surrogate-key-vs-natural-key-differences-and-when-to-use-in-sql-server/

8. REMOVAL: when a table's history shows a candidate index has not
   served a query plan in the lookback window your platform's
   query-stats view supports, drop the index rather than retaining it
   speculatively — every index adds write-side maintenance cost that
   only pays for itself against a real read pattern.
   source: https://www.mssqltips.com/sqlservertip/5431/surrogate-key-vs-natural-key-differences-and-when-to-use-in-sql-server/

9. When producing any schema/relationship deliverable, declare
   conceptual, logical, and physical model layers explicitly (or state
   which layer(s) don't apply and why) — DAMA-DMBOK treats these as
   three distinct, traceable levels (conceptual: stakeholder-level
   entities/relationships; logical: full attribute/relationship detail;
   physical: the actual DDL), and a deliverable that jumps straight to
   physical DDL loses the traceability back to the business concept a
   reviewer needs to audit the design.
   source: https://medium.com/dama-dmbok-data-modeling/dama-dmbok-data-modeling-introduction-8a7906c1c59d

10. When two components across model layers represent the same
    business concept (e.g. a physical `MobileDevice` table and its
    conceptual `Product` entity), record the lineage link between them
    explicitly in the data dictionary — DAMA-DMBOK's model-lineage
    practice is what lets a later "why does this column exist" question
    resolve back to the originating business concept instead of forcing
    re-derivation.
    source: https://medium.com/dama-dmbok-data-modeling/dama-dmbok-deliverables-steps-of-the-data-modeling-process-5cdc4b33ecf

11. REMOVAL: when a conceptual-model entity has no corresponding
    logical or physical artifact after a schema has shipped, either
    build the missing layer or delete the orphaned conceptual entity —
    an entity that exists only in the conceptual model with no
    downstream trace is a stale artifact, not documentation, and
    misleads a reviewer into thinking it was implemented.
    source: https://medium.com/dama-dmbok-data-modeling/dama-dmbok-data-modeling-introduction-8a7906c1c59d

12. When justifying a decision to stop short of full normalization on a
    specific table, state the measured cost you're avoiding (read
    latency, join fan-out) and the specific normalization step skipped
    — an unjustified denormalization is functionally identical to an
    unmodeled table and forfeits BCNF's anomaly protection with no
    record of what was traded for what.
    source: https://www.digitalocean.com/community/tutorials/database-normalization
