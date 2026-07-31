---
Subject: issue-2
---

# Current-state survey — issue-2

## This repo (`data-modeling-rulebook`), as of `23aabd5`

| File | Role |
|---|---|
| `data-modeling/agents/warrant-hunter.md` | Local copy of the hunt agent, with data-modeling's own mandate text ("데이터를 어떤 관계/스키마로 모델링할지") pasted in. |
| `data-modeling/hooks/directive.sh` | SessionStart directive. Boilerplate (trap/kill-switch/CLAUDE_ROLE guard/heredoc open-close) byte-identical to every other rulebook's copy (verified against `api-design-rulebook`). Role-unique content: YOU DECIDE / USE_WHEN / PRODUCES / WRITE_SCOPE / HAND-OFF values, plus a BOUNDARY CASE paragraph that is itself boilerplate (identical across rulebooks, not role-unique). |
| `data-modeling/hooks/trailer-gate.sh` | Local copy, comment says "role-agnostic," env-driven only by `DATA_MODELING_CYCLE_OFF`. |
| `data-modeling/hooks/record-fields-gate.sh` | Local copy enforcing THIS repo's own `produces` field set (`schema-erd`, `migration-plan`, `normalization-rationale`) as literal substring checks against `docs/issue-<n>/reports/data-modeling.md`. |
| `data-modeling/hooks/handbook-trigger-gate.sh` | Local copy; body is `exit 0` — a placeholder, never hardened. |
| `data-modeling/hooks/hooks.json` | Wires all 4 files above as SessionStart/PreToolUse hooks. |

No `core/hooks/tests/stub-check.sh` or `parse-check.sh` present locally yet — this repo predates issue-63/#66's core promotion (scaffolded at issue-170, before the canon existed).

## Core canon, as landed on `tokenmaxxxer/tokenmaxxxer-core@main`

- `core/hooks/hooks.json` registers `board-gate.sh`, `approval-gate.sh`,
  `gh-guard.sh`, `trailer-gate.sh`, `record-fields-gate.sh`,
  `handbook-trigger-gate.sh` globally (`PreToolUse` matcher `.*`) — these
  fire for every plugin install once `core` is installed, no per-rulebook
  registration needed.
- `core/hooks/lib/role-directive.sh` exports `core_role_directive(you_decide,
  use_when, produces, hand_off)`, reading `CLAUDE_ROLE` and
  `<ROLE>_CYCLE_OFF` itself. A rulebook's own `directive.sh` becomes: source
  this file, set the 4 values, call the function. Nothing else.
- `core/hooks/tests/stub-check.sh`: (a) fails if any of
  `trailer-gate.sh`/`record-fields-gate.sh`/`handbook-trigger-gate.sh`/`parse-check.sh`
  is found anywhere under a rulebook's `hooks/` tree (presence alone is the
  failure, content irrelevant); (b) structurally validates `directive.sh` —
  every non-blank/non-comment line must be the source line, a plain
  `NAME=value` assignment, or the `core_role_directive` call; anything else
  (a `case`, a guard `[ ... ]`, a raw `cat`/`echo`) fails as "regrown
  boilerplate."
- `core/hooks/record-fields-gate.sh` (canon version) enforces contract §20's
  generic record shape (what/why/upstream/loop_state/open-findings) against
  `docs/issue-<n>/reports/${CLAUDE_ROLE}.md` — **not** this repo's specific
  `produces` field names. Per-role divergence in which `loop_state` values
  count as terminal is preserved via `RECORD_FIELDS_TERMINAL_STATES`
  (space-separated, default `landed`), injected through the rulebook's own
  `hooks.json` env, not through a file copy.
- `warrant/` is a standalone, separately-installed plugin
  (`claude plugin install warrant@tokenmaxxxer-core`), not something a
  rulebook vendors. `warrant/agents/warrant-hunter.md` is fully generic —
  no role-specific mandate text anywhere in it; it reads whatever
  `CLAUDE_ROLE`/the dispatching session gives it in-prompt at hunt time.
  Nothing in this repo needs to reference it beyond the install instruction.
- `core/contract/role-handoff-contract.md` has no `WRITE_SCOPE` or
  "BOUNDARY CASE" concept at all — confirmed by grep. These two elements of
  the current local `directive.sh` are not contract-level fields; they were
  added locally at issue-170 scaffolding time and core's promotion did not
  carry them forward.

## Order constraint check

Issue #2 states this switch must land before this rulebook's own
"rulebook maturation" phase 2. No such phase-2 work has started in this
repo (single commit on `main`), so no ordering conflict exists yet.

## Sibling rulebooks

None of the sampled siblings (`api-design`, `accessibility`, `architecture`)
have converted to the canon-stub form yet — this repo's conversion would be
first, with no already-approved stub to copy verbatim beyond
`role-directive.sh`'s own usage docstring.
