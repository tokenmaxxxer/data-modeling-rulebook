#!/usr/bin/env bash
# PreToolUse gate: Inmon/3NF methodology-specific content for data-modeling.
# Contract (frozen, shared by data-modeling-{structure,kimball,datavault}):
#   - reads the tool-call JSON from stdin (Claude Code PreToolUse hook payload)
#   - only acts on Write/Edit/MultiEdit calls whose resolved file_path
#     matches this role's proposal or record surface; any other path is a
#     silent allow (exit 0)
#   - fail-closed: unparseable input, or an internal error, on an in-scope
#     path blocks (exit 2)
#   - kill switch: DATA_MODELING_INMON_GATE_OFF — only a recognized
#     on-spelling (1/true/yes/on, case-insensitive) disables the gate; any
#     other value, including a typo, keeps it active
#   - only fires its methodology-specific check when the content actually
#     names the Inmon/3NF token (inmon or 3nf, case-insensitive); if that
#     token is absent, this methodology wasn't the one picked, so exit 0
#     immediately (data-modeling-structure already required some
#     methodology-fit token to be present)
#   - built on core's gate-house standard library (issue-72 canon,
#     reference-only, never vendored): gate-lib.sh/gate-lib.py
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh"
gate_trap_fail_closed
set -uo pipefail

gate_kill_switch_active "${DATA_MODELING_INMON_GATE_OFF:-}" || { trap - EXIT; exit 0; }

payload="$(cat 2>/dev/null || true)"

root="${CLAUDE_PROJECT_DIR:-}"
[ -n "$root" ] && [ -d "$root" ] || root="$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)"

GATE_NAME="data-modeling-inmon" GATE_PAYLOAD="$payload" GATE_ROOT="$root" \
python3 <<'PY'
import sys
try:
    import importlib.util, os, re

    name = os.environ["GATE_NAME"]

    def deny(msg):
        sys.stderr.write("%s gate: refused — %s\n" % (name, msg))
        sys.exit(2)

    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec)
    _spec.loader.exec_module(gate_lib)

    raw = os.environ.get("GATE_PAYLOAD", "")
    ev = gate_lib.gate_parse_json_or_deny(raw, deny)

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if tool not in ("Write", "Edit", "MultiEdit", "NotebookEdit"):
        sys.exit(0)
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; cannot evaluate an in-scope write.")

    p = ti.get("file_path") or ti.get("notebook_path")
    if not isinstance(p, str) or not p:
        sys.exit(0)

    root = os.environ["GATE_ROOT"]
    rel = gate_lib.gate_normalize_path(root, p)
    if rel is None:
        sys.exit(0)

    is_proposal = bool(re.match(r'^docs/issue-[0-9]+/proposals/.+\.md$', rel))
    is_record = bool(re.match(r'^docs/issue-[0-9]+/reports/data-modeling\.md$', rel))
    if not (is_proposal or is_record):
        sys.exit(0)

    abs_path = p if os.path.isabs(p) else os.path.join(root, p)
    current = None
    if os.path.isfile(abs_path):
        try:
            with open(abs_path, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed." % rel)

    new_text, ok = gate_lib.gate_reconstruct_write(tool, ti, current)
    if not ok or new_text is None:
        deny(
            "this write targets %s but the gate cannot determine the resulting content "
            "from the tool input (tool=%r). Use Write for the full content, or an "
            "Edit/MultiEdit whose old_string matches the current content." % (rel, tool)
        )

    low = new_text.lower()
    lines = new_text.splitlines()

    if not re.search(r'\b(inmon|3nf)\b', low):
        sys.exit(0)

    def extract_scope(phrase_re):
        for i, l in enumerate(lines):
            if re.match(r'^#{1,6}\s', l) and re.search(phrase_re, l, re.I):
                buf = [l]
                j = i + 1
                while j < len(lines) and not re.match(r'^#{1,6}\s', lines[j]):
                    buf.append(lines[j])
                    j += 1
                return "\n".join(buf)
        for l in lines:
            if re.match(r'^\s*' + phrase_re + r'\s*:', l, re.I):
                return l
        for i, l in enumerate(lines):
            if re.search(phrase_re, l, re.I):
                for j in range(max(0, i - 2), i + 1):
                    if re.match(r'^#{1,6}\s', lines[j]):
                        return "\n".join(lines[max(0, i - 2):i + 1])
        return None

    missing = []

    if is_proposal:
        target_scope = extract_scope(r'normalization\s*target|target\s*(normal\s*)?form')
        form_re = r'\b(1nf|2nf|3nf|bcnf)\b'
        ok_target = bool(target_scope and re.search(form_re, target_scope, re.I))
        if not ok_target:
            ok_target = bool(re.search(r'target[^.\n]*' + form_re, low) or re.search(form_re + r'[^.\n]*form', low))
        if not ok_target:
            missing.append("normalization-target-named (intended normalization form: a Normalization Target heading/line naming 1nf/2nf/3nf/bcnf)")
    elif is_record:
        dev_scope = extract_scope(r'(normalization\s*)?deviations?')
        no_dev = bool(re.search(r'\bno\s+(normalization\s+)?deviations?\b', low))
        if not (dev_scope or no_dev):
            missing.append("normalization-deviations-stated (state normalization deviations as a heading/labeled line, or explicitly state \"no deviations\")")

    if missing:
        deny("blocked write to %s — missing: %s" % (rel, "; ".join(missing)))

    sys.exit(0)
except SystemExit:
    raise
except Exception as e:
    sys.stderr.write("data-modeling-inmon gate: fail-closed: internal error: %r\n" % (e,))
    sys.exit(2)
PY
rc=$?
exit "$rc"
