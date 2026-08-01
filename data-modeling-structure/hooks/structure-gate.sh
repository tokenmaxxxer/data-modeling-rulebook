#!/usr/bin/env bash
# PreToolUse gate: methodology-agnostic proposal/record shape for data-modeling.
# Contract (frozen, shared by data-modeling-{inmon,kimball,datavault} gates):
#   - reads the tool-call JSON from stdin (Claude Code PreToolUse hook payload)
#   - only acts on Write/Edit/MultiEdit calls whose resolved file_path
#     matches this role's proposal or record surface; any other path is a
#     silent allow (exit 0)
#   - fail-closed: unparseable input, or an internal error, on an in-scope
#     path blocks (exit 2)
#   - kill switch: DATA_MODELING_STRUCTURE_GATE_OFF — only a recognized
#     on-spelling (1/true/yes/on, case-insensitive) disables the gate; any
#     other value, including a typo, keeps it active
#   - built on core's gate-house standard library (issue-72 canon,
#     reference-only, never vendored): gate-lib.sh/gate-lib.py
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh"
gate_trap_fail_closed
set -uo pipefail

gate_kill_switch_active "${DATA_MODELING_STRUCTURE_GATE_OFF:-}" || { trap - EXIT; exit 0; }

payload="$(cat 2>/dev/null || true)"

root="${CLAUDE_PROJECT_DIR:-}"
[ -n "$root" ] && [ -d "$root" ] || root="$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)"

GATE_NAME="data-modeling-structure" GATE_PAYLOAD="$payload" GATE_ROOT="$root" \
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

    def extract_scope(phrase_re):
        # 1) a Markdown heading naming the phrase -> everything until the
        #    next heading.
        for i, l in enumerate(lines):
            if re.match(r'^#{1,6}\s', l) and re.search(phrase_re, l, re.I):
                buf = [l]
                j = i + 1
                while j < len(lines) and not re.match(r'^#{1,6}\s', lines[j]):
                    buf.append(lines[j])
                    j += 1
                return "\n".join(buf)
        # 2) a labeled line ("Phrase: ...") -> that line.
        for l in lines:
            if re.match(r'^\s*' + phrase_re + r'\s*:', l, re.I):
                return l
        # 3) within 2 lines of a `## ` section-boundary keyword.
        for i, l in enumerate(lines):
            if re.search(phrase_re, l, re.I):
                for j in range(max(0, i - 2), i + 1):
                    if re.match(r'^#{1,6}\s', lines[j]):
                        return "\n".join(lines[max(0, i - 2):i + 1])
        return None

    def adjacent(a, b, window=3):
        la = [i for i, l in enumerate(lines) if re.search(a, l, re.I)]
        lb = [i for i, l in enumerate(lines) if re.search(b, l, re.I)]
        for i in la:
            for j in lb:
                if abs(i - j) <= window:
                    return True
        for para in re.split(r'\n\s*\n', new_text):
            if re.search(a, para, re.I) and re.search(b, para, re.I):
                return True
        return False

    missing = []
    if is_proposal:
        if "reports/data-modeling/survey" not in low:
            missing.append("survey-referenced (must cite docs/issue-<n>/reports/data-modeling/survey)")
        if not re.search(r'\b(conceptual|logical|physical)\b', low):
            missing.append("layers-named (at least one of conceptual/logical/physical)")
        alt_scope = extract_scope(r'alternatives?\s*(considered)?')
        if not alt_scope:
            missing.append("alternatives-considered (as a heading or its own labeled line, not a bare mention)")
        oq_scope = extract_scope(r'open\s*questions?')
        if not oq_scope:
            missing.append("open-questions (as a heading or its own labeled line, not a bare mention)")
        fit_scope = extract_scope(r'methodology\s*fit')
        fit_tokens = r'\b(inmon|3nf|kimball|dimensional model|star schema|data vault|no schema decision|routed to)\b'
        if not (fit_scope and re.search(fit_tokens, fit_scope, re.I)):
            missing.append("methodology-fit-named (inmon/3nf, kimball/dimensional model/star schema, data vault, or an explicit no-fit statement, named in a Methodology Fit heading/line — a bare mention elsewhere in the document does not count)")
    elif is_record:
        if re.search(r'\bconceptual\b', low) and re.search(r'\blogical\b', low) and re.search(r'\bphysical\b', low):
            pass
        elif re.search(r'\b(skip|not applicable|n/a)\b', low):
            pass
        else:
            missing.append("layers-or-justified-skip (name conceptual/logical/physical, or justify skipping one)")
        if not extract_scope(r'data\s*dictionary'):
            missing.append("data-dictionary (named as a heading or its own labeled line, distinct from ERD)")
        if not extract_scope(r'migration\s*plan'):
            missing.append("migration-rollback: migration plan (as a heading or its own labeled line)")
        if not extract_scope(r'rollback'):
            missing.append("migration-rollback: rollback (as a heading or its own labeled line)")
        if re.search(r'\bpipeline\b|\betl\b', low):
            if not adjacent(r'hand-off', r'data-engineering', window=3):
                missing.append("decides-boundary: pipeline/ETL movement mentioned without a hand-off note to data-engineering within the same paragraph or nearby lines")

    if missing:
        deny("blocked write to %s — missing: %s" % (rel, "; ".join(missing)))

    sys.exit(0)
except SystemExit:
    raise
except Exception as e:
    sys.stderr.write("data-modeling-structure gate: fail-closed: internal error: %r\n" % (e,))
    sys.exit(2)
PY
rc=$?
exit "$rc"
