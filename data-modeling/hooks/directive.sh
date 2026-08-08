#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"
core_role_directive "YOU DECIDE: 데이터를 어떤 관계/스키마로 모델링할지" "USE_WHEN: 스키마 신설/변경이 걸릴 때" "PRODUCES (required record fields): conceptual/logical/physical model, ERD, data dictionary, normalization rationale (target form + deviations), migration plan (with rollback path), table_name, table_type (fact/dimension), grain, verdict (pass/fail)" "HAND-OFF: 파이프라인 이동/변환이 걸리면 → data-engineering | WRITE_SCOPE: [\"src/**\"] (migrations only)"
