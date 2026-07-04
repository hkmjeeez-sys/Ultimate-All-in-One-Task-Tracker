#!/usr/bin/env bash
# Step 3i: Analytics -- 8 weekly buckets feeding the Dashboard timeline chart
# and the Analytics trend chart, plus a category breakdown table. Must be
# populated before the Dashboard/Analytics charts are added.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

echo "Writing Analytics..." >&2

values_update "Analytics!A1:D1" '{
  "values": [["Week Starting", "Week Ending", "Tasks Completed", "Tasks Created"]]
}'

BODY_ROWS=""
for row in $(seq 2 9); do
  # row 9 = this week's Monday (0 weeks back); row 2 = 7 weeks back (oldest of 8 buckets)
  a="=TODAY()-WEEKDAY(TODAY(),2)+1-7*(9-${row})"
  b="=A${row}+6"
  c="=COUNTIFS('Master Tasks'!J:J,\">=\"&A${row},'Master Tasks'!J:J,\"<=\"&B${row})"
  d="=COUNTIFS('Master Tasks'!H:H,\">=\"&A${row},'Master Tasks'!H:H,\"<=\"&B${row})"
  row_json=$(printf '["%s","%s","%s","%s"]' "$(jesc "$a")" "$(jesc "$b")" "$(jesc "$c")" "$(jesc "$d")")
  if [[ -z "$BODY_ROWS" ]]; then BODY_ROWS="$row_json"; else BODY_ROWS="$BODY_ROWS,$row_json"; fi
done

values_update "Analytics!A2:D9" "{\"values\":[$BODY_ROWS]}"

# Category breakdown table (F1:H7)
values_update "Analytics!F1:H1" '{"values": [["Category", "Count", "% of Total"]]}'

CATEGORIES=(Work Growth Finance Home Personal Errands)
CAT_ROWS=""
for i in "${!CATEGORIES[@]}"; do
  row=$((i + 2))
  cat="${CATEGORIES[$i]}"
  g="=COUNTIF('Master Tasks'!D:D,\"${cat}\")"
  h="=IFERROR(G${row}/COUNTA('Master Tasks'!\$B\$2:\$B),0)"
  row_json=$(printf '["%s","%s","%s"]' "$(jesc "$cat")" "$(jesc "$g")" "$(jesc "$h")")
  if [[ -z "$CAT_ROWS" ]]; then CAT_ROWS="$row_json"; else CAT_ROWS="$CAT_ROWS,$row_json"; fi
done

values_update "Analytics!F2:H7" "{\"values\":[$CAT_ROWS]}"
