#!/usr/bin/env bash
# Step 3h: Decision Matrix -- Eisenhower 2x2, each quadrant a FILTER() spill
# off Master Tasks' Urgent?/Important? checkboxes. Quadrant title cells are
# merged in the formatting step.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

echo "Writing Decision Matrix..." >&2

values_update "Decision Matrix!A1" '{"values": [["🔴 Do First — Urgent & Important"]]}'
values_update "Decision Matrix!H1" '{"values": [["🟡 Schedule — Important, Not Urgent"]]}'
values_update "Decision Matrix!A22" '{"values": [["🔵 Delegate — Urgent, Not Important"]]}'
values_update "Decision Matrix!H22" '{"values": [["⚪ Eliminate — Neither"]]}'

quadrant_formula() {
  # quadrant_formula <urgent TRUE|FALSE> <important TRUE|FALSE>
  printf "=IFERROR(FILTER('Master Tasks'!B:B,'Master Tasks'!M:M=%s,'Master Tasks'!N:N=%s),\"\")" "$1" "$2"
}

DO_FIRST="$(quadrant_formula TRUE TRUE)"
SCHEDULE="$(quadrant_formula FALSE TRUE)"
DELEGATE="$(quadrant_formula TRUE FALSE)"
ELIMINATE="$(quadrant_formula FALSE FALSE)"

values_update "Decision Matrix!A3" "{\"values\":[[\"$(jesc "$DO_FIRST")\"]]}"
values_update "Decision Matrix!H3" "{\"values\":[[\"$(jesc "$SCHEDULE")\"]]}"
values_update "Decision Matrix!A24" "{\"values\":[[\"$(jesc "$DELEGATE")\"]]}"
values_update "Decision Matrix!H24" "{\"values\":[[\"$(jesc "$ELIMINATE")\"]]}"
