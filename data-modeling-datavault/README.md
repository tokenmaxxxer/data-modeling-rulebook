# data-modeling-datavault

Data Vault methodology content gate for the `data-modeling` role. Owns the
methodology-specific content check when Data Vault is the chosen approach —
the phase-shape check (step order, required sections) lives in
`data-modeling-structure`, independent of which methodology is picked.

## What it checks

Fires as a `PreToolUse` hook on `Write` calls, scoped by `file_path`, same
as `data-modeling-structure`:

- `docs/issue-<n>/proposals/*.md` (phase 1)
- `docs/issue-<n>/reports/data-modeling.md` (phase 2)

Any other path is left untouched (exit 0).

The gate only fires its content check when the content names the Data Vault
token (case-insensitive `data vault`) — if that token is absent, the write
is allowed immediately (exit 0), since this methodology wasn't the one
picked for the decision.

When the token is present:

- Proposal mode:
  1. `hub-satellite-link` — at least one of hub/satellite/link is named.
  2. `rationale` — an auditability or schema-drift rationale is present
     (auditability, schema drift, or audit trail).
- Record mode:
  1. `hub-satellite-link` — the hub/satellite/link structure is named in
     the record.

## Fail-closed

If the hook payload's `file_path`/`content` can't be parsed on an in-scope
path, the gate blocks (exit 2) rather than silently allowing the write.

## Kill switch

Set `DATA_MODELING_DATAVAULT_GATE_OFF=1` to skip this gate entirely.

## Tests

`tests/datavault-gate-tests.sh` — allow/deny cases for this gate only, run
directly or via the repo-root `tests/run-all-gate-tests.sh` aggregator.
