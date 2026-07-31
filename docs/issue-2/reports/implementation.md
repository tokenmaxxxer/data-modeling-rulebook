---
Subject: issue-2
---

# Record — core canon switch (phase 2)

loop_state: landed

## What was done

Executed the phase-1 proposal (`docs/issue-2/proposals/`, PR #3, approved
via the issue comment `APPROVE issue-2/implementation`) exactly as
written, resolving its one open decision:

1. Removed `data-modeling/agents/warrant-hunter.md` (and the now-empty
   `agents/` directory). Added `claude plugin install
   warrant@tokenmaxxxer-core` to README's Install section.
2. Removed `data-modeling/hooks/trailer-gate.sh`,
   `record-fields-gate.sh`, `handbook-trigger-gate.sh` and dropped their
   `PreToolUse` entries from `data-modeling/hooks/hooks.json`; only the
   `SessionStart` → `directive.sh` wiring remains.
3. Rewrote `data-modeling/hooks/directive.sh` as a canon stub: sources
   `core/hooks/lib/role-directive.sh` and calls `core_role_directive`
   with this role's four values, as a single-line call (stub-check's
   structural parser requires every non-blank line to match its allowed
   shape — a one-arg-per-line call form fails it; folded to one line).
4. Resolved the proposal's open WRITE_SCOPE/BOUNDARY-CASE decision:
   folded `WRITE_SCOPE` into the `HAND-OFF` argument as a trailing
   clause, and moved the BOUNDARY CASE paragraph into README.md as
   static documentation (no longer repeated every `SessionStart`).
5. No `RECORD_FIELDS_TERMINAL_STATES` override added — no per-role
   terminal-state vocabulary exists yet, so the canon default (`landed`)
   applies.

## Why

Core issue #63 and #66 landed a single canon for the warrant-hunt agent
and the three role-agnostic gates plus the directive boilerplate; this
repo's own copies are now drift risk, not local behavior, and this
issue's proposal (approved) is the migration plan for this rulebook.

## Upstream basis

- `docs/issue-2/proposals/` (this repo, PR #3, merged)
- Core canon files consulted at
  `/home/jwjung/tokenmaxxxer/tokenmaxxxer-core/core/hooks/hooks.json`,
  `core/hooks/lib/role-directive.sh`, `core/hooks/tests/stub-check.sh`

## stub-check.sh verification

Ran core's `core/hooks/tests/stub-check.sh` against `data-modeling/`:

```
stub-check: ok — no vendored 'trailer-gate.sh' under data-modeling
stub-check: ok — no vendored 'record-fields-gate.sh' under data-modeling
stub-check: ok — no vendored 'handbook-trigger-gate.sh' under data-modeling
stub-check: ok — no vendored 'parse-check.sh' under data-modeling
stub-check: ok — data-modeling/hooks/directive.sh is a role-directive stub
```

Exit code 0.

## Net file diff (as executed)

- Deleted: `data-modeling/agents/warrant-hunter.md`,
  `data-modeling/hooks/trailer-gate.sh`,
  `data-modeling/hooks/record-fields-gate.sh`,
  `data-modeling/hooks/handbook-trigger-gate.sh`.
- Rewrote: `data-modeling/hooks/directive.sh`, `data-modeling/hooks/hooks.json`.
- Edited: `README.md` (Install, Layout, BOUNDARY CASE relocation).

## Open findings

None.
