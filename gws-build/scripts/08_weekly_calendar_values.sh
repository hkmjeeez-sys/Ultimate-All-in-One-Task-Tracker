#!/usr/bin/env bash
# Step 3f: Weekly Calendar. B1 = week-start date input (defaults to this
# week's Monday). Row 3 = the 7 date headers. Row 4 holds the per-day task
# list formula; rows 4-15 are merged per column in the formatting step to
# give wrapped multi-task lists room to breathe.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

echo "Writing Weekly Calendar..." >&2

# ISO weekday: 1=Mon..7=Sun. Monday-of-this-week = today - (isoweekday - 1).
ISO_DOW="$(date -d "$(today_date)" +%u 2>/dev/null || date -j -f "%Y-%m-%d" "$(today_date)" +%u)"
MONDAY_OFFSET="-$((ISO_DOW - 1))"
MONDAY_DATE="$(offset_date "$MONDAY_OFFSET")"

values_update "Weekly Calendar!A1:B1" "{
  \"values\": [[\"Week Starting (Monday):\", \"$MONDAY_DATE\"]]
}"

values_update "Weekly Calendar!A3:G3" '{
  "values": [["=$B$1+0", "=$B$1+1", "=$B$1+2", "=$B$1+3", "=$B$1+4", "=$B$1+5", "=$B$1+6"]]
}'

COLS=(A B C D E F G)
ROW_CELLS=""
for col in "${COLS[@]}"; do
  f="=IFERROR(TEXTJOIN(CHAR(10),TRUE,FILTER('Master Tasks'!\$B:\$B,'Master Tasks'!\$I:\$I=${col}\$3)),\"\")"
  esc="\"$(jesc "$f")\""
  if [[ -z "$ROW_CELLS" ]]; then ROW_CELLS="$esc"; else ROW_CELLS="$ROW_CELLS,$esc"; fi
done

values_update "Weekly Calendar!A4:G4" "{\"values\":[[$ROW_CELLS]]}"
