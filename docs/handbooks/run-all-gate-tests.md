# run-all-gate-tests

Current state. Edited from now on to stay true.

## What this covers

`tests/run-all-gate-tests.sh` is the repo-root aggregator for the
`data-modeling` rulebook's `PreToolUse` gate plugins. It sources and runs
each plugin's own test suite in place, non-interactively:

- `data-modeling-structure/tests/structure-gate-tests.sh`
- `data-modeling-inmon/tests/inmon-gate-tests.sh`
- `data-modeling-kimball/tests/kimball-gate-tests.sh`
- `data-modeling-datavault/tests/datavault-gate-tests.sh`

Before those four, it also runs core's gate-house
`compliance-check.sh` (issue-72 canon, reference-only, never vendored)
against each of the four plugins' directories, so a future hand-rolled
kill switch or a local `.replace()`-shaped reconstruction creeping back
in fails the suite, not just the issue-10 migration.

Run it with `bash tests/run-all-gate-tests.sh` from the repo root. It exits
non-zero if any suite fails and prints which one.

`tests/resolve-core.sh` (sourced by every plugin's own test suite plus
`tests/run-all-gate-tests.sh` itself) resolves `CLAUDE_PLUGIN_ROOT_CORE` for
standalone test runs — an already-exported value first (a real install or a
developer's own local `core` checkout), else a one-time shallow clone of
`tokenmaxxxer-core` into a cache directory. The `compliance-check.sh` step
prints a warning and is skipped (not a failure) rather than blocking the
suite when neither resolves — the compliance check is best-effort in an
offline/no-core-clone dev environment, while the gate scripts' own runtime
behavior always depends on `CLAUDE_PLUGIN_ROOT_CORE` being set by a real
plugin install.

## Adding a plugin's suite to the aggregator

When a new `data-modeling-*` methodology plugin is added, append its test
script path to the `for suite in ...` list in
`tests/run-all-gate-tests.sh`. Each suite is expected to be self-contained
(own `run()` helper, own `mktemp`-based temp files — the sandbox's `/tmp`
is not writable, use `mktemp` rather than `/tmp/foo.$$`) and to exit
non-zero on any failing case.

## Gate script contract these suites test

Every `data-modeling-*` `PreToolUse` gate script (`hooks/*-gate.sh`) is
built on core's gate-house standard library (issue-72 canon,
reference-only, never vendored — `core/hooks/lib/gate-lib.sh` /
`gate-lib.py`), and follows the same contract, frozen when
`data-modeling-structure` was migrated (issue-10) and mirrored by
`data-modeling-inmon`/`-kimball`/`-datavault`:

- reads the tool-call JSON from stdin; malformed JSON (truncated,
  non-object top level, empty payload) fails closed via
  `gate_lib.gate_parse_json_or_deny`.
- fires on `Write`, `Edit`, and `MultiEdit` (`hooks.json` matcher
  `Write|Edit|MultiEdit`); the resulting content is reconstructed via
  `gate_lib.gate_reconstruct_write`, which honors each `Edit`/`MultiEdit`
  edit's own `replace_all` flag rather than reading only
  `tool_input.content` (a `Write`-only read would miss `Edit`/`MultiEdit`
  entirely). `Bash`-tool writes are out of these gates' tool scope
  (pass through) — see the open question in
  `docs/issue-10/proposals/gate-remediation.md` §2b.
- path-scoped via `gate_lib.gate_normalize_path` (absolute, relative, and
  `./`-prefixed paths to the same file match identically): only acts on
  `docs/issue-*/proposals/*.md` (proposal mode) or
  `docs/issue-*/reports/data-modeling.md` (record mode); any other path
  is a silent allow (exit 0).
- fail-closed end-to-end: `gate_trap_fail_closed` is installed before
  `set -uo pipefail`, and each gate's own Python payload wraps its body
  in `try/except Exception: deny(...)`, so an internal crash still exits
  2, not an untrapped code Claude Code would treat as fail-open.
- each plugin's own namespaced kill switch
  (`DATA_MODELING_{STRUCTURE,INMON,KIMBALL,DATAVAULT}_GATE_OFF`) is read
  via `gate_lib.gate_kill_switch_active`: only a recognized on-spelling
  (`1`/`true`/`yes`/`on`, case-insensitive) disables the gate; any other
  value, including a typo, keeps it active.
- the three methodology plugins additionally no-op (exit 0) whenever
  their own methodology token is absent from the content — they only
  enforce content once `data-modeling-structure`'s always-on
  `methodology-fit-named` check has already required some token to be
  present.
- semantic checks are section/adjacency-scoped, not bare substring: a
  marker phrase (`alternatives-considered`, `open-questions`,
  `methodology-fit-named`, `data-dictionary`, `migration plan`,
  `rollback`, Inmon's `normalization-target`/`deviations`, Kimball's
  `grain`/`fact table`/`dimension table`, Data Vault's `rationale`) must
  appear as/under a Markdown heading, as its own labeled line, or within
  2 lines of a `## ` section boundary — a bare mention elsewhere in the
  document (e.g. "we are not using Inmon here" outside any fit section)
  no longer satisfies the check. `decides-boundary`'s hand-off check
  requires `hand-off` and `data-engineering` within the same paragraph or
  3 lines of each other, not merely both present anywhere in the record.

`tests/resolve-core.sh` resolves `CLAUDE_PLUGIN_ROOT_CORE` for standalone
test runs (honors an already-set value; otherwise shallow-clones
`tokenmaxxxer-core` into a cache dir) so these gates — and
`tests/run-all-gate-tests.sh`'s own `compliance-check.sh` pass against
each plugin's `hooks/` dir — can run outside a full Claude Code plugin
install.
