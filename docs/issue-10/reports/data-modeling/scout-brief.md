---
Subject: issue-10
---

# Scout brief — gate-house adoption pattern (issue-10)

Mode: batched-sequential (single session, no parallel subagent dispatch —
one clear canonical source existed, so fan-out angles collapsed to one
target after the first read; recorded per the scout directive's
fallback-and-say-so clause). Stages used: 2 of 5 (sweep: clone+locate
`core`'s library/handbook; deepen: read one already-migrated core gate as
exemplar). Wall-clock: well under budget.

## Category must-bes (from the gate-house standard + its own exemplar)

- Fail-closed trap installed as the *first* statement (`gate_trap_fail_closed`
  or the equivalent inline `trap __fc EXIT` pattern), before `set -u`.
- Kill switch resolved via `gate_kill_switch_active`, never a hand-rolled
  string compare — the fixed on-spelling set (`1`/`true`/`yes`/`on`) is
  the only thing that disables; everything else, including garbage, stays
  active.
- Path matching resolves both relative and absolute inputs to one
  root-relative form before pattern-matching (`gate_normalize_path` in
  Python, or the exemplar's own `resolve()`/`_under()` helpers) — matching
  a bare string case-glob against `$file_path` is the anti-pattern.
- Content-under-write is reconstructed via `gate_reconstruct_write`
  (honors per-edit `replace_all`, handles `Write`/`Edit`/`MultiEdit`/
  `NotebookEdit` uniformly) — never a gate-local `.replace(old, new, 1)`.
- The gate's own internal-error path also fails closed (the exemplar wraps
  its whole Python payload in `try/except Exception` and denies on any
  internal crash, not just on the anticipated parse-failure branch).

## Performance axes the exemplar competes on

1. **Section-boundary precision** — the exemplar's `has_any(...)` calls
   still substring-match, but only within *reconstructed final content*,
   scoped per required field (`what-was-done`, `why`, `upstream-basis`,
   `loop_state` via a regex-anchored line, `open-findings`) rather than
   one grep over the raw diff; loop_state is asserted via
   `^\s*loop_state:\s*(...)\s*$` (line-anchored), not substring anywhere.
2. **Conditional requirements** — extra fields (`next-steps`,
   `resolution-path`) are required only when `loop_state` is non-terminal,
   not unconditionally — sets the shape for a section/adjacency upgrade
   without inventing a full doc-structure parser from scratch.
3. **Config over hardcoding** — role/terminal-state variance is handled
   through an env var the plugin's own `hooks.json` sets, not copy-paste
   divergence.

## Adopt / skip

- **Adopt**: cite `gate-lib.sh`+`gate-lib.py` directly (bash sources one,
  Python payload loads the other via `importlib`, exactly the exemplar's
  `GATE_LIB_PY` pattern); adopt its path-resolve + reconstruct + kill-switch
  + fail-closed primitives verbatim, no local reimplementation.
- **Adopt**: the exemplar's "required section named + line-anchored where
  the field has one canonical marker (loop_state), else phrase-anchored
  within the reconstructed text" approach as the shape for this repo's
  semantic-check upgrade (structure gate's `layers-named`,
  `methodology-fit-named`, etc. — see proposal §3).
- **Skip**: building a general Markdown-heading/AST parser — the
  exemplar itself doesn't do that; it stays at anchored-substring/regex
  scoped to reconstructed full content, which is enough to close the
  "word mention anywhere passes" hole the issue names, without a new
  dependency.

## Segment fit / gap line

This repo (`data-modeling-rulebook`) has NOT yet migrated any gate to
`gate-lib.sh` — an org-wide code search for `gate-lib.sh` under
`tokenmaxxxer` returned zero sibling-rulebook hits, so there is no
already-migrated *rulebook* exemplar to copy structurally; `core`'s own
`record-fields-gate.sh` (pre-#66/#72 promoted canon gate, not a rulebook
plugin) is the closest and only available reference. Gap: this repo's four
gates currently meet none of the five gate-lib primitives and none of the
structure/adjacency upgrade; the exemplar meets all five plus the
conditional-requirement pattern the semantic upgrade should reuse.

Sources:
- https://github.com/tokenmaxxxer/tokenmaxxxer-core/blob/main/core/hooks/lib/gate-lib.sh
- https://github.com/tokenmaxxxer/tokenmaxxxer-core/blob/main/docs/handbooks/gate-house-standard.md
- https://github.com/tokenmaxxxer/tokenmaxxxer-core/blob/main/core/hooks/record-fields-gate.sh
- https://github.com/tokenmaxxxer/tokenmaxxxer-core/blob/main/core/hooks/tests/compliance-check.sh
- https://github.com/tokenmaxxxer/tokenmaxxxer-core/blob/main/core/hooks/tests/canon-manifest.txt
