---
Subject: issue-10
---

# Current-state survey — gate audit remediation (data-modeling)

## Scope

Four plugins carry a `PreToolUse` gate: `data-modeling-structure`,
`data-modeling-inmon`, `data-modeling-kimball`, `data-modeling-datavault`.
All four gate scripts (`*-gate.sh`) are structurally identical — same
defects, independently re-derived per plugin. `data-modeling/hooks/directive.sh`
is a `SessionStart` hook, not a `PreToolUse` gate, and is out of scope.

## Confirmed defects (matches issue #10's audit exactly)

1. **`hooks.json` matcher is `Write` only**, in all four plugins
   (`data-modeling-{structure,inmon,kimball,datavault}/hooks/hooks.json:5`).
   `Edit`, `MultiEdit`, and `NotebookEdit` calls against the same
   proposal/record paths bypass the gate entirely by construction — not a
   logic bug inside the script, the script never runs.
2. **Fail-closed is not trap-at-top.** Each gate does reach `exit 2` when
   `jq` returns empty/`null` for an in-scope path, but there is no
   `trap ... EXIT` installed before `set -u`. An early crash (e.g. `set -u`
   itself hitting truly unset `$1`, or an unanticipated bash error before
   the manual `-z`/`null` check) exits non-zero-non-two or is swallowed as
   exit 0, i.e. fail-open on the code path the manual check doesn't cover.
   This matches the gate-house survey's defect class 1.
3. **Kill switch is hand-rolled and narrower than the fixed convention.**
   Each gate checks only `[ "$X_GATE_OFF" = "1" ]` — a literal string
   compare against `"1"`. `true`/`yes`/`on`/`TRUE` do not disable it
   (inconsistent with the fixed on-spelling set), and, more importantly,
   there is no `gate_kill_switch_active` call at all — this predates and
   does not benefit from the core fix landed in issue #72.
4. **Relative-path-only anchoring.** The `case "$file_path" in
   docs/issue-*/proposals/*.md)` glob only matches when Claude Code hands
   the hook a relative path. An absolute path to the same file
   (`/abs/repo/docs/issue-7/proposals/x.md`) or a `./`-prefixed path falls
   through to the `*) exit 0 ;;` silent-allow branch — the gate is bypassed
   for any absolute-path write, which is exactly how `Edit`/`Write` calls
   are sometimes dispatched.
5. **No `Edit`/`MultiEdit`/`replace_all` reconstruction at all.** The
   scripts only ever read `.tool_input.content` (a `Write`-only field).
   Even if the matcher were widened, there is no logic path that
   reconstructs an `Edit` (`old_string`/`new_string`), a `MultiEdit`
   (array of edits, each with its own `replace_all`), or a `NotebookEdit`
   cell — this is the same defect class the gate-house library's
   `gate_reconstruct_write` was built to fix in core's own
   `record-fields-gate.sh`.
6. **Semantic checks are pure substring `grep -q`,** not section/adjacency/
   structure checks. E.g. `structure-gate.sh:41`'s
   `methodology-fit-named` passes on any occurrence anywhere in the
   document of the word `inmon` — a document that merely *mentions* Inmon
   in an unrelated aside (e.g. "we are not using Inmon here") satisfies the
   same `grep -q` as an actual methodology-fit section. None of the six
   semantic checks (survey-referenced, layers-named, alternatives,
   open-questions, methodology-fit, data-dictionary, migration-plan,
   rollback, decides-boundary hand-off) test section proximity or heading
   structure.

## Test coverage gaps

`data-modeling-structure/tests/structure-gate-tests.sh` (46 lines) and the
inmon/kimball/datavault equivalents (44-46 lines each) cover only
`Write`-tool, relative-path, well-formed-JSON, present/missing-field cases.
None of the four test files exercise: `Edit`, `MultiEdit`,
`replace_all: true` against a multiply-occurring string, malformed JSON
(truncated/non-object/empty), a kill-switch value other than exactly
`"1"`, or an absolute `file_path`. `tests/run-all-gate-tests.sh` (23 lines)
only fans out to the four per-plugin suites — it does not add its own
cross-cutting cases.

## README/reality gaps

`README.md`'s hooks/plugin references need re-verification against the
actual `.claude-plugin/plugin.json` sources and `hooks.json` matchers once
the migration changes the matcher list — tracked as a proposal action item
(exact ghost-file diff to be confirmed during phase 2 execution, not
phase 1; this survey does not re-run per issue #10's phase-1-only scope).

## What's available to fix this (core issue #72, landed)

`tokenmaxxxer/tokenmaxxxer-core`, `core/hooks/lib/gate-lib.sh` +
`gate-lib.py`, provides exactly the five missing primitives:
`gate_trap_fail_closed`, `gate_kill_switch_active`, `gate_deny`/
`gate_allow`, `gate_parse_json_or_deny` + `gate_normalize_path` +
`gate_reconstruct_write` (Python), and `gate_bash_write_targets` (bash).
`docs/handbooks/gate-house-standard.md` documents the mandatory six-case
test harness (`run-gate-lib-tests.sh`) and `compliance-check.sh`, a
detector for exactly defect classes 3 and 5 above. Per the issue's
precondition and the handbook's own "no retroactive fix in core" note,
this repo's migration is this repo's own responsibility, referencing
(never vendoring) `core`'s library — see the phase-1 proposal for the
adoption plan.
