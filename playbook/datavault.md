---
axis: datavault
rule_count_floor: 10
---

# Data Vault — hubs, links, satellites, raw/business vault split

Decision rules for when to reach for Data Vault 2.0 over Inmon/Kimball,
and how to structure hubs, links, satellites, and the raw/business
vault boundary.

## Rules

1. When ingesting from many source systems with heavy, ongoing schema
   evolution and a hard auditability requirement, choose Data Vault
   over Inmon/Kimball — Data Vault's layered architecture and
   deterministic hash keys are built specifically for multi-source
   ingestion where sources and their schemas keep changing underneath
   the model.
   source: https://erstudio.com/blog/data-vault-modeling/

2. When modeling a business object (customer, product, order), create a
   Hub keyed by its business key — Hubs are the "nouns," holding only
   the business key and load metadata, deliberately separated from any
   descriptive attribute so the identity of the object never has to be
   rebuilt when its attributes change.
   source: https://medium.com/@avigarg010489/data-vault-2-0-made-simple-part-1-fundamentals-explained-892bfcbc4e72

3. When modeling a relationship or transaction between two or more
   Hubs, create a Link — Links are the "verbs" connecting business
   objects, kept structurally separate from both the Hubs and any
   descriptive attribute of the relationship.
   source: https://datavidhya.com/learn/data-modeling-and-warehouse/modern-approaches/data-vault/

4. When a Hub or Link needs descriptive, time-varying attributes,
   attach a Satellite (for a Hub) or a Link Satellite (for a Link's
   relationship-specific attributes) rather than adding columns to the
   Hub/Link itself — a Link Satellite specifically stores the changing
   properties of the relationship the Link represents, keeping the Link
   table itself immutable identity-only.
   source: https://www.tedamoh.com/en/academy/secret-spice/coaching/299-data-vault-link-satellite

5. When a new attribute, relationship, or business rule needs to be
   added to an already-loaded Raw Vault, extend it by adding a new
   Satellite or Link rather than altering or rebuilding existing
   tables — this is the structural payoff of separating nouns/verbs/
   adjectives: history in existing Satellites survives untouched.
   source: https://makingdatameaningful.com/data-vault-hubs-links-and-satellites-with-associated-loading-patterns/

6. When a calculation, derived metric, or soft business rule is needed
   on top of ingested data, place it in the Business Vault layer, never
   by mutating the Raw Vault — the Business Vault exists precisely so
   derived/soft-rule content layers on top without disturbing the Raw
   Vault's "single version of the facts."
   source: https://medium.com/@avigarg010489/data-vault-2-0-made-simple-part-1-fundamentals-explained-892bfcbc4e72

7. When multiple source systems report conflicting descriptive values
   for what is structurally the same business object, do NOT resolve
   the conflict in the Raw Vault Satellites — load both source-tagged
   Satellites as-is, and resolve/standardize the conflict via a Derived
   Satellite in the Business Vault — this is what keeps the Raw Vault
   an unopinionated historical record.
   source: https://medium.com/@avigarg010489/data-vault-2-0-made-simple-part-1-fundamentals-explained-892bfcbc4e72

8. When the project has a single, stable source system and no
   multi-source auditability requirement, do NOT default to Data Vault
   — the hub/link/satellite split trades simplicity for auditability
   and evolvability that a single-source project has no use for;
   over-applying Data Vault here just adds join fan-out with no payoff.
   source: https://erstudio.com/blog/data-vault-modeling/

9. REMOVAL: when a Satellite tracks an attribute that no source system
   has updated since initial load and no downstream consumer reads its
   history, collapse it into the parent Hub/Link's initial-load record
   and drop the Satellite — an unchanging, unread Satellite adds a join
   and a table to maintain for an attribute that is, in practice,
   static; this mirrors the general finding that additive structure
   (an unused Satellite) is easier to leave in place than to notice and
   remove, so it must be actively checked for, not left as default.
   source: https://www.tedamoh.com/en/academy/secret-spice/coaching/299-data-vault-link-satellite
   source: https://www.nature.com/articles/s41586-021-03380-y (Adams, Converse, Hales & Klotz, *Nature* 592, 2021, "People systematically overlook subtractive changes" — the general bias toward retaining unnecessary additive structure this rule counteracts)

10. REMOVAL: when a Business Vault Derived Satellite duplicates a
    calculation that a downstream BI tool/semantic layer already
    computes natively, delete the Derived Satellite rather than
    maintaining the same logic twice — Business Vault content should
    fill a gap the consumption layer can't fill itself, not shadow
    logic that already lives downstream.
    source: https://medium.com/@avigarg010489/data-vault-2-0-made-simple-part-1-fundamentals-explained-892bfcbc4e72

11. When choosing hash keys vs. sequence keys for Hub/Link business
    keys, use deterministic hash keys when loads happen in parallel
    across multiple independent pipelines — Data Vault 2.0's
    deterministic hashing lets independently-running loaders compute
    the same key for the same business key without a shared
    sequence-generator bottleneck.
    source: https://techcommunity.microsoft.com/blog/analyticsonazure/advanced-data-vault-2-0-models-on-synapse-data-warehouse-in-microsoft-fabric/4038713
