# data-modeling-kimball

Kimball dimensional-modeling / star-schema methodology check for the
`data-modeling` role. Owns the methodology-specific content check — the
phase-shape check (step order, required sections) lives in
`data-modeling-structure` and fires independently.

## What it checks

Fires as a `PreToolUse` hook on `Write` calls, scoped by `file_path`:

- `docs/issue-<n>/proposals/*.md` (phase 1)
- `docs/issue-<n>/reports/data-modeling.md` (phase 2)

Any other path is left untouched. Within an in-scope path, the gate only
fires its methodology-specific check when the content actually names the
Kimball token (case-insensitive: `kimball`, `dimensional model`, or `star
schema`). If none of those tokens are present, the write is allowed
untouched — the decision may simply not be a Kimball fit.

When a Kimball token is present:

- **Proposal**: a grain statement is required (`grain:` or `grain is`).
- **Record**: the fact/dimension table split must be named — both `fact
  table` and `dimension table` must appear.

## Fail-closed

If the hook payload's `file_path`/`content` can't be parsed on an in-scope
path, the gate blocks (exit 2) rather than silently allowing the write.

## Kill switch

Set `DATA_MODELING_KIMBALL_GATE_OFF=1` to skip this gate entirely.

## Tests

`tests/kimball-gate-tests.sh` — allow/deny cases for this gate only, run
directly or via the repo-root `tests/run-all-gate-tests.sh` aggregator.
