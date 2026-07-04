#!/usr/bin/env bash
# Step 3d: Kanban Board -- a live, read-only FILTER() view off Master Tasks
# Status column. Row 1 = explanatory note (merged in formatting step), row 2 =
# lane headers, row 3+ = spilling FILTER formulas per lane.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

echo "Writing Kanban Board..." >&2

values_update "Kanban Board!A1" '{
  "values": [["Live view of Master Tasks — change a task'"'"'s Status there to move it here."]]
}'

values_update "Kanban Board!A2:G2" '{
  "values": [["🔲 Not Started", "", "🔵 In Progress", "", "🟡 On Hold", "", "🟢 Completed"]]
}'

lane_formula() {
  # lane_formula <status literal>
  local status="$1"
  printf '=IFERROR(FILTER(%s,%s),"")' \
    "'Master Tasks'!B2:B&\" — \"&TEXT('Master Tasks'!I2:I,\"MMM d\")" \
    "'Master Tasks'!E2:E=\"${status}\""
}

NOT_STARTED="$(lane_formula "Not Started")"
IN_PROGRESS="$(lane_formula "In Progress")"
ON_HOLD="$(lane_formula "On Hold")"
COMPLETED="$(lane_formula "Completed")"

values_update "Kanban Board!A3" "{\"values\":[[\"$(jesc "$NOT_STARTED")\"]]}"
values_update "Kanban Board!C3" "{\"values\":[[\"$(jesc "$IN_PROGRESS")\"]]}"
values_update "Kanban Board!E3" "{\"values\":[[\"$(jesc "$ON_HOLD")\"]]}"
values_update "Kanban Board!G3" "{\"values\":[[\"$(jesc "$COMPLETED")\"]]}"
