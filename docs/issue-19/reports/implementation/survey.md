# Current-state survey — issue #19

## Scout skip record
Skip condition applied: "the spec literally leaves no design decision
open." on-the-record `docs/specs/test-env-resolution.md` (issue #551)
ships a complete reference implementation (`gates/test_env_resolve.py`),
a fixed resolution order, a fixed SKIP contract (message text, exit code
75), and per-consumer-shape adoption guidance for exactly this repo's
shape ("Bash test runner"). Adopting it is mechanical porting, not a
design choice — scouting the field for a different approach would
contradict the issue's explicit instruction to adopt this convention.
No sweep was run.

## What exists today

Env resolution is currently hand-rolled in `tests/resolve-core.sh`:
honors `CLAUDE_PLUGIN_ROOT_CORE` first, then falls back to a **network
git clone** of `tokenmaxxxer-core` into a tmp cache. This is exactly the
"network-fetch fallback... not part of the canonical SKIP contract"
called out in the convention doc — it can hang or flake instead of
producing a clean SKIP.

Failure/skip behavior on a plain checkout without core reachable:
- `tests/run-all-gate-tests.sh`: if `CLAUDE_PLUGIN_ROOT_CORE` never
  resolves (network clone fails/unavailable), it prints
  `"run-all-gate-tests: FAILED — CLAUDE_PLUGIN_ROOT_CORE unresolved..."`
  and exits 1 — a real failure, not a SKIP. This is the misleading-failure
  the issue names.
- Each per-plugin suite (`structure-gate-tests.sh`,
  `inmon-gate-tests.sh`, `kimball-gate-tests.sh`,
  `datavault-gate-tests.sh`) sources `tests/resolve-core.sh`, then in its
  final block (confirmed in `structure-gate-tests.sh:224-233`, same shape
  in the other three — verified via `grep -n CLAUDE_PLUGIN_ROOT_CORE
  <plugin>/tests/*.sh` across all four) does the same thing: FAILs with
  "cannot run compliance-check.sh" when unresolved.
- Independent of that final block, every suite's `run_raw` helper invokes
  the plugin's own gate script (e.g. `structure-gate.sh`), which sources
  `${CLAUDE_PLUGIN_ROOT_CORE:-...../core}/hooks/lib/gate-lib.sh` itself
  (`data-modeling-structure/hooks/structure-gate.sh:15`) and exits 2 with
  `"cannot source gate-lib.sh"` when that's unreachable — so every
  individual `run_raw`/`write_case`/`edit_case` assertion in the suite
  also degrades into a misleading FAIL (wrong exit code from the gate
  itself, not from the assertion under test), not just the trailing
  compliance-check block.
- `tests/missing-core-test.sh` deliberately asserts that
  `run-all-gate-tests.sh` exits non-zero when
  `CLAUDE_PLUGIN_ROOT_CORE=/nonexistent/stub-core-$$` is forced — i.e. it
  currently encodes "unresolved core is a failure" as the desired
  behavior. Under the new SKIP contract this needs to become "exits with
  the SKIP code (75), not the old generic failure" — same intent (don't
  silently report success), updated exit-code expectation.

## Write surfaces (confirmed by reading each file)

- `tests/resolve-core.sh` — hand-rolled resolver + network clone; replace
  with wrapper around the vendored reference module implementing the
  convention's 3-step order (env var -> caller candidates -> SKIP),
  dropping the network clone from the canonical path.
- `tests/env_resolve.py` (new) — vendored, unmodified port of
  on-the-record's `gates/test_env_resolve.py` reference implementation
  (canon reference-only, same pattern this repo already uses for
  `gate-lib.sh`: reference module copied in, not built independently).
- `tests/run-all-gate-tests.sh` — branch on the resolver's SKIP outcome:
  treat an unresolved core as a distinct SKIP report, not
  `"run-all-gate-tests: FAILED"`.
- `tests/missing-core-test.sh` — update the asserted exit code from "any
  non-zero" to specifically the SKIP contract's distinct code, since the
  desired behavior itself changed (SKIP, not FAIL).
- `data-modeling-structure/tests/structure-gate-tests.sh`,
  `data-modeling-inmon/tests/inmon-gate-tests.sh`,
  `data-modeling-kimball/tests/kimball-gate-tests.sh`,
  `data-modeling-datavault/tests/datavault-gate-tests.sh` — each must
  short-circuit to a SKIP (not run any `run_raw`/assertion, not FAIL)
  when the resolver reports unresolved, referencing
  `docs/specs/test-env-resolution.md` per the acceptance check's grep
  requirement.
- No `.env.example`, no dependency-manifest change, no migration: only a
  Python3 stdlib script is vendored (the reference module has no
  third-party imports), and Python3 is already a stated dependency
  elsewhere in this rulebook's tooling.

## Unknowns / risk noted for the proposal
- The convention's reference module has no hardcoded sibling-candidate
  path; each consumer supplies its own candidate list. This repo's
  existing hardcoded relative candidate is `../../core` (see
  `structure-gate.sh:15`) — the proposal will use `../core` and
  `../../core` relative to repo root as the caller-supplied candidates,
  matching the convention doc's own example and this repo's existing
  fallback path.
- Whether losing the network-clone fallback changes any currently-passing
  CI path: `run-all-gate-tests.sh` and the four per-plugin suites are
  invoked in this repo's own test workflow, which needs to be checked
  before landing so a legitimate CI run (where core presumably is
  reachable via a real install or checked out sibling) doesn't
  regress into SKIP. Flagged for phase 2 execution, not resolved here.
