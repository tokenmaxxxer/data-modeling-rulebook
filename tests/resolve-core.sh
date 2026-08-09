#!/usr/bin/env bash
# Resolves CLAUDE_PLUGIN_ROOT_CORE so the gate test suites can run
# standalone (`bash <plugin>/tests/*.sh` outside a Claude Code session
# where a plugin installer would normally set it).
#
# Implements the canonical test-env resolution convention
# (docs/specs/test-env-resolution.md, issue #551) via the vendored
# tests/env_resolve.py: env var (validated non-empty gate-lib.sh) ->
# caller-supplied sibling candidates -> explicit SKIP (exit 75), never a
# misleading FAIL. Always re-validates CLAUDE_PLUGIN_ROOT_CORE through the
# resolver rather than trusting it blindly, so a bogus/unresolvable value
# (e.g. a test forcing a nonexistent path) reaches the SKIP contract
# instead of silently passing through. As a repo-local extension layered
# *before* the canonical resolver call (the convention explicitly allows
# this), a best-effort network clone of tokenmaxxxer-core into a tmp cache
# is attempted first when no already-valid CLAUDE_PLUGIN_ROOT_CORE and no
# sibling candidate exists locally, so a developer machine with no
# sibling checkout but network access still resolves real assertions
# exactly as before; only a genuinely offline/no-sibling environment
# reaches SKIP. A pre-existing cache is always replaced with a fresh
# clone, never reused as-is: env_resolve.py's reachability check only
# confirms gate-lib.sh is present and non-empty, not that it is current,
# so a cache left over from before an upstream core change (e.g.
# issue-75's gate_bash_write_targets) would otherwise resolve as
# "reachable" while actually stale, turning a real upstream addition
# into a misleading FAIL instead of the convention's SKIP/pass-through.
# (A plain `git pull` was tried first but does not self-heal a detached-
# HEAD shallow clone left at an old commit — the exact shape this cache
# takes — so re-cloning fresh is the reliable fix.)
_resolve_core_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
_resolve_core_cache="${TMPDIR:-/tmp}/tokenmaxxxer-core-canon-cache"
if [ ! -s "${CLAUDE_PLUGIN_ROOT_CORE:-/nonexistent}/hooks/lib/gate-lib.sh" ] \
   && [ ! -f "$_resolve_core_root/../core/hooks/lib/gate-lib.sh" ] \
   && [ ! -f "$_resolve_core_root/../../core/hooks/lib/gate-lib.sh" ]; then
  rm -rf "$_resolve_core_cache"
  git clone -q --depth 1 https://github.com/tokenmaxxxer/tokenmaxxxer-core.git \
    "$_resolve_core_cache" >/dev/null 2>&1 || true
fi

_resolve_core_result="$(python3 "$_resolve_core_root/tests/env_resolve.py" \
  "$_resolve_core_root/../core" \
  "$_resolve_core_root/../../core" \
  "$_resolve_core_cache/core" 2>&1)"
_resolve_core_status=$?

if [ "$_resolve_core_status" = "0" ]; then
  export CLAUDE_PLUGIN_ROOT_CORE="$_resolve_core_result"
  unset TEST_ENV_SKIP
else
  unset CLAUDE_PLUGIN_ROOT_CORE
  export TEST_ENV_SKIP=1
  echo "$_resolve_core_result (see docs/specs/test-env-resolution.md)" >&2
fi

unset _resolve_core_root _resolve_core_cache _resolve_core_result _resolve_core_status
