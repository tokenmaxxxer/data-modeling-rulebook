---
proposal: docs/issue-19/proposals/test-env-resolution-adoption.md
---

# Hunt record — test-env-resolution-adoption

## after-proposal — stance 3: assume the rule as written cannot hold — find the state nothing maintains

Verdict: FINDING — dropping the network-clone fallback silently turns "real assertions ran" into "SKIP", for exactly the plain-checkout-no-sibling-core environment the proposal itself is being written in, with nothing that detects or prevents the coverage loss.
Kind: silent-failure
Seed: docs/issue-19/proposals/test-env-resolution-adoption.md (plans to rewrite tests/resolve-core.sh to try only `../core`/`../../core` candidates via env_resolve.py, dropping the current git-clone-of-tokenmaxxxer-core fallback)
cap_seconds: 60
tier: default
diff_stat_lines: proposal file only (~110 lines), no code changed yet
started_at: 2026-08-09T00:00:00Z
ended_at: 2026-08-09T00:05:00Z

### Reproduce
```
cd /home/jwjung/.tokenmaxxxer/work/data-modeling-rulebook-issue-19-implementation
test -d ../core   || echo "NO ../core sibling"
test -d ../../core || echo "NO ../../core sibling"
# current behavior: resolve-core.sh's network-clone fallback still finds a real core
unset CLAUDE_PLUGIN_ROOT_CORE
. tests/resolve-core.sh
echo "RESOLVED=[$CLAUDE_PLUGIN_ROOT_CORE]"
```

### Observed
```
NO ../core sibling
NO ../../core sibling
RESOLVED=[/tmp/claude-.../tokenmaxxxer-core-canon-cache/core]
```
In this exact checkout (a worktree under `~/.tokenmaxxxer/work/`, sibling to
dozens of other issue worktrees, not to a `core` checkout), there is no
`../core` or `../../core`. Today's `tests/resolve-core.sh` still resolves a
real, working core via its network `git clone` fallback, so
`run-all-gate-tests.sh` and all four per-plugin suites currently exercise
their full real assertions (compliance-check.sh, gate-lib.sh-backed
behavior) here. The proposal explicitly removes that network path and
replaces it with only two sibling candidates. Run in this same environment
after the proposed change, every one of those suites would hit
`env_resolve.py`'s SKIP branch and exit 75 — a coverage regression from
"real assertions ran" to "silently skipped" with no code, config, or CI
signal anywhere in the plan that would notice or flag the loss. The
proposal's own "How you'll know it worked" section only checks the
already-known SKIP case (no candidate, no network) and the already-known
resolved case (`CLAUDE_PLUGIN_ROOT_CORE` pre-set) — it never checks the
in-between case that today's network fallback currently serves: no env var,
no sibling `core`, but network reachable. That state (which this repro just
showed is the state of the very machine writing the proposal) has no
invariant maintaining it under the new plan.

### Expected
Either the proposal should acknowledge and accept this specific coverage
loss explicitly (naming which real environments currently rely on the
network-clone fallback and lose real-assertion coverage, e.g. CI runners or
worktree-style dev checkouts with no `core` sibling), or it should keep some
network-reachable fallback candidate so environments like this one continue
to run real assertions instead of degrading to SKIP silently.
