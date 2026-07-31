---
Subject: issue-1
---

# Current-state survey — issue-1

## This repo, as of `1ae3f03` (post core-canon switch, issue-2 merged)

| File | Role | Bearing on this issue |
|---|---|---|
| `data-modeling/hooks/directive.sh` | Canon stub: sources `core/hooks/lib/role-directive.sh`, calls `core_role_directive` with 4 fixed args (YOU DECIDE / USE_WHEN / PRODUCES / HAND-OFF). | `PRODUCES` currently reads `"schema/ERD, migration plan, normalization rationale"` — free text, not a methodology or a required-field checklist. This is the field phase 2 will need to tighten. |
| `data-modeling/hooks/hooks.json` | Wires `directive.sh` to `SessionStart` only. No local gate files (trailer/record-fields/handbook-trigger) — those are core canon now, fired globally once `core@tokenmaxxxer-core` is installed. | Any phase-2 "gate" this issue proposes cannot be a new local gate script (would violate the canon-stub constraint issue-2 just enforced) — it must ride on values passed into `core_role_directive`, `RECORD_FIELDS_TERMINAL_STATES`-style env injection, or a new field on the core record-fields contract if one is needed. |
| `data-modeling/.claude-plugin/plugin.json` | Plugin manifest; `description` echoes the same decides/use_when/hand-off text. | Would need the same free-text update if PRODUCES changes. |
| `README.md` | Documents decides/use_when/produces/write_scope/hand-off, install steps, BOUNDARY CASE. No section on *how* a schema decision should be produced (no methodology, no required proposal sections). | This is the natural home for phase-2's adopted methodology once ratified — currently silent on it entirely. |
| `docs/specs/approvers.md` | `JiwonJung94` only — single-account mode applies (issue author == sole approver). | Phase 2 opens via the `APPROVE issue-1/data-modeling` issue-comment path, not a PR-review Approve from a second account. |

No prior `docs/issue-*/reports/data-modeling.md` record exists yet (repo has never done phase-2 work under this role) — there is no existing deliverable to compare against; this issue is greenfield for both the proposal-writing norm and the deliverable norm.

## Constraint recap (from the issue body)

- warrant-hunter stays a core-canon reference (already true post-issue-2 — nothing to touch here).
- "record 규율·문서화 의무는 기존 강화 조항 유지" — whatever record-discipline strengthening already exists (the core canon's generic record shape: what/why/upstream/loop_state/open-findings, contract §20) must not be weakened by this issue's changes; this issue can only *add* domain-specific required fields on top, not remove the generic ones.

## Gaps this issue must close

1. **No methodology named anywhere.** `directive.sh`'s `PRODUCES` line lists artifact *names* (schema/ERD, migration plan, normalization rationale) but never says which modeling methodology governs how those are produced (dimensional vs. normalized vs. hybrid), nor which model layers (conceptual/logical/physical) are mandatory.
2. **No phase-1 proposal-writing norm for this role specifically.** The only phase-1 precedent in this repo is issue-2's `core-canon-switch.md`, which is an infra-migration proposal, not a schema-design proposal — it has no dimensional-vs-normalized tradeoff section, no ERD, no data-dictionary norm, because issue-2 wasn't a data-modeling deliverable itself.
3. **No phase-2 record template/checklist.** `record-fields-gate.sh` (core canon) only checks the generic contract §20 shape; it has no knowledge of what "normalization rationale" or "migration plan" must *contain* to count as complete.
4. **`RECORD_FIELDS_TERMINAL_STATES` and any future domain-specific env injection point are unused** — the plugin reflection plan (part (d) of the issue) has a concrete, already-precedented mechanism (issue-2's survey documents it) to hang new required-field enforcement on, without violating the canon-stub structural check.
