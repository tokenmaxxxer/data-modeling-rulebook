---
Subject: issue-1
---

# Record — rulebook maturation (phase 2)

loop_state: landed

## What was done

Executed the phase-1 proposal (`docs/issue-1/proposals/rulebook-maturation.md`,
PR against `main`, approved via the issue comment `APPROVE issue-1/data-modeling`)
exactly per its "(d) Plugin reflection plan":

1. Rewrote `data-modeling/hooks/directive.sh`'s `PRODUCES` argument from
   free text (`schema/ERD, migration plan, normalization rationale`) to
   name the three mandatory model layers and the two new/clarified
   components explicitly: `conceptual/logical/physical model, ERD, data
   dictionary, normalization rationale (target form + deviations),
   migration plan (with rollback path)`. No other argument or structure
   changed — still a single `core_role_directive` call, still passes
   `stub-check.sh`'s structural parser.
2. Updated `data-modeling/.claude-plugin/plugin.json`'s `description` to
   match the new `PRODUCES` wording, keeping manifest and directive in
   sync per existing convention.
3. Added a `## Methodology` section to `README.md` carrying the
   methodology-fit decision table (OLTP/Inmon, Analytics/Kimball, raw
   ingestion/Data Vault) and the three-layer requirement, since
   `core_role_directive`'s 4-arg template has no slot for a decision
   table — mirrors how issue-2's proposal relocated BOUNDARY CASE to
   README for the same structural reason. Also updated README's
   `produces` bullet to match the new wording.
4. Record-fields enforcement: adopted option (i) from the proposal —
   documentation-only enforcement via directive.sh + README. No new
   local gate added (would fail `stub-check.sh`'s no-vendored-gates
   check); building a core-level content-check primitive is out of this
   issue's scope, as the proposal states.
5. No change to `hooks.json` — no new hooks introduced, wiring stays
   `SessionStart` → `directive.sh` only, per the canon-stub constraint
   and this issue's warrant-hunter-stays-a-core-reference constraint.

## Why

Phase 1's survey and scout brief (this repo) found the field's near-unanimous
consensus that skipping a conceptual/logical/physical layer, or conflating
ERD with a data dictionary, are documentation gaps rather than style
choices — and found no single fixed warehouse methodology fits this role's
workload-agnostic `WRITE_SCOPE`. The approved proposal resolves both by
(a) making all three layers mandatory record components and (b) a
methodology-fit table keyed to decision shape instead of one committed
style. This record reflects that approved plan into the plugin's live
directive/manifest/README, per contract v3's phase-2 execution step.

## Upstream basis

- `docs/issue-1/proposals/rulebook-maturation.md` (this repo, approved via
  issue-1 comment `APPROVE issue-1/data-modeling`)
- `docs/issue-1/reports/data-modeling/survey.md`,
  `docs/issue-1/reports/data-modeling/scout-brief.md` (phase-1 evidence
  base the proposal cites)

## Conceptual / logical / physical model artifacts

Not applicable this iteration — this issue's phase 2 is a directive/manifest/
README wording reflection (methodology and required-record-field norms),
not an actual schema/relationship decision. No entities, attributes, or DDL
are introduced or changed, so no conceptual, logical, or physical model
artifacts exist to produce. The next real schema-decision issue this role
executes is the one that must produce all three layers plus ERD and data
dictionary per the norm this record just landed.

## Normalization rationale

Not applicable — no schema changed in this issue (see above).

## Migration plan

Not applicable — no schema changed in this issue; nothing to migrate or
roll back.

## stub-check.sh verification

Structural shape unchanged: `directive.sh` remains a single-line
`core_role_directive "..." "..." "..." "..."` call sourcing
`core/hooks/lib/role-directive.sh`, matching the same stub-check-passing
form as before this edit (verified in issue-2's record); only the
`PRODUCES` argument's string value changed.

## Net file diff (as executed)

- Rewrote: `data-modeling/hooks/directive.sh` (`PRODUCES` arg value only).
- Edited: `data-modeling/.claude-plugin/plugin.json` (`description`),
  `README.md` (`produces` bullet, new `## Methodology` section).

## Open findings

None — the proposal's one open question (record-fields enforcement
strictness) is resolved above as option (i), per the proposal's own
recommendation.
