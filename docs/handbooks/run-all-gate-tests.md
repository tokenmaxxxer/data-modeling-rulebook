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

Run it with `bash tests/run-all-gate-tests.sh` from the repo root. It exits
non-zero if any suite fails and prints which one.

## Adding a plugin's suite to the aggregator

When a new `data-modeling-*` methodology plugin is added, append its test
script path to the `for suite in ...` list in
`tests/run-all-gate-tests.sh`. Each suite is expected to be self-contained
(own `run()` helper, own `mktemp`-based temp files — the sandbox's `/tmp`
is not writable, use `mktemp` rather than `/tmp/foo.$$`) and to exit
non-zero on any failing case.

## Gate script contract these suites test

Every `data-modeling-*` `PreToolUse` gate script (`hooks/*-gate.sh`)
follows the same contract, frozen when `data-modeling-structure` was
built and reused by `data-modeling-inmon`/`-kimball`/`-datavault`:

- reads the tool-call JSON from stdin, `jq -r '.tool_input.file_path //
  empty'` / `.tool_input.content // empty`.
- path-scoped: only acts on `docs/issue-*/proposals/*.md` (proposal mode)
  or `docs/issue-*/reports/data-modeling.md` (record mode); any other
  path is a silent allow (exit 0).
- fail-closed: an unparseable `file_path`/`content` on an in-scope path
  blocks (exit 2) rather than silently allowing the write.
- each plugin's own namespaced kill switch
  (`DATA_MODELING_{STRUCTURE,INMON,KIMBALL,DATAVAULT}_GATE_OFF=1`) skips
  the check entirely (exit 0) when set.
- the three methodology plugins additionally no-op (exit 0) whenever
  their own methodology token is absent from the content — they only
  enforce content once `data-modeling-structure`'s always-on
  `methodology-fit-named` check has already required some token to be
  present.
