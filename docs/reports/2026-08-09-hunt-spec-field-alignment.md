---
proposal: docs/issue-16/proposals/spec-field-alignment.md
---

# Hunt record — spec-field-alignment

## after-proposal — stance 4: assume the write set cannot carry this work — find the path the build will need that the proposal does not list

Verdict: NO FINDING
Seed: docs/issue-16/proposals/spec-field-alignment.md (frozen write set: README.md, data-modeling/hooks/directive.sh, data-modeling-structure/hooks/structure-gate.sh, data-modeling-structure/tests/structure-gate-tests.sh, docs/specs/record-fields-terminal-states.json, docs/handbooks/run-all-gate-tests.md)
cap_seconds: 120
tier: default
diff_stat_lines: ~300 (two new docs files, ~150 lines each)
started_at: 2026-08-09T00:00:00Z
ended_at: 2026-08-09T00:20:00Z

Checked and ruled out as candidates for a missing path:
- `record-fields-gate.sh` is core canon, invoked globally (not wired per-plugin in `hooks.json`); no `hooks.json` edit is needed to make it read the new `docs/specs/record-fields-terminal-states.json` — confirmed by reading `core/hooks/record-fields-gate.sh` (`override_path = posixpath.join(root, "docs/specs/record-fields-terminal-states.json")`, read unconditionally, no registration file). `ROLE_TO_KIND["implementation"] = "coding-record"` also confirmed, matching the proposal's own reasoning for why `coding-record` is the right kind key.
- `.claude-plugin/marketplace.json` lists plugins only (`source`/`name`/`description`); it has no per-file manifest that a new `docs/specs/*.json` or edited hook body would need to be added to. `grep -n "record-fields\|structure-gate\|docs/specs" .claude-plugin/marketplace.json` returns nothing to update.
- No `canon-scripts.md` exists in this repo.
- `structure-gate.sh`'s field checks are inline `missing.append(...)` calls with no separate config/registry file — the new table_name/table_type/grain/verdict checks (proposal step 3) don't need any file beyond the script itself.
- Ran `python3 core/hooks/tests/gate-prose-coverage-check.py .` against this repo as-is: `summary: 0 violation(s), 0 gate(s) with needles checked` — this tool's `has_any(...)`/dict-key/field-key needle extraction finds nothing in any of this rulebook's gate scripts (their checks use a different code shape), so it does not apply here regardless of the proposal's planned edits, and it is not invoked from `tests/run-all-gate-tests.sh` or anything else in this repo (`grep -rn "gate-prose-coverage" .` empty) — not a real build dependency.
- `core/hooks/tests/canon-manifest.txt` lists only `record-fields-gate.sh` as canon; `structure-gate.sh` is not canon-tracked, so compliance-check's canon-duplication check is unaffected by editing it.
- `docs/handbooks/run-all-gate-tests.md` currently states no numeric test count (`grep -n structure-gate-tests\|test count docs/handbooks/*.md README.md` found only the file-path bullet), so step 6's "update only if a stated number changes" is plausibly a no-op, not evidence of a missing file elsewhere.

No reproduction of a build-required path outside the frozen write set was found. Returning NO FINDING per the one-repro rule.
