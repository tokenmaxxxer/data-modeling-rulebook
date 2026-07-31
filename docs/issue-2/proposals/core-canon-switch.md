---
Subject: issue-2
---

# Proposal — switch to core canon (core issue-63/#66 rollout)

Phase 1 only. No execution in this PR — this is the plan phase 2 will
carry out once approved.

## 1. Remove the warrant-hunter copy

Delete `data-modeling/agents/warrant-hunter.md` and the now-empty
`data-modeling/agents/` directory. Nothing replaces it inside this repo:
the hunt agent is now the separately-installed `warrant@tokenmaxxxer-core`
plugin, and its content is already fully role-generic (no mandate text to
localize). Add one line to this README's Install section:

```
claude plugin install warrant@tokenmaxxxer-core
```

`data-modeling/hooks/directive.sh` never carried hunt-cadence text, so
there is nothing to strip from it for this item.

## 2. Remove the 3 gate copies + their hook registration

Delete `data-modeling/hooks/trailer-gate.sh`,
`data-modeling/hooks/record-fields-gate.sh`,
`data-modeling/hooks/handbook-trigger-gate.sh`. Rewrite
`data-modeling/hooks/hooks.json` to drop their `PreToolUse` entries,
keeping only the `SessionStart` → `directive.sh` wiring:

```json
{
  "hooks": {
    "SessionStart": [
      { "hooks": [ { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/directive.sh" } ] }
    ]
  }
}
```

Core's own `core/hooks/hooks.json` already fires all three globally
(`PreToolUse` matcher `.*`) once `core@tokenmaxxxer-core` is installed —
confirmed present in the install chain this repo's README already lists
as a prerequisite for every agent session (per core's README s.5).

Per-role terminal-`loop_state` divergence (issue item 4): this repo's
skeleton scaffolding has never defined a `loop_state` vocabulary of its
own (no record has been written yet), so the canon default
(`RECORD_FIELDS_TERMINAL_STATES` unset → `landed`) applies as-is. No
override needed. If a data-modeling-specific terminal state emerges later
(e.g. treating some pre-`landed` state as terminal for this role), add
`"RECORD_FIELDS_TERMINAL_STATES": "landed <state>"` as an env entry on
the `record-fields-gate.sh` hook invocation in `hooks.json` at that time —
this file has no hook invocation left to attach it to until core's own
entry does that job, so nothing to add now.

## 3. Rewrite directive.sh as a canon stub

Replace `data-modeling/hooks/directive.sh` with the exact form
`core/hooks/lib/role-directive.sh`'s own usage docstring specifies:

```bash
#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"
core_role_directive \
  "YOU DECIDE: 데이터를 어떤 관계/스키마로 모델링할지" \
  "USE_WHEN: 스키마 신설/변경이 걸릴 때" \
  "PRODUCES (required record fields): schema/ERD, migration plan, normalization rationale" \
  "HAND-OFF: 파이프라인 이동/변환이 걸리면 → data-engineering"
```

This passes `stub-check.sh`'s structural check (source line + one
`core_role_directive` call, no other logic).

### Open decision for the approver: WRITE_SCOPE / BOUNDARY CASE

The current directive emits two things `core_role_directive`'s fixed
4-argument template does not: a `WRITE_SCOPE` line and a BOUNDARY CASE
paragraph. The survey confirms neither is a contract-v3 field — BOUNDARY
CASE is identical boilerplate across every sampled rulebook (a candidate
for its own core-canon promotion, out of this issue's scope), and
`WRITE_SCOPE` is role-unique but has no slot in the call signature.
`stub-check.sh` rejects any extra line in `directive.sh` beyond the
source/assignment/call shape, so neither can be re-added as loose
`cat`/`echo` output without failing the canon check.

Recommended resolution, pending approval: fold `WRITE_SCOPE` into the
`HAND-OFF` argument as a trailing clause (single line, still passes the
structural check):

```bash
  "HAND-OFF: 파이프라인 이동/변환이 걸리면 → data-engineering | WRITE_SCOPE: [\"src/**\"] (migrations only)"
```

and move the BOUNDARY CASE paragraph out of the SessionStart directive
entirely into this README (static documentation, read once, not repeated
every session) — since it carries no per-role information, repeating it
at every `SessionStart` is exactly the drift-by-duplication issue-66
targets, just not yet caught by `stub-check.sh` because that check only
looks for the 4 canon gate filenames, not for boilerplate paragraphs
smuggled through `core_role_directive`'s own arguments. Phase 2 implements
whichever of these two the approver confirms (or an alternative) at
Approve time.

## 4. Verify against stub-check.sh

Phase 2's record (`docs/issue-2/reports/implementation.md`) will include the
literal output of running core's `core/hooks/tests/stub-check.sh` against
`data-modeling/`, confirming: no vendored copy of the 3 gates found, and
`directive.sh` recognized as a valid stub.

## Net file diff (phase 2 preview, not executed here)

- Delete: `data-modeling/agents/warrant-hunter.md`,
  `data-modeling/hooks/trailer-gate.sh`,
  `data-modeling/hooks/record-fields-gate.sh`,
  `data-modeling/hooks/handbook-trigger-gate.sh`.
- Rewrite: `data-modeling/hooks/directive.sh`, `data-modeling/hooks/hooks.json`.
- Edit: `README.md` (Layout list, Install section, BOUNDARY CASE relocation
  per the decision above).
