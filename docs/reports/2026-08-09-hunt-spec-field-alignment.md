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

## before-landing — stance 1: assume this change and another plugin's rule cancel each other — find the pair

Verdict: FINDING — the new unconditional `table_type: fact|dimension` check in structure-gate.sh's is_record branch structurally conflicts with data-modeling-datavault's own record-scope check, which accepts hub/satellite/link vocabulary (not fact/dimension) for the same record file.
Kind: composition
Seed: data-modeling-structure/hooks/structure-gate.sh (uncommitted diff, lines 179-192, adding table_name/table_type/grain/verdict checks unconditionally to is_record)
cap_seconds: 120
tier: default
diff_stat_lines: 58 (4 files: README.md +24, structure-gate.sh +14, structure-gate-tests.sh +20/-2, directive.sh +1/-1)
started_at: 2026-08-09T00:00:00Z
ended_at: 2026-08-09T00:20:00Z

### Reproduce
Built a PreToolUse Write payload targeting the record path `data-modeling.md` under an issue reports tree, whose content is a legitimate Data Vault record: names hub/satellite/link, states data dictionary/migration plan/rollback, justifies skipping conceptual/logical/physical layers, and supplies table_name/grain/verdict fields -- but has no `table_type: fact|dimension` line (Data Vault has no fact/dimension distinction; it has hub/link/satellite).

```
cat payload.json | bash data-modeling-datavault/hooks/datavault-gate.sh   # datavault-gate's own record check
cat payload.json | bash data-modeling-structure/hooks/structure-gate.sh   # new shared structure-gate check
```

### Observed
```
== datavault ==
datavault_rc=0
== structure ==
data-modeling-structure gate: refused - blocked write to <record path> - missing: table_type (required record field, labeled line 'table_type: fact|dimension')
structure_rc=2
```
datavault-gate.sh allows the write (it only requires hub/satellite/link, which the record has); structure-gate.sh unconditionally denies the same write because it now requires `table_type` to be literally `fact` or `dimension`. Since structure-gate.sh's contract header states it is shared by all three data-modeling methodology gates and gates the same record path, every Data Vault record permitted by its own methodology gate is permanently blocked by the sibling structure gate -- there is no vocabulary a Data Vault author can write in `table_type:` that is both true to the methodology and satisfies structure-gate's fact/dimension-only enum.

### Expected
The table_type check (or its accepted value set) should account for the methodology actually declared in the record (e.g. accept hub/link/satellite when the record is a Data Vault record, mirroring how the pipeline/ETL hand-off check and the pre-existing layers-or-justified-skip check are conditional/methodology-aware), instead of unconditionally requiring `fact` or `dimension` for every record regardless of which sibling methodology gate already accepted it.
