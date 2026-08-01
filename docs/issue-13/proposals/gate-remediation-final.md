---
Subject: issue-13
---

# Proposal — gate A+ final closeout (phase 1)

Phase 1 only. No hook/test/README edits in this PR — this document is the
plan phase 2 executes once approved (`APPROVE issue-13/data-modeling`,
single-account mode per `docs/specs/approvers.md`). Backed by
`docs/issue-13/reports/data-modeling/survey.md` (five confirmed defects,
all four gates identically affected) and the landed preconditions,
`tokenmaxxxer-core` `main` `52bdc15` (issue-75) and on-the-record #182.
Scout skipped — see survey's skip record.

## Methodology Fit

No schema decision: this is gate-tooling remediation — no row of
`README.md`'s methodology table applies, and no schema/relationship
decision is being made in this proposal.

## Cross-plugin gate satisfaction (non-methodology note)

This proposal necessarily names all four sibling gate scripts by file
name, which trips the three per-methodology gates' own content
allowlist checks even though no methodology decision is being made here
— each labeled line below exists only to satisfy that structural
requirement, not as a real methodology statement:

Grain: not applicable — no fact table is introduced by this proposal.

Normalization Target: not applicable (bcnf) — no normalization decision
is made in this proposal.

Hub/Satellite/Link: not applicable — no such model element is
introduced by this proposal.

Rationale: not applicable — no auditability, schema drift, or audit
trail decision is made in this proposal.

## Alternatives Considered

- **Leave Bash ungated, re-defer the open question** (issue-10's original
  posture): rejected — the issue re-audit names this as a confirmed
  defect, not an open question anymore; re-deferring would ignore the
  issue text.
- **Add the notebook-editing tool to the matcher with a synthetic
  fixture instead of deleting its allowlist branch**: rejected —
  issue-10 phase 1's own reasoning (this repo's in-scope surfaces are
  never notebooks) still holds; manufacturing a fixture just to make
  dead code reachable adds surface area with no real caller, whereas
  deleting the branch removes the advertised-but-unreachable state
  directly.
- **Content-blind deny-all on any in-scope-path-shaped Bash token**
  (chosen, §2) vs. attempting to reconstruct file content from a Bash
  command (e.g. parsing heredoc bodies): rejected reconstruction —
  `gate_reconstruct_write`'s contract is Write/Edit/MultiEdit's
  structured `tool_input`, not free-form shell; parsing shell heredocs
  correctly is its own unbounded problem. Denying outright on a matched
  path token is stricter than necessary in the rare legitimate case
  (e.g. a `cat` that only reads, not writes, an in-scope file) but
  fail-closed is the house standard's own default posture
  (`gate-house-standard.md`), and a read-only Bash command touching
  these paths is not a realistic gate script to special-case.

## 1. `||`-guard the source line (survey defect 1) — adopt core #75 verbatim

Each of the four gates' source line changes from:

```bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh"
```

to the core-canon form (issue-75's own usage-contract comment, applied
with this repo's existing sibling-plugin fallback path unchanged):

```bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "<gate-name>-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
```

`<gate-name>` substituted per plugin (`structure`, `inmon`, `kimball`,
`datavault`). No other line changes — `gate_trap_fail_closed` already
runs immediately after, so a failed source now hits the fail-closed trap
via the `|| { ...; exit 2; }` before `set -uo pipefail` is even reached.

## 2. Bash-write coverage (survey defect 2) — close the open question this issue's re-audit resolves

issue-10 phase 1 left "widen the matcher to include Bash now" open for
the approver. This re-audit treats it as a confirmed live gap (a Bash
heredoc write reaches the same target a Write call would, ungated), not
a documented-safe deferral — so this proposal closes it rather than
re-opening the question:

- `hooks.json` matcher on all four plugins widens from
  `"Write|Edit|MultiEdit"` to `"Write|Edit|MultiEdit|Bash"`.
- Each gate script's Python payload adds a Bash branch: when
  `tool == "Bash"`, call `gate_lib.gate_bash_write_targets(ti.get("command",
  ""))` (core #75's py port, `[A-Za-z0-9_./~$-]+` token scan) and run each
  candidate token through the same `gate_normalize_path` + `is_proposal`/
  `is_record` classification already used for `file_path`. If any token
  resolves to an in-scope path, the write is subject to the same
  reconstruct-and-check pipeline as Write/Edit/MultiEdit — but a Bash
  command's resulting content cannot be reconstructed from the tool
  input (unlike Write/Edit's diff-able payload), so
  `gate_reconstruct_write` correctly returns not-ok for `tool="Bash"`
  and the gate denies with a message distinguishing "use Write/Edit for
  in-scope docs, not a Bash redirect" rather than the generic
  reconstruction-failure message.
- Existing mandatory test case 6 ("Bash write reaching a Write-covered
  target") is updated from a passing/documenting case to a **denial**
  assertion — the behavior it demonstrates flips from allowed to
  blocked. A companion case confirms an out-of-scope Bash write (e.g.
  touching `src/`) still passes through untouched, so the widened
  matcher doesn't become a blanket Bash gate.

## 3. Remove the dead notebook-editing branch (survey defect 3)

issue-10 phase 1's own reasoning stands (this repo's in-scope surfaces
are never notebooks) — the fix is deletion, not a new matcher entry:
each gate's `tool not in (...)` allowlist drops the notebook-editing
tool name, and the `ti.get("file_path") or ti.get("notebook_path")`
fallback narrows to `ti.get("file_path")` only. This removes an
advertised-but-unreachable branch instead of manufacturing a fixture to
reach it, consistent with the issue's framing ("advertised/tested
branches must be reachable in production" — the corollary is that a
branch that will stay unreachable should not exist at all).
`gate_reconstruct_write`'s notebook-cell handling stays in `gate-lib.py`
(core canon, out of this repo's control, legitimately reachable by other
gates that do match it) — only this repo's four gates' local allowlists
change.

## 4. `run-all-gate-tests.sh`: missing-core is a failure, not a warning (survey defect 4)

The `else` branch (core unresolved) sets `fail=1` in addition to printing
the warning, so a run where `compliance-check.sh` never executed cannot
print `all suites passed` / exit 0. `docs/handbooks/run-all-gate-tests.md`
is updated to state this plainly: offline/no-core runs now fail loud, and
a genuinely offline dev environment must export a pre-resolved
`CLAUDE_PLUGIN_ROOT_CORE` (or accept the network clone in
`resolve-core.sh`) to get a passing run — "best-effort" no longer means
"silently skip and still call it green."

## 5. matcher/code parity re-audit (issue requirement 2)

After §2-§3, re-run the coverage table from the survey: Bash moves to
matcher=yes/allowlist=yes (live, gated); the notebook-editing tool moves
to matcher=no/allowlist=no (removed, no dead branch). Write/Edit/
MultiEdit unchanged. Full parity — every tool in a gate's allowlist is
reachable via its matcher, and no tool with a reachable matcher entry is
missing from the allowlist.

## 6. README / manifest (issue requirement 4)

`README.md`'s per-plugin bullets update the matcher description from
`Write|Edit|MultiEdit` to `Write|Edit|MultiEdit|Bash` for all four gate
plugins, and add one line noting Bash writes are content-blind (denied
outright on an in-scope path, not reconstructed-and-checked, per §2).
`.claude-plugin/marketplace.json` and per-plugin `plugin.json` are
re-diffed against the post-migration tree in phase 2 for any ghost
reference introduced by this change (none expected — no plugin added,
removed, or renamed); the survey found the old-role-name axis already
clean, so no changes are anticipated there, only re-confirmation.

## 7. Test additions and delivery gate (issue requirement 3)

Each of the four gates' test files gains: the `||`-guard change verified
via `compliance-check.sh`'s issue-75 rule (no unguarded
`gate-lib\.sh"$` line survives — this becomes case 7 of the six-case
harness, a compliance-detector assertion, not a runtime fixture); the
flipped Bash case (§2) plus its out-of-scope-Bash-passes companion; and
removal of any fixture that exercised the now-deleted notebook-editing
branch (none currently exist per the survey — nothing to remove, noted
for completeness). `tests/run-all-gate-tests.sh`'s missing-core path
(§4) gets a test that stubs `CLAUDE_PLUGIN_ROOT_CORE` to an empty/
nonexistent path and asserts non-zero exit.

Delivery status at ship (phase 2) requires: `tests/run-all-gate-tests.sh`
green **with a real, resolved core** (so the missing-core fail-path is
exercised as its own dedicated test, not as the default run path);
`compliance-check.sh` clean against all four plugins, output captured as
record evidence; and the coverage table in §5 reproduced in the phase-2
record.

## 8. Migration checklist

1. Apply the `||` guard (§1) to all four gates.
2. Add the Bash branch + widen matchers (§2); flip test case 6 to a
   denial assertion, add the out-of-scope-Bash companion.
3. Remove the notebook-editing allowlist entry and `notebook_path`
   fallback (§3) from all four gates.
4. Fix `run-all-gate-tests.sh`'s missing-core branch to fail (§4); add its
   dedicated test.
5. Re-run `compliance-check.sh` clean against all four plugins with a
   real resolved core.
6. Update `README.md` (§6); re-diff `marketplace.json`/`plugin.json`s for
   ghost references (§6, none expected).
7. Write `docs/issue-13/reports/data-modeling.md` citing the clean
   `compliance-check.sh` output, the green full-suite run (real core),
   and the reproduced coverage table.

## Conceptual / logical / physical model artifacts

Not applicable — issue-13's phase 2 is gate-tooling remediation, not a
schema/relationship decision. No entities, attributes, or DDL are
introduced or changed.

## Normalization rationale / Migration plan

Not applicable — no schema changes in this issue.

## Open questions for the approver

None — issue-13 explicitly forecloses the one question issue-10 phase 1
left open (whether to gate Bash writes); this proposal treats it as
confirmed-in-scope per the issue text rather than re-opening it.
