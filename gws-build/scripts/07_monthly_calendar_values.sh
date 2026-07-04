#!/usr/bin/env bash
# Step 3e: Monthly Calendar. Layout (resolves the spec's B1/D1-vs-merged-title
# overlap by moving the selectors to row 1 with labels, and the merged title
# banner to row 2):
#   Row 1: A1 "Month:" label, B1 month dropdown, C1 "Year:" label, D1 year input
#   Row 2: merged title A2:G2 = "Monthly Calendar — <Month> <Year>"
#   Row 3: Sun..Sat day-of-week headers
#   Rows 4-9: 6-week grid; each cell = day number + task list for that date
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

echo "Writing Monthly Calendar..." >&2

MONTH_NAMES=(January February March April May June July August September October November December)
CUR_MONTH_NUM="$(date -d "$(today_date)" +%-m 2>/dev/null || date -j -f "%Y-%m-%d" "$(today_date)" +%-m)"
CUR_MONTH_NAME="${MONTH_NAMES[$((CUR_MONTH_NUM - 1))]}"
CUR_YEAR="$(date -d "$(today_date)" +%Y 2>/dev/null || date -j -f "%Y-%m-%d" "$(today_date)" +%Y)"

values_update "Monthly Calendar!A1:D1" "{
  \"values\": [[\"Month:\", \"$CUR_MONTH_NAME\", \"Year:\", $CUR_YEAR]]
}"

values_update "Monthly Calendar!A2" '{
  "values": [["=\"Monthly Calendar — \"&B1&\" \"&D1"]]
}'

values_update "Monthly Calendar!A3:G3" '{
  "values": [["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]]
}'

FIRST_OF_MONTH='DATEVALUE($B$1&" 1, "&$D$1)'
WEEKDAY_OFFSET="WEEKDAY(${FIRST_OF_MONTH},1)"
DAYS_IN_MONTH="DAY(EOMONTH(${FIRST_OF_MONTH},0))"

BODY_ROWS=""
for w in 0 1 2 3 4 5; do
  row_cells=""
  for c in 1 2 3 4 5 6 7; do
    day_expr="${c}-${WEEKDAY_OFFSET}+1+${w}*7"
    task_filter="IFERROR(TEXTJOIN(\", \",TRUE,FILTER('Master Tasks'!\$B:\$B,'Master Tasks'!\$I:\$I=DATE(\$D\$1,MONTH(${FIRST_OF_MONTH}),${day_expr}))),\"\")"
    cell_formula="=IF(OR(${day_expr}<1,${day_expr}>${DAYS_IN_MONTH}),\"\",${day_expr}&CHAR(10)&${task_filter})"
    esc="\"$(jesc "$cell_formula")\""
    if [[ -z "$row_cells" ]]; then row_cells="$esc"; else row_cells="$row_cells,$esc"; fi
  done
  if [[ -z "$BODY_ROWS" ]]; then BODY_ROWS="[$row_cells]"; else BODY_ROWS="$BODY_ROWS,[$row_cells]"; fi
done

values_update "Monthly Calendar!A4:G9" "{\"values\":[$BODY_ROWS]}"
