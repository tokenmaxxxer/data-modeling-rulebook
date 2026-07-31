---
Subject: issue-2
---

# Scout brief — issue-2 (core canon reference switch)

Scope note: this task has no external product to benchmark against — the
target pattern is a **specific already-landed canon** (core issue-63/#66),
not an open design space. Scouting here means reading that canon and the
sibling rulebooks that would face the same migration, not web search.

## Sweep (1 stage, parallel `gh api`/`curl` reads)

- `tokenmaxxxer/tokenmaxxxer-core` tree: `core/hooks/*`, `core/hooks/lib/role-directive.sh`,
  `core/hooks/tests/stub-check.sh`, `warrant/*`.
- 3 sibling rulebooks (`api-design`, `accessibility`, `architecture`) checked
  for whether any had already converted — none had; this repo would be the
  first `directive.sh` stub conversion under the new canon.

## Must-bes (from core canon, binding on any converting rulebook)

- `directive.sh` MUST source `core/hooks/lib/role-directive.sh` and call
  `core_role_directive` with exactly 4 args; `stub-check.sh`'s structural
  check rejects any other non-blank/non-comment line (no raw `cat`, no
  `case`, no extra `echo`).
- `trailer-gate.sh` / `record-fields-gate.sh` / `handbook-trigger-gate.sh`
  local copies must be deleted outright — `stub-check.sh` fails on their
  mere presence, regardless of content. Their `hooks.json` entries go with them.
- Per-role divergence in `record-fields-gate.sh` is now carried by
  `RECORD_FIELDS_TERMINAL_STATES` (env var, default `landed`), not by a
  separate copy of the gate.
- `warrant-hunter.md` becomes a separately-installed plugin
  (`warrant@tokenmaxxxer-core`) with fully generic content — no per-role
  mandate text to inject.

## Gap line

Current `data-modeling/hooks/directive.sh` carries two elements
`core_role_directive`'s fixed template does not emit: a `WRITE_SCOPE` line
and a `BOUNDARY CASE` paragraph. Neither appears anywhere in
`core/contract/role-handoff-contract.md` — they are local-to-this-rulebook
additions from the issue-170 skeleton scaffolding, not contract-level
fields. See proposal for the resulting decision point.

## Adopt / skip

- Adopt: exact stub form from `role-directive.sh`'s own usage docstring.
- Adopt: delete-outright pattern for the three gates + hunter, matching
  how core's own `stub-check.sh` treats "presence = drift" for those files.
- Skip: inventing a local variant of `core_role_directive` to route around
  the structural check — that reproduces the exact per-role drift issue-66
  is closing.

Sources:
- https://github.com/tokenmaxxxer/tokenmaxxxer-core/blob/main/core/hooks/lib/role-directive.sh
- https://github.com/tokenmaxxxer/tokenmaxxxer-core/blob/main/core/hooks/tests/stub-check.sh
- https://github.com/tokenmaxxxer/tokenmaxxxer-core/blob/main/core/hooks/record-fields-gate.sh
- https://github.com/tokenmaxxxer/tokenmaxxxer-core/blob/main/core/hooks/trailer-gate.sh
- https://github.com/tokenmaxxxer/tokenmaxxxer-core/blob/main/core/hooks/handbook-trigger-gate.sh
- https://github.com/tokenmaxxxer/tokenmaxxxer-core/blob/main/core/hooks/hooks.json
- https://github.com/tokenmaxxxer/tokenmaxxxer-core/blob/main/warrant/agents/warrant-hunter.md
- https://github.com/tokenmaxxxer/tokenmaxxxer-core/blob/main/core/contract/role-handoff-contract.md
- https://github.com/tokenmaxxxer/api-design-rulebook/blob/main/api-design/hooks/directive.sh (sibling, unconverted — comparison baseline)
- Stages used: 1 (sweep only; saturated — no exemplar disagreement to deepen on, this is a fixed canon not a design space). Mode: batched-sequential `gh`/`curl` calls (no parallel dispatch available for read-only API calls in this session; stated per scout-directive fallback rule).
