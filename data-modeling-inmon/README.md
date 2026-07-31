# data-modeling-inmon

Inmon/3NF methodology-specific content gate for the `data-modeling` role.
Owns the content check for the Inmon (3NF, normalized enterprise data
warehouse) methodology — the phase-shape check (section presence, layer
naming, etc.) lives in `data-modeling-structure`, which fires on every
proposal/record regardless of methodology.

## What it checks

Fires as a `PreToolUse` hook on `Write` calls, scoped by `file_path`, same
as `data-modeling-structure`:

- `docs/issue-<n>/proposals/*.md`
- `docs/issue-<n>/reports/data-modeling.md`

Any other path is left untouched.

This gate only runs its methodology-specific check when the content names
the Inmon/3NF token (`inmon` or `3nf`, case-insensitive). If that token is
absent, the write is allowed immediately (exit 0) — Inmon/3NF wasn't the
methodology picked for this decision, so there is nothing for this plugin
to check. (`data-modeling-structure` already requires *some*
methodology-fit token to be present in proposals.)

When the token **is** present:

- Proposal mode: must name an intended normalization target form. Checked
  with:

  ```
  target[^.]*\b(1nf|2nf|3nf|bcnf)\b|\b(1nf|2nf|3nf|bcnf)\b[^.]*form
  ```

  i.e. either "target ... 1nf/2nf/3nf/bcnf" or "1nf/2nf/3nf/bcnf ... form"
  within the same sentence (up to the next `.`). Missing this blocks
  (exit 2) with a message naming what's missing.

- Record mode: must state normalization deviations, or explicitly state
  there are none. Checked by presence of the substring `deviation`
  (covers "normalization deviations: ..." and "no deviations from 3nf
  were made"). Missing this blocks (exit 2).

## Fail-closed

If the hook payload's `file_path`/`content` can't be parsed on an in-scope
path, the gate blocks (exit 2) rather than silently allowing the write.

## Kill switch

Set `DATA_MODELING_INMON_GATE_OFF=1` to skip this gate entirely.

## Tests

`tests/inmon-gate-tests.sh` — allow/deny cases for this gate only, run
directly or via the repo-root `tests/run-all-gate-tests.sh` aggregator.
