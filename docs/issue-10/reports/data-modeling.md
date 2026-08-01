---
Subject: issue-10
---

# Record — gate audit remediation to A+ (phase 2)

loop_state: landed

## What was done

Executed the approved phase-1 proposal
(`docs/issue-10/proposals/gate-remediation.md`, approved via the issue
comment `APPROVE issue-10/data-modeling`, single-account mode per
`docs/specs/approvers.md`) exactly per its migration checklist (§7):

1. Ran `core/hooks/tests/compliance-check.sh` against the four gates'
   pre-migration state — all four flagged for the hand-rolled kill switch
   (`reads a *_OFF kill-switch env var but does not call
   gate_kill_switch_active`); `data-modeling-inmon`, `-kimball`,
   `-datavault` also lacked any `gate_reconstruct_write` call.
2. Migrated all four `*-gate.sh` scripts (`structure`, `inmon`, `kimball`,
   `datavault`) to source `gate-lib.sh` and load `gate-lib.py` via
   `importlib`, matching `record-fields-gate.sh`'s idiom: `gate_trap_fail_closed`
   installed first, before `set -uo pipefail`; the gate's own Python
   payload wrapped in `try/except Exception: deny(...)` so an internal
   crash still exits 2; `gate_kill_switch_active` for the kill switch
   (only `1`/`true`/`yes`/`on` disable; any other value, including a typo,
   stays active); `gate_normalize_path` for absolute/relative/`./`-prefixed
   path matching; `gate_reconstruct_write(tool, tool_input, current_content)`
   replacing the old `Write`-only `.tool_input.content` read, covering
   `Edit`/`MultiEdit` (honoring each edit's own `replace_all`) and
   `NotebookEdit`. `CLAUDE_PLUGIN_ROOT_CORE` with the sibling-plugin
   fallback (`.../hooks/../../core`) is the only path added, matching the
   convention `data-modeling/hooks/directive.sh` already used for
   `role-directive.sh`.
3. Widened each of the four `hooks.json` `PreToolUse` matchers from
   `"Write"` to `"Write|Edit|MultiEdit"` — `NotebookEdit` and `Bash` stay
   out of the matcher per the proposal's explicit exclusion for this repo.
4. Upgraded every substring `grep -q`/bare-`in low` semantic check to one
   of: line-anchored marker fields where the check has a canonical
   syntax; section-scoped phrase checks (a Markdown heading naming the
   phrase, a `Phrase:`-labeled line, or within 2 lines of a `## `
   boundary) for `methodology-fit-named`, `alternatives-considered`,
   `open-questions`, `data-dictionary`, `migration plan`, `rollback`,
   `normalization-target-named`, `normalization-deviations-stated`,
   `grain-statement`, `fact-table`, `dimension-table`, and Data Vault's
   `rationale`; and an adjacency check for `structure-gate.sh`'s
   `decides-boundary` hand-off check (`hand-off` and `data-engineering`
   within the same paragraph or within 3 lines of each other, replacing
   "both appear anywhere in the doc"). All checks operate on the fully
   reconstructed content from `gate_reconstruct_write`, not raw
   `tool_input.content`.
5. Added the mandatory test cases to each of the four gates' own test
   files: `Edit` with `replace_all:true` against a multiply-occurring
   `old_string`; `MultiEdit` with mixed `replace_all` true/false edits;
   malformed JSON (truncated, non-object top level, empty payload);
   kill-switch set to an unrecognized value (`maybe`), asserted to stay
   active; an absolute `file_path` and a `./`-prefixed variant matching
   the same scope as a relative fixture; a `Bash`-tool write to the same
   target a `Write` call would hit (documents current pass-through —
   allowed, since the matcher and the gate's own `tool_name` check both
   exclude `Bash`); plus one false-positive-closing case per rewritten
   semantic check (e.g. a bare "we are not using Inmon here" aside no
   longer satisfying `methodology-fit-named`; "grain" used in an
   unrelated coffee-texture sentence no longer satisfying
   `grain-statement`). Each plugin's suite now runs against real files on
   disk under a `CLAUDE_PROJECT_DIR`-resolved fake project root (with a
   `docs/specs/approvers.md` marker), the same root-resolution shape
   `record-fields-gate.sh` uses, so `Edit`/`MultiEdit` reconstruction has
   real "current content" to work against.
6. Wired core's `compliance-check.sh` into `tests/run-all-gate-tests.sh`
   (runs first, against each of the four plugins' directories) rather than
   a separate wrapper script, resolving `CLAUDE_PLUGIN_ROOT_CORE` via the
   new `tests/resolve-core.sh` (already-exported value first, else a
   one-time shallow clone of `tokenmaxxxer-core` into a cache directory —
   skips with a warning, not a failure, if neither resolves, since the
   compliance check is best-effort in an offline dev environment while the
   gates' own runtime behavior always depends on a real plugin install
   setting `CLAUDE_PLUGIN_ROOT_CORE`). Documented in
   `docs/handbooks/run-all-gate-tests.md`.
7. Re-ran `compliance-check.sh` clean against all four plugins (see
   below) and realigned `README.md`: the four gate plugins now list their
   real `hooks/*-gate.sh` paths, the widened `Write|Edit|MultiEdit`
   matcher, and their real kill-switch env var names; the fixed
   kill-switch on-spelling set is called out; no reference to a
   nonexistent file or plugin remains.

## Why

Issue #10's audit found all four `data-modeling-*` gates independently
re-derived the same six defect classes core's gate-house standard
(`docs/handbooks/gate-house-standard.md`, issue-72) already has a shared,
tested fix for: `Write`-only matcher, no fail-closed trap, a hand-rolled
kill switch that fails open on any unrecognized value, relative-path-only
anchoring, no `Edit`/`MultiEdit`/`replace_all` reconstruction, and
substring-only semantic checks. The approved phase-1 proposal's plan was
to adopt the shared library rather than re-patch each defect locally
per-gate (four more independently-drifting implementations); this record
reflects that plan executed against all four gates with no deviation from
the approved checklist, plus the two items the proposal explicitly left
open for the approver (below), which this phase does not resolve
unilaterally.

## Upstream basis

- `docs/issue-10/proposals/gate-remediation.md` (this repo, approved via
  issue-10 comment `APPROVE issue-10/data-modeling`)
- `docs/issue-10/reports/data-modeling/survey.md`,
  `docs/issue-10/reports/data-modeling/scout-brief.md` (phase-1 evidence
  base the proposal cites)
- `docs/handbooks/gate-house-standard.md`, `core/hooks/lib/gate-lib.sh` +
  `gate-lib.py`, `core/hooks/record-fields-gate.sh` (core canon,
  `tokenmaxxxer/tokenmaxxxer-core`, issue-72 — reference-only, never
  vendored)
- `docs/issue-7/reports/data-modeling.md` (prior phase-2 record — the
  plugin set and per-methodology check shapes this migration upgrades in
  place, not replaces)

## Conceptual / logical / physical model artifacts

Not applicable — issue-10's phase 2 is a rulebook enforcement-tooling
migration (gate internals), not a schema/relationship decision. No
entities, attributes, or DDL are introduced or changed.

## Normalization rationale

Not applicable — no schema changed in this issue.

## Migration plan

Not applicable — no schema changed in this issue; nothing to migrate or
roll back. (The four gate scripts' own internal logic changed, but their
external contract — matcher scope, kill-switch names, in-scope paths — is
additive/widened, not breaking, for any existing caller.)

## compliance-check.sh — clean run (evidence)

```
$ bash tests/run-all-gate-tests.sh   # first phase (compliance-check step)
== compliance-check: data-modeling-structure ==
compliance-check: ok — .../data-modeling-structure/hooks/structure-gate.sh
== compliance-check: data-modeling-inmon ==
compliance-check: ok — .../data-modeling-inmon/hooks/inmon-gate.sh
== compliance-check: data-modeling-kimball ==
compliance-check: ok — .../data-modeling-kimball/hooks/kimball-gate.sh
== compliance-check: data-modeling-datavault ==
compliance-check: ok — .../data-modeling-datavault/hooks/datavault-gate.sh
```

## Full test suite — green run (evidence)

```
$ bash tests/run-all-gate-tests.sh
== data-modeling-structure/tests/structure-gate-tests.sh ==
...
structure-gate-tests: all passed
== data-modeling-inmon/tests/inmon-gate-tests.sh ==
...
inmon-gate-tests: all passed
== data-modeling-kimball/tests/kimball-gate-tests.sh ==
...
kimball-gate-tests: all passed
== data-modeling-datavault/tests/datavault-gate-tests.sh ==
...
datavault-gate-tests: all passed
run-all-gate-tests: all suites passed
```

Also run and green individually (per the checklist's "plus each plugin's
own suite individually"): `bash data-modeling-structure/tests/structure-gate-tests.sh`,
`bash data-modeling-inmon/tests/inmon-gate-tests.sh`,
`bash data-modeling-kimball/tests/kimball-gate-tests.sh`,
`bash data-modeling-datavault/tests/datavault-gate-tests.sh` — each exits 0
independently of the aggregator.

## Net file diff (as executed)

- Edited: `data-modeling-structure/hooks/structure-gate.sh`,
  `data-modeling-inmon/hooks/inmon-gate.sh`,
  `data-modeling-kimball/hooks/kimball-gate.sh`,
  `data-modeling-datavault/hooks/datavault-gate.sh` (gate-lib migration +
  semantic-check upgrade).
- Edited: all four plugins' `hooks/hooks.json` (matcher widened to
  `Write|Edit|MultiEdit`).
- Edited: all four plugins' `tests/*-gate-tests.sh` (mandatory case
  additions, real-file `CLAUDE_PROJECT_DIR` fixtures).
- Edited: `tests/run-all-gate-tests.sh` (compliance-check.sh step added).
- New: `tests/resolve-core.sh` (standalone `CLAUDE_PLUGIN_ROOT_CORE`
  resolution for test runs, not vendoring — falls back to an ad hoc
  network clone of core, never a checked-in copy of any core file).
- Edited: `README.md` (real plugin/matcher/kill-switch layout).
- Edited: `docs/handbooks/run-all-gate-tests.md` (documents the
  compliance-check step and `resolve-core.sh`).
- New: `docs/issue-10/reports/data-modeling.md` (this record).
- No `core/hooks/*` file touched or copied (canon-reference-only
  preserved, per `docs/handbooks/canon-scripts.md`).

## Open findings

Two items the proposal's "Open questions for the approver" section left
explicitly undecided are **not** resolved in this phase and remain open,
per the task's own constraint not to unilaterally decide beyond the
approved proposal:

1. **Bash-matcher widening.** Whether to add `Bash` to the four
   `hooks.json` matchers (currently `Write|Edit|MultiEdit` only) so a
   `Bash`-tool file write reaching the same target a `Write` call would
   hit is also gated. The mandatory test case 6 in each plugin's suite
   demonstrates today's behavior concretely: such a write currently
   passes through (exit 0, allowed) — both because the matcher excludes
   `Bash` and because each gate's own Python payload only recognizes
   `tool_name in ("Write","Edit","MultiEdit","NotebookEdit")`. Deferred to
   a follow-up issue per the proposal.
2. **Adjacency-window width for `decides-boundary`.** The hand-off/
   data-engineering adjacency check uses the proposal's proposed 3-line
   default (plus a same-paragraph fallback), not the alternative
   "same paragraph only, via blank-line boundaries" the proposal flagged
   as a stricter-but-more-expensive option. Not changed from the 3-line
   default in this phase.
