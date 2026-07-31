---
Subject: issue-7
---

# Scout brief — methodology-gate precedent across sibling rulebooks

Mode: local filesystem sweep (this role's "field" is sibling contract-v3
rulebooks that already closed the same gap, not external web products) —
batched-sequential in one session (parallel `find`/`cat` calls issued in
single turns), 2 stages: sweep (locate candidate gate implementations) +
one deepening round (read `pricing`'s gate + core's test harness in full).
Saturation reached after stage 2: a third rulebook (`implementation`'s
`coding-progress-gate.sh`) confirmed the same two-shape split (stateless
content gate vs. stateful ordering gate) rather than revealing a third
shape — no further round would change the design decision.

## Must-bes (what every comparable gate does)

- **Fail-closed always**: unparseable JSON, unresolvable `Edit` diff, or
  internal exception all `exit 2` (deny), never silently allow.
  (`pricing/hooks/methodology-gate.sh:73-84,153-159,221-223`)
- **Scope to this role's own write surfaces only**: a regex match on the
  resolved file path (`docs/issue-<n>/proposals/*<role>*.md` and
  `docs/issue-<n>/reports/<role>.md`); anything else is `exit 0` immediately
  — the gate is not a general-purpose linter.
  (`pricing/hooks/methodology-gate.sh:94-95,118-119`)
- **Kill switch namespaced per role** (`<ROLE>_METHODOLOGY_GATE_OFF`), same
  off-value parsing as core's trailer/record-fields gates (`""|0|false|no|off`
  = not off, anything else = off) — deliberately generous "off" parsing
  documented as a fixed-once bug pattern to not repeat.
  (`pricing/hooks/methodology-gate.sh:25-28`; `implementation-rulebook coding/hooks/hunt-state.sh:19-23`)
- **Compute resulting content, not just presence**: for `Write`, use
  `content` directly; for `Edit`/`MultiEdit`, replay the diff against
  current file content and deny if the diff can't be resolved (old_string
  not found) rather than guessing. (`pricing/hooks/methodology-gate.sh:129-159`)
- **Role-labeled deny message** (`"<role>: refused — ..."`) — every core and
  sibling gate test asserts this string shape specifically.
  (`core/hooks/tests/run-role-gates-tests.sh:27-30`)
- **Canon reference only, never a vendored copy**: new role-specific gate
  files (methodology-gate.sh-shaped) are NOT canon and are fine to add
  locally; only files under `core/hooks/`/`core/hooks/tests/`
  (`canon-manifest.txt`) may never be duplicated into a rulebook tree.
  (`docs/handbooks/canon-scripts.md:8-16`)

## Performance axes gates compete on

1. **Element-check precision** — string/regex needles broad enough to not
   false-positive-deny a legitimately-scoped-out write (pricing's
   `exited_early` escape hatch for "no method fielded" cases) vs. narrow
   enough to catch a genuinely missing element.
2. **Statelessness vs. state-tracking** — pricing's gate is fully stateless
   (one write, one content check); `coding`'s hunt-guard/hunt-state pair
   tracks lock+count files across hook invocations for an actual
   cross-turn ordering constraint. Picking the wrong one over-engineers
   (state machine for a same-turn requirement) or under-enforces (content
   check for a genuine multi-step ordering rule).

## Adopt / skip

- **Adopt**: pricing's exact structural shape (fail-closed trap, path-scope
  regex, Write/Edit/MultiEdit content resolution, role-labeled deny,
  namespaced kill switch) — same contract v3 role shape, same phase-1/
  phase-2 write surfaces, directly reusable pattern.
- **Skip**: state-tracking (hunt-lock/count file pair) — per the survey's
  ordering-constraint finding, this role's methodology has no
  cross-invocation sequencing requirement to enforce; adding state files
  the methodology doesn't need would be exactly the kind of unenforced
  scaffolding issue #7 is trying to eliminate elsewhere.

## Gap line (field must-bes vs. this role's current state)

Already met: role-labeled directive, `PRODUCES` field naming the five
record components (survey.md's "what exists today").
Missing (this is what the proposal must close): every must-be above except
the directive — no gate file, no path-scoping, no fail-closed trap, no
kill switch, no tests, at all.

Sources:
- `/home/jwjung/tokenmaxxxer/rulebooks/pricing-rulebook/pricing/hooks/methodology-gate.sh`
- `/home/jwjung/tokenmaxxxer/rulebooks/pricing-rulebook/docs/issue-1/proposals/methodology-norms.md`
- `/home/jwjung/tokenmaxxxer/rulebooks/pricing-rulebook/pricing/hooks/hooks.json`
- `/home/jwjung/tokenmaxxxer/tokenmaxxxer-core/docs/handbooks/canon-scripts.md`
- `/home/jwjung/tokenmaxxxer/tokenmaxxxer-core/core/hooks/tests/run-role-gates-tests.sh`
- `/home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/coding/hooks/hunt-state.sh`
- `/home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/coding/hooks/coding-progress-gate.sh`
