---
status: proposed
files:
  - tests/resolve-core.sh
  - tests/env_resolve.py
  - tests/run-all-gate-tests.sh
  - tests/missing-core-test.sh
  - data-modeling-structure/tests/structure-gate-tests.sh
  - data-modeling-inmon/tests/inmon-gate-tests.sh
  - data-modeling-kimball/tests/kimball-gate-tests.sh
  - data-modeling-datavault/tests/datavault-gate-tests.sh
  - docs/issue-19/reports/implementation/survey.md
  - docs/issue-19/reports/implementation.md
---

## Request
Adopt the canonical test-env resolution convention landed at
on-the-record `docs/specs/test-env-resolution.md` (issue #551) across
this rulebook's gate-test scripts: apply its resolution order and SKIP
contract everywhere a script currently assumes `CLAUDE_PLUGIN_ROOT_CORE`
is set, so that a plain checkout outside the spawn env prints an
explicit SKIP and exits with the convention's distinct code instead of
failing misleadingly. No assertion that runs when core is reachable may
be weakened.

## Constraints
- Resolution order is fixed by the convention doc: `CLAUDE_PLUGIN_ROOT_CORE`
  (validated non-empty `hooks/lib/gate-lib.sh`) -> caller-supplied
  sibling candidates -> SKIP with message `SKIP: core plugin unreachable
  — unverifiable outside spawn env` and exit code 75.
- No network fetch may live inside the canonical resolution path (per
  the doc, a network fallback is at most a repo-local extension layered
  on top, and this repo's current network clone in
  `tests/resolve-core.sh` is exactly the ad hoc pattern the convention
  exists to replace).
- Every script touched must reference `docs/specs/test-env-resolution.md`
  by grep-able string (acceptance check #3).
- Assertions that exercise a gate script while core IS reachable must be
  byte-for-byte unchanged in behavior.
- A script whose failure turns out to be a real defect, not an
  environment gap, must still surface as a FAIL/finding — never masked
  under SKIP.

## Rationale
Two ways to source the convention's reference resolver were available:

1. **Fetch `on-the-record`'s `gates/test_env_resolve.py` at test-run time**
   (mirroring today's network-clone-of-core pattern in
   `tests/resolve-core.sh`) — rejected: this is precisely the ambiguity
   the convention doc calls out by name ("a network dependency turning
   into a silent hang or a flaky failure is exactly the ambiguity this
   convention removes"). Keeping a live fetch on the resolution's own
   critical path would leave the exact defect issue #19 is meant to
   close, just moved one file over.
2. **Vendor a static, unmodified copy of the reference module into this
   repo's `tests/`** (chosen) — matches this repo's own established
   pattern for `gate-lib.sh` (canon reference-only, copied in rather than
   fetched or reimplemented, per the existing comment in
   `tests/resolve-core.sh`), keeps the resolver itself network-free and
   deterministic, and the module is genuinely file-local: stdlib-only,
   no external imports, so vendoring adds no new dependency.

Within the chosen approach, sibling-candidate paths were also a choice:
this repo's own existing hardcoded fallback (`../../core`, see
`data-modeling-structure/hooks/structure-gate.sh:15`) plus the doc's own
worked example (`../core`) are used as the caller-supplied candidate
list, rather than inventing a different path — reusing the path this
repo already trusts elsewhere in the same tree.

## What will be done
- Vendor `gates/test_env_resolve.py` from on-the-record verbatim into
  `tests/env_resolve.py` (module renamed to avoid a `test_` prefix that
  would make bare `pytest` collection of this repo pick it up as a test
  file; logic and constants — `SKIP_MESSAGE`, `EX_TEMPFAIL = 75`,
  `resolve_core()` — unchanged).
- Rewrite `tests/resolve-core.sh` to invoke
  `python3 tests/env_resolve.py ../core ../../core <network-cache-dir>`
  (candidates relative to repo root, plus the existing tmp cache dir as
  a third candidate) instead of hand-rolled logic; on exit 0 export
  `CLAUDE_PLUGIN_ROOT_CORE` to the printed path; on exit 75, leave it
  unset and export a companion `TEST_ENV_SKIP=1` so downstream scripts
  can branch without re-invoking the resolver. Keep today's network
  `git clone` as a repo-local extension layered *before* the resolver
  call (the doc explicitly allows this): if neither `../core` nor
  `../../core` exists locally, attempt the same best-effort shallow
  clone into the tmp cache as today, THEN call the resolver with the
  cache dir included as a candidate — so a developer machine with no
  sibling checkout but network access keeps resolving real assertions
  exactly as it does today, and only a genuinely offline/no-sibling
  environment reaches SKIP. (Closes a warrant-hunt finding: dropping the
  clone outright would silently flip this repo's own current dev
  environment — no `../core`/`../../core` sibling, but network-reachable
  — from "real assertions ran" to SKIP with nothing to detect the
  regression.)
- Update `tests/run-all-gate-tests.sh`: when `TEST_ENV_SKIP=1`, print the
  convention's SKIP message plus a reference to
  `docs/specs/test-env-resolution.md`, and exit 75 instead of the current
  "run-all-gate-tests: FAILED" / exit 1.
- Update `tests/missing-core-test.sh`: assert exit code 75 specifically
  (not just "non-zero") when `CLAUDE_PLUGIN_ROOT_CORE` is forced
  unresolvable, matching the new SKIP contract.
- Update each of the four per-plugin suites
  (`structure-gate-tests.sh`, `inmon-gate-tests.sh`,
  `kimball-gate-tests.sh`, `datavault-gate-tests.sh`): after sourcing
  `tests/resolve-core.sh`, check `TEST_ENV_SKIP`; if set, print the SKIP
  message referencing the convention doc and exit 75 immediately, before
  any `run_raw`/`write_case`/`edit_case` call and before the trailing
  compliance-check block — replacing today's degrade-into-misleading-FAIL
  behavior at both sites.
- Leave every assertion that runs when core resolves (the bulk of each
  suite's body, and `compliance-check.sh` invocation) untouched.
- Write `docs/issue-19/reports/implementation.md` (phase-2 record) at
  build time per the standing record-shape directive.

## Out of scope
- Changes to on-the-record itself, or to the reference module's logic —
  vendored verbatim, not modified.
- `tests/env_resolve.py`'s own unit tests (`gates/test_test_env_resolve.py`
  in on-the-record) are not ported; this repo's existing suites already
  exercise the resolver end-to-end via `missing-core-test.sh` (unresolved
  path) and every other suite's core-reachable path (resolved path) —
  adding a redundant standalone unit-test file is not required by the
  issue's acceptance checks.
- Any change to `data-modeling-structure/hooks/structure-gate.sh` (and
  the other three plugins' own gate scripts) — they source
  `gate-lib.sh` directly at their own call site and are not gate-*test*
  scripts; the issue scopes this to gate-test scripts only.
- CI workflow wiring: no `.github/workflows/` exists in this repo today,
  so there is nothing to update there.

## How you'll know it worked
- `CLAUDE_PLUGIN_ROOT_CORE` unset, no `../core`/`../../core` sibling
  present: running `tests/run-all-gate-tests.sh` and each of the four
  per-plugin suites directly prints the convention's SKIP message, exits
  75, and does not print `"run-all-gate-tests: FAILED"` or any
  `run_raw`-driven FAIL line.
- `tests/missing-core-test.sh` passes against the new exit-75 contract.
- With a real `core` checkout reachable via `CLAUDE_PLUGIN_ROOT_CORE`,
  running the same suites produces byte-identical pass/fail verdicts to
  the current `main` behavior (spot-checked by running before/after).
- `grep -rl "test-env-resolution" tests/ data-modeling-*/tests/` matches
  all eight touched test scripts (satisfies acceptance check #3).
