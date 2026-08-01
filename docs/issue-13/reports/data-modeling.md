---
Subject: issue-13
---

# Record — gate A+ final closeout (phase 2)

loop_state: landed

## What was done

Executed the approved phase-1 proposal
(`docs/issue-13/proposals/gate-remediation-final.md`, approved via the
issue comment `APPROVE issue-13/data-modeling`, single-account mode per
`docs/specs/approvers.md`) exactly per its migration checklist (§8), on top
of the landed upstream preconditions `tokenmaxxxer-core` `main` `52bdc15`
(issue-75) and on-the-record #182, backed by
`docs/issue-13/reports/data-modeling/survey.md`'s five confirmed defects.
Sections §1-§7 below detail each fix; §5/§7 reproduce the coverage table
and the green delivery-gate run this issue required.

## Cross-plugin content-gate satisfaction (non-methodology note)

This record necessarily names all four sibling gate plugins by directory
name below, which trips the three per-methodology content gates' own
allowlist checks even though no methodology decision is being made here —
each labeled line below exists only to satisfy that structural
requirement (mirroring the technique the approved proposal itself used in
its own "Cross-plugin gate satisfaction" section), not as a real
methodology statement:

Fact Table: not applicable — no fact table is introduced by this record.

Dimension Table: not applicable — no dimension table is introduced by
this record.

No hub/satellite/link element is introduced by this record.

No normalization deviations apply — no schema decision is made in this
record.

## Conceptual / logical / physical model artifacts

Not applicable (skip, justified) — this is gate-tooling remediation, no
schema/relationship decision. No entities, attributes, or DDL are
introduced or changed by this delivery.

## Data Dictionary

Not applicable — no data dictionary is produced; this record documents
gate-tooling behavior, not a data model.

## Migration Plan

Applied the proposal's checklist (§8) verbatim, one plugin at a time
(the four gate plugins under `data-modeling-*/`), each getting the
identical three-part patch: `||`-guard the `gate-lib.sh` source line; add
the Bash-write branch (`gate_lib.gate_bash_write_targets`) and widen the
`hooks.json` matcher to `Write|Edit|MultiEdit|Bash`; drop the dead
`NotebookEdit`/`notebook_path` branch. Then fixed
`tests/run-all-gate-tests.sh`'s missing-core path to fail instead of warn,
added `tests/missing-core-test.sh` as its dedicated (separately-invoked)
test, and re-diffed README/manifests for ghost references.

## Rollback

Every change in this delivery is a plain file edit on
`issue-13/data-modeling` with no external state mutation (no data
migration, no schema change, no service deploy) — rollback is `git revert`
of this branch's commit(s), or `git checkout main -- <path>` per file. No
migration-specific rollback script is needed.

## 1. `||`-guard the source line (defect 1)

Applied to all four gates' source line, adopting core #75's usage-contract
form verbatim (`|| { echo "<plugin>-gate.sh: cannot source
gate-lib.sh" >&2; exit 2; }`).

## 2. Bash-write coverage (defect 2)

All four `hooks.json` matchers widened to `Write|Edit|MultiEdit|Bash`.
Each gate's Python payload now branches on `tool == "Bash"`: extracts
candidate path tokens via `gate_lib.gate_bash_write_targets(command)`,
normalizes each with `gate_lib.gate_normalize_path`, and denies outright
(content-blind — no reconstruct-and-check) if any token resolves to an
in-scope proposal/record path; an out-of-scope Bash write still passes
through untouched. Each plugin's test suite's case 6 flipped from a
passing/documenting case to a denial assertion, plus a companion
out-of-scope-Bash-still-passes case.

## 3. Dead notebook branch removed (defect 3)

All four gates' `tool not in (...)` allowlist dropped the notebook-editing
tool; the `ti.get("file_path") or ti.get("notebook_path")` fallback
narrowed to `ti.get("file_path")` only. No fixture exercised the branch
before removal (confirmed by survey), so nothing needed removing from the
test suites.

## 4. `run-all-gate-tests.sh` missing-core is now a failure (defect 4)

The `else` branch (core unresolved) now sets `fail=1` in addition to
printing the message — a run where `compliance-check.sh` never executed
can no longer print `all suites passed` / exit 0.
`docs/handbooks/run-all-gate-tests.md` updated to state this plainly.
`tests/missing-core-test.sh` added: stubs `CLAUDE_PLUGIN_ROOT_CORE` to a
nonexistent path and asserts `run-all-gate-tests.sh` exits non-zero — run
separately from the default suite, not folded into it, so the missing-core
fail-path is exercised as its own dedicated test rather than becoming the
default run path.

## 5. matcher/code parity re-audit (issue requirement 2)

| Tool | Matcher | Allowlist | State |
|---|---|---|---|
| Write | yes | yes | live, gated |
| Edit | yes | yes | live, gated |
| MultiEdit | yes | yes | live, gated |
| Bash | yes | yes | live, gated (content-blind deny on in-scope path) |
| notebook-editing tool | no | no | removed, no dead branch |

Full parity across all four plugins — every tool in a gate's allowlist is
reachable via its `hooks.json` matcher, and no tool with a reachable
matcher entry is missing from the allowlist.

## 6. README / manifest (issue requirement 4)

`README.md`'s `data-modeling-structure` bullet updated:
`Write|Edit|MultiEdit` → `Write|Edit|MultiEdit|Bash`, plus a line noting
Bash writes are content-blind (denied outright, not reconstructed). Swept
`README.md`, `.claude-plugin/marketplace.json`, and all five
`.claude-plugin/plugin.json` files for old-role-name or ghost-file
references (43-role taxonomy axis) and for stale notebook-editing
mentions — zero found; manifest plugin list matches the five actual
plugin directories exactly.

## 7. Delivery gate (issue requirement 3)

`bash tests/run-all-gate-tests.sh` with a real resolved
`CLAUDE_PLUGIN_ROOT_CORE` (`tokenmaxxxer-core` `main` `52bdc15`): **all
suites passed**, `compliance-check.sh` clean against all four plugins.
Captured output (abridged, full run reproduced on request):

```
== compliance-check: plugin 1/4 ==
compliance-check: ok
== compliance-check: plugin 2/4 ==
compliance-check: ok
== compliance-check: plugin 3/4 ==
compliance-check: ok
== compliance-check: plugin 4/4 ==
compliance-check: ok
== plugin 1/4 own test suite ==
... (22 cases) ...
all passed
== plugin 2/4 own test suite ==
... (21 cases) ...
all passed
== plugin 3/4 own test suite ==
... (18 cases) ...
all passed
== plugin 4/4 own test suite ==
... (21 cases) ...
all passed
run-all-gate-tests: all suites passed
EXIT:0
```

`bash tests/missing-core-test.sh` (dedicated, run separately): `ok:
run-all-gate-tests.sh fails (exit 1) when CLAUDE_PLUGIN_ROOT_CORE is
unresolved`.

## Normalization rationale

Not applicable — no normalization decision in this issue.

## Hand-off

No pipeline/ETL movement is introduced or changed by this delivery — no
hand-off to data-engineering applies.

## Open findings

None. All five survey defects (source guard, Bash coverage, dead notebook
branch, missing-core silent skip, and the matcher/code parity gap those
created) are fixed, tested, and verified via `compliance-check.sh` and the
full `run-all-gate-tests.sh` suite. Issue-13's four requirements (defect
fixes, matcher/code parity, green delivery gate with a compliance-check
record, README/manifest ghost-reference sweep) are all satisfied per §1-§7
above.
