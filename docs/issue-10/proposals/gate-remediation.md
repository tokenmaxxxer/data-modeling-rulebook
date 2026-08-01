---
Subject: issue-10
---

# Proposal — gate audit remediation to A+ (phase 1)

Phase 1 only. No hook/test/README edits in this PR — this document is the
plan phase 2 executes once approved (`APPROVE issue-10/data-modeling`,
single-account mode per `docs/specs/approvers.md`). Backed by
`docs/issue-10/reports/data-modeling/survey.md` (current-state defects,
confirmed identical across all four gates) and
`docs/issue-10/reports/data-modeling/scout-brief.md` (adoption pattern from
`core`'s `record-fields-gate.sh` exemplar, the closest available reference
since no sibling rulebook has migrated yet).

## 1. Adopt, don't reimplement: `core/hooks/lib/gate-lib.sh` + `gate-lib.py`

Per the issue's precondition and `docs/handbooks/gate-house-standard.md`,
each of the four gates (`structure`, `inmon`, `kimball`, `datavault`)
sources `gate-lib.sh` and loads `gate-lib.py` exactly as
`core/hooks/record-fields-gate.sh` does:

```bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}/hooks/lib/gate-lib.sh"
gate_trap_fail_closed
set -uo pipefail
gate_kill_switch_active "${DATA_MODELING_<X>_GATE_OFF:-}" || { trap - EXIT; exit 0; }
```

No copy of `gate-lib.sh`/`gate-lib.py`/`compliance-check.sh` is vendored
into this repo (canon-reference-only rule); `CLAUDE_PLUGIN_ROOT_CORE` (or a
`core` sibling-plugin discovery fallback matching how other cross-plugin
references in this repo already resolve `core`) is the only path this repo
adds.

This closes defects 2, 3, 4, 5 from the survey in one migration:

- **Fail-closed (defect 2)**: `gate_trap_fail_closed` installed first,
  before `set -uo pipefail`, plus (following the exemplar) the gate's own
  Python payload wraps its body in `try/except Exception: deny(...)` so an
  internal crash still exits 2, not an untrapped non-0/2 code.
- **Kill switch (defect 3)**: `gate_kill_switch_active` replaces the
  `[ "$X_GATE_OFF" = "1" ]` string compare — recognized on-spellings
  (`1`/`true`/`yes`/`on`, case-insensitive) disable; every other value,
  including a typo, stays active.
- **Path anchoring (defect 4)**: `gate_normalize_path` (or the exemplar's
  `resolve()`/`_under()` posixpath helpers, if the Python payload already
  has a project root) replaces the bare `case "$file_path" in docs/...)`
  glob, so absolute, relative, and `./`-prefixed paths to the same file
  match identically.
- **Edit/MultiEdit/replace_all (defect 5)**: `gate_reconstruct_write(tool,
  tool_input, current_content)` replaces the `Write`-only
  `.tool_input.content` read, honoring each `MultiEdit` edit's own
  `replace_all` flag and reconstructing `NotebookEdit` cell source.

## 2. `hooks.json` matcher widened (defect 1)

Each of the four `hooks.json` files' `PreToolUse` matcher changes from:

```json
"matcher": "Write"
```

to:

```json
"matcher": "Write|Edit|MultiEdit"
```

`NotebookEdit` is deliberately not added to the matcher — this repo's
in-scope surfaces (`docs/issue-*/proposals/*.md`,
`docs/issue-*/reports/data-modeling.md`) are never notebooks; adding it
would be surface-area with no reachable case, and the mandatory test
suite (§4) would have no fixture to justify it. `gate_reconstruct_write`
still handles `NotebookEdit` inside the library for the tool-agnostic
Bash-scan case (§2b) without requiring the matcher to include it.

### 2b. Bash-write coverage

`gate_bash_write_targets` scans a `Bash` `tool_input.command` string for
path-shaped tokens; whether to add `Bash` to the matcher and wire this in
is a phase-2 execution decision (it changes matcher semantics for four
plugins, not four scripts) — flagged here as an open question the
approver should weigh in on, not decided unilaterally in this proposal.
The gate-house standard's own mandatory test case 6 (a `Bash`-tool file
write reaching the same target a `Write`-tool call would hit) is adopted
into this repo's test suite regardless (§4), which will demonstrate
whether current behavior already denies-by-silence (safe) or allows
(unsafe) before the matcher decision is made.

## 3. Semantic checks: substring → section/adjacency/structure (defect 6)

Each of the six existing checks in `structure-gate.sh` (and the
methodology-specific checks in the other three) is rewritten from a bare
`grep -q PATTERN` over the whole lower-cased content to one of two
tightened forms, following the exemplar's own two patterns (scout-brief
§"Performance axes" 1-2):

- **Line-anchored marker fields** (fields with one canonical syntax, like
  the exemplar's `loop_state:`): anchor the regex to line start/end
  (`^\s*<field>:\s*...$`), not a bare substring, so a field name mentioned
  in prose no longer satisfies a structural-marker check.
- **Section-scoped phrase fields** (fields expressed as a heading or
  labeled paragraph, like `methodology-fit-named`,
  `alternatives-considered`, `open-questions`, `data-dictionary`,
  `migration plan`, `rollback`): require the marker phrase to appear as
  or immediately under a Markdown heading line (`^#{1,6}\s.*<phrase>`) OR
  within N (2) lines of a recognized section-boundary keyword the
  role's own structure already uses (`## `), rather than anywhere in the
  document. A bare mention inside unrelated prose (the issue's own
  example: "we are not using Inmon here" outside any Inmon-fit section)
  no longer satisfies the check.
- The `decides-boundary` hand-off check (structure-gate.sh:52, currently
  requiring `hand-off` AND `data-engineering` to both appear anywhere)
  becomes an adjacency check: both terms must appear within the same
  paragraph or within 3 lines of each other, so a document that mentions
  "data-engineering" in one section and "hand-off" in an unrelated one
  no longer passes.

No new parsing dependency is introduced — this stays at anchored-regex/
adjacency-window scope over the fully reconstructed content (per
scout-brief's explicit "skip: general Markdown-AST parser" call), matching
the exemplar's own level of sophistication rather than exceeding it.

## 4. Mandatory test additions (defect: test coverage gaps)

Per `gate-house-standard.md`'s six-case harness, each of the four gates'
own test files gains, at minimum:

1. `Edit` with `replace_all: true` against a multiply-occurring
   `old_string`.
2. `MultiEdit` with mixed `replace_all: true`/`false` edits in one call.
3. Malformed JSON: truncated, non-object top level, empty payload.
4. Kill-switch env var set to an unrecognized value (e.g. `"maybe"`) —
   assert the gate stays **active** (denies the same way it would with
   the switch unset).
5. Absolute `file_path` matching the same scope a relative-path fixture
   already matches, plus a `./`-prefixed variant.
6. A `Bash`-tool file write reaching the same target a `Write`-tool call
   would hit (demonstrates current pass-through behavior per §2b, ahead
   of the matcher decision).

Plus, for the semantic-check upgrade (§3): one case per rewritten check
where the old substring match would have (incorrectly) passed and the new
section/adjacency check correctly fails — e.g. a proposal that mentions
"inmon" only in an unrelated sentence outside any fit-section.

Delivery status at ship (phase 2) requires the full suite green, run via
`tests/run-all-gate-tests.sh` plus each plugin's own suite individually.

## 5. Compliance detector

`core/hooks/tests/compliance-check.sh "$(dirname "$0")/.."` is wired into
this repo's own `tests/run-all-gate-tests.sh` (or a new
`tests/compliance-check.sh` wrapper calling the core script, per the
handbook's invocation convention) so a future regression — a
hand-rolled kill switch or a `.replace()` reconstruction creeping back in
— is caught automatically, not only at this one migration.

## 6. README realignment

`README.md` is updated in phase 2 (not this PR) to: list the actual four
gate plugins and their real `hooks/*.sh` paths and matchers post-migration,
document each plugin's actual kill-switch env var name, and remove any
reference to a file or plugin that does not exist in the tree (ghost-file
removal — the exact diff is confirmed against the post-migration tree
during phase 2, not guessed at here).

## 7. Migration checklist (mirrors the handbook's own, §"Per-repo migration
checklist")

1. Run `compliance-check.sh` against the four gates' current state; record
   the violation list (expected: all four flagged for hand-rolled kill
   switch + no-reconstruction).
2. Migrate each of the four `*-gate.sh` scripts to source `gate-lib.sh` /
   load `gate-lib.py`, per §1-§3 above.
3. Widen each `hooks.json` matcher per §2.
4. Add the mandatory test cases per §4; re-run each plugin's suite plus
   `tests/run-all-gate-tests.sh`.
5. Re-run `compliance-check.sh` clean.
6. Update `README.md` per §6.
7. Write `docs/issue-10/reports/data-modeling.md` citing the clean
   `compliance-check.sh` output and the green test run as evidence.

## Open questions for the approver

- Whether to widen the matcher to include `Bash` now (§2b) or defer it to
  a follow-up issue once the new Bash-write test case (§4.6) shows actual
  current exposure.
- Whether the adjacency window for `decides-boundary` (§3, currently
  proposed as 3 lines) should instead be "same paragraph" measured by
  blank-line boundaries — a stricter but more expensive check to
  implement; proposed default is the line-count window for parity with
  the exemplar's own regex-only approach.
