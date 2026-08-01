---
Subject: issue-13
---

# Survey — current-state of the four gates after issue-10 phase 2

## Scout: skipped

Skip condition 1 (pure bugfix, no open design space): the issue names
confirmed defects and points at core issue #75's already-landed guard
shape as the reference to apply verbatim. There is no product-facing
direction decision here — only conformance to a canon that is already
merged and inspected below.

## Precondition check (both landed on `tokenmaxxxer-core` `main`)

- core #75 (`52bdc15`, PR #77): `gate-lib.sh`'s usage contract now
  mandates an `||`-guarded source line (fail-closed on missing core,
  replacing the prior fail-open-via-undefined-function bug);
  `compliance-check.sh` gained a detection rule for an unguarded
  `gate-lib.sh"$` source line; `gate_bash_write_targets` ported to
  `gate-lib.py` with sh-identical token semantics (regex
  `[A-Za-z0-9_./~$-]+`, sh/py parity-tested).
- on-the-record #182: `CLAUDE_PLUGIN_ROOT_CORE` injection in spawn —
  outside this repo's tree, nothing here depends on its internals beyond
  the env var already being the resolution path all four gates use.

Both confirmed present on `tokenmaxxxer-core` `main` before this survey.

## Defect 1 — `||` guard missing on all four gates (core #75 not yet applied here)

`data-modeling-{structure,inmon,kimball,datavault}/hooks/*-gate.sh` each
still source `gate-lib.sh` with no `||` guard on the same line:

```
. "${CLAUDE_PLUGIN_ROOT_CORE:-...}/hooks/lib/gate-lib.sh"
```

Confirmed identical across all four (`structure-gate.sh:15`,
`inmon-gate.sh:20`, and by the same shared-contract comment block,
`kimball-gate.sh`/`datavault-gate.sh`). This is exactly the issue-75-
confirmed defect: on a missing/unreachable core, the source fails, no
`gate_*` function is defined, and every gate's own
`gate_kill_switch_active ... || { exit 0; }` line reads the resulting
"command not found" (127) as the switch being off — silently allowing
every write. `compliance-check.sh`'s new rule (core #75) would flag all
four the moment it runs against them (see defect 5 — it currently doesn't
reliably run at all).

## Defect 2 — Bash writes ungated, and the test suite records this as a pass

None of the four `hooks.json` matchers include `Bash`
(`"Write|Edit|MultiEdit"` only), and none of the four gate scripts' own
`tool not in (...)` allowlist includes `Bash`. issue-10's phase-1
proposal explicitly left this as an open question for the approver
(§2b: "whether to add `Bash` to the matcher... flagged here as an open
question") and shipped mandatory test case 6 — "a `Bash`-tool file write
reaching the same target a `Write`-tool call would hit" — to *document*
current behavior, not to fail on it. That test currently asserts the
Bash write is allowed and passes green; the re-audit calls this out as
the residual gap the open question left unresolved, not a documented-safe
state — a `Bash` `cat > docs/issue-<n>/proposals/x.md <<EOF` reaches the
exact same target the structural gate blocks via `Write`, ungated.
`gate_bash_write_targets` (core #75, now sh+py) exists specifically to
close this and is unused by any of the four gates.

## Defect 3 — `NotebookEdit` dead branch

Each gate's Python payload allowlists `tool in ("Write", "Edit",
"MultiEdit", "NotebookEdit")` (e.g. `structure-gate.sh:47`) and reads
`ti.get("file_path") or ti.get("notebook_path")` to cover it — but no
`hooks.json` matcher in this repo includes `NotebookEdit`
(`"Write|Edit|MultiEdit"` only, all four). Per issue-10 phase 1 §2 this
exclusion was deliberate ("this repo's in-scope surfaces... are never
notebooks"), but the code still carries the `NotebookEdit` case and
`gate_reconstruct_write`'s notebook-cell-source path, neither of which
any matcher can ever route a call into — a branch advertised (and even
test-covered at the library level in core) but unreachable in production
here, which is exactly the class of defect the issue calls out
("광고·테스트된 분기가 프로덕션에서 도달 가능해야 함").

## Defect 4 — `run-all-gate-tests.sh` silent success when core is unresolved

`tests/run-all-gate-tests.sh`: when `CLAUDE_PLUGIN_ROOT_CORE` fails to
resolve (`resolve-core.sh` couldn't clone/find core), the script takes
the `else` branch, prints a `WARNING` to stderr, and does **not** set
`fail=1`. If the four plugins' own suites all pass, the script prints
`run-all-gate-tests: all suites passed` and exits 0 — with
`compliance-check.sh` (defect 1's detector) never having run at all. This
is a "green" delivery run that never checked the very compliance rule
core #75 added, and nothing distinguishes it from an actually-clean run
in exit-code or the final summary line.

## Defect 5 — matcher/code coverage audit (issue requirement 2)

| Tool | In `hooks.json` matcher (all 4) | In gate's `tool not in (...)` allowlist |
|---|---|---|
| Write | yes | yes |
| Edit | yes | yes |
| MultiEdit | yes | yes |
| NotebookEdit | no | yes (defect 3 — dead branch) |
| Bash | no | no (defect 2 — ungated, not a dead branch, a live gap) |

Full parity requires either removing the `NotebookEdit` case (matcher
still excludes it, deliberately, per issue-10's own reasoning) or adding
`NotebookEdit` to the matcher with a real fixture — the current state is
neither; it advertises a branch with no route to it.

## README / manifest ghost-file and old-role-name check (issue requirement 4)

`README.md` and `.claude-plugin/marketplace.json` reviewed line-by-line
against the actual tree: five plugins listed match five plugins present,
`hooks/*.sh` paths and matcher (`Write|Edit|MultiEdit`, unchanged since
issue-10) match the real files, all five kill-switch names match. No
reference to a plugin, file, or old per-methodology role name (pre-taxonomy-
promotion naming, issue-160) that doesn't exist in the tree was found —
this axis is currently clean. It is not clean of the `Bash` gap (README
doesn't mention `Bash` matcher status either way) or of describing the
`NotebookEdit` allowlist entry as reachable — those two get called out
explicitly once fixed, per the phase-2 plan below.
