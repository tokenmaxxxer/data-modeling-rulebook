---
Subject: issue-7
---

# Current-state survey — data-modeling gate/directive maturity (phase 1)

## What exists today

- `data-modeling/hooks/directive.sh` — one `SessionStart` hook, a thin call
  into core's `core_role_directive` with four free-text args (decides /
  use_when / produces / hand-off). The `PRODUCES` arg already names the
  five required record fields (conceptual/logical/physical model, ERD,
  data dictionary, normalization rationale, migration plan with rollback),
  per `docs/issue-1/proposals/rulebook-maturation.md`.
- `README.md` — carries the methodology-fit table (issue-1 phase 2) and the
  boundary-case note. No directive depth beyond the one-line `PRODUCES`
  summary and the table.
- `data-modeling/hooks/hooks.json` — wires `SessionStart` → `directive.sh`
  only. No `PreToolUse` entry.
- No local gate scripts of any kind (`data-modeling/hooks/` holds only
  `directive.sh` and `hooks.json`). Core canon supplies the role-agnostic
  gates globally (`trailer-gate.sh`, `record-fields-gate.sh`,
  `handbook-trigger-gate.sh`) — confirmed in `README.md`'s own "no local
  gate files" note.
- No `tests/` directory anywhere in this repo.
- No `agents/` directory, no checklists.
- `docs/issue-1/proposals/rulebook-maturation.md` (d).4 left the
  content-level enforcement question open explicitly: it recommended
  "documentation-only enforcement" for its own phase 2 and named the
  alternative — a role-specific content gate — as **out of scope for that
  issue**, deferring it. Issue #7 is that deferred work.

## The gap issue #7 names

`record-fields-gate.sh` (core canon) enforces the generic contract §20
shape (what/why/upstream/loop_state/open-findings) on any role's record.
It has no knowledge of this role's own required record *content*:

- it does not check that a record naming "physical" also traces a
  conceptual/logical layer (or states why not);
- it does not check that "normalization rationale" names an actual target
  form or that "migration plan" contains a rollback path;
- it does not check that a phase-1 proposal actually contains a
  methodology-fit row-and-reason, an alternatives-considered section, or a
  data-dictionary-vs-ERD distinction — issue-1's own required proposal
  sections (a.1–a.5).

Today, all of the above is enforced by directive wording only, i.e. not
enforced at all if the model drafting the record or proposal skips a
section — the "hook machine" implementation-rulebook is held up against.

## Comparable sibling rulebooks (same contract v3 shape) already closed this gap

- `pricing` role: `docs/issue-1/proposals/methodology-norms.md` (phase 1) →
  `pricing/hooks/methodology-gate.sh` (phase 2), wired as a `PreToolUse`
  gate on `Write|Edit|MultiEdit` matching its own proposal/record paths.
  Checks six pricing-specific elements are present in the write's resulting
  text (method named, family named, inputs-needed stated, gate-check
  result present, labeled numbers, residual list). Fails closed on
  unparseable payload, unresolvable diff (an `Edit` whose `old_string`
  doesn't match), or internal error.
- `implementation`/`coding` role: `coding/hooks/coding-progress-gate.sh` +
  `coding/hooks/state.sh` / `hunt-state.sh` — the state-tracking half, used
  where the methodology has an order constraint (there, hunt lock/count
  state persisted across hook invocations via files under the project
  root).

Both live under `docs/handbooks/canon-scripts.md`'s referenced-never-copied
clause: role-specific gates are new local scripts (not canon), so this
clause does not block them — it blocks *copying* canon-owned files
(`trailer-gate.sh`, `record-fields-gate.sh`, `handbook-trigger-gate.sh`,
`stub-check.sh`), which this role continues to reference from core, never
vendor.

## Ordering constraint check (issue #7 item 2, "조사→근거→채택")

This role's own adopted methodology (issue-1) is **not sequential across
turns** the way the coding role's hunt-lock is: the methodology-fit
decision (b) and the required record components are all resolved within a
single phase-1 proposal / phase-2 record, not staged across separate write
events that need cross-invocation memory. There is no "survey now, only
allowed to write proposal after" state machine needed here — issue-1
already enforces survey-before-proposal via the `scout-directive`'s
SURVEY-FIRST ORDER and the phase-1 required-sections list (a.2: proposal
must reference the survey file), which is a same-turn structural
requirement a content gate can check for (survey file referenced by path
inside the proposal text) without needing persisted state across
invocations. **Conclusion: no state-tracking mechanism is required for
this role's methodology** — the gate that item 2 needs is a stateless
per-write content check, same shape as `pricing`'s. This is stated
explicitly per issue #7's own "필요 시" (if needed) framing on both state
tracking and agents/checklists.

## Open surfaces for the phase-1 proposal to resolve

1. Directive depth for phase 1 and phase 2 separately (issue #7 item 1) —
   today's directive is one `PRODUCES` line; needs per-facet elaboration.
2. Exact required-element list and regex/string-match design for the new
   `data-modeling-gate.sh` (item 2), scoped to this role's actual proposal
   sections (issue-1 a.1–a.5) and record components (issue-1 b.1–b.4).
3. Gate test file under repo-root `tests/` (item 3) — no existing test
   harness in this repo; needs to be created following the core
   `run-role-gates-tests.sh` subprocess-invocation pattern.
4. Whether any agents/checklist artifact is warranted (item 4) — per the
   ordering-constraint finding above, likely not, since there is no
   repeated multi-step procedure beyond "check these elements in one
   write," but the proposal must state this explicitly rather than by
   omission.
