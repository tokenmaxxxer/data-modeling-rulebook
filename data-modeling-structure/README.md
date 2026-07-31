# data-modeling-structure

Methodology-agnostic phase-shape gate for the `data-modeling` role. Owns the
step order and required sections every proposal/record must carry
**regardless of which methodology fits the decision** — the shape check, not
the methodology-specific content check (that lives in
`data-modeling-inmon`/`-kimball`/`-datavault`, one plugin per methodology).

## What it checks

Fires as a `PreToolUse` hook on `Write` calls, scoped by `file_path`:

- `docs/issue-<n>/proposals/*.md` (phase 1):
  1. `survey-referenced` — cites `docs/issue-<n>/reports/data-modeling/survey`.
  2. `layers-named` — at least one of conceptual/logical/physical.
  3. `alternatives-considered`.
  4. `open-questions`.
  5. `methodology-fit-named` — inmon/3nf, kimball/dimensional model/star
     schema, data vault, **or** an explicit no-fit statement (`no schema
     decision`, `routed to`).
- `docs/issue-<n>/reports/data-modeling.md` (phase 2):
  1. `layers-or-justified-skip` — all three layers named, or fewer plus an
     explicit skip justification.
  2. `data-dictionary` — named as a section distinct from the ERD.
  3. `migration-rollback` — a migration plan and a rollback path.
  4. `decides-boundary` — if pipeline/ETL movement is mentioned, a
     hand-off note to `data-engineering` must accompany it.

Any other path is left untouched. A matched methodology token in element 5
is what makes the corresponding `data-modeling-{inmon,kimball,datavault}`
gate fire its own content check in the same `PreToolUse` batch — this
plugin does not call them; each detects its own token independently.

## Fail-closed

If the hook payload's `file_path`/`content` can't be parsed on an in-scope
path, the gate blocks (exit 2) rather than silently allowing the write.

## Kill switch

Set `DATA_MODELING_STRUCTURE_GATE_OFF=1` to skip this gate entirely.

## Tests

`tests/structure-gate-tests.sh` — allow/deny cases for this gate only, run
directly or via the repo-root `tests/run-all-gate-tests.sh` aggregator.
