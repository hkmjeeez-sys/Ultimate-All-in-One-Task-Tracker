#!/usr/bin/env bash
# Step 3j (last data step): Dashboard. The build prompt gives exact helper
# ranges for 3 of the 5 charts (E2:F6, H2:I7, K2:L6) but leaves notification/
# KPI/feed cell layout to our discretion -- this script places them in the
# left sidebar (columns A-D) so they never collide with the helper tables and
# chart anchors that live in columns E onward (per Section 7 chart anchors:
# G6, K6, O6, S6, G22, O22, G38).
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

echo "Writing Dashboard..." >&2

values_update "Dashboard!A1" '{
  "values": [["✨ Ultimate All-in-One Task Tracker — Dashboard"]]
}'

# ---- Notifications (A3:D5) --------------------------------------------------
N1='="🔸 "&COUNTIFS('"'"'Master Tasks'"'"'!I:I,TODAY()+1,'"'"'Master Tasks'"'"'!E:E,"<>Completed")&" tasks due tomorrow — stay on track!"'
N2='="✅ Completed "&TEXT(IFERROR(COUNTIF('"'"'Master Tasks'"'"'!E:E,"Completed")/COUNTA('"'"'Master Tasks'"'"'!B2:B),0),"0%")&" of tasks ("&COUNTIF('"'"'Master Tasks'"'"'!E:E,"Completed")&" done, "&(COUNTA('"'"'Master Tasks'"'"'!B2:B)-COUNTIF('"'"'Master Tasks'"'"'!E:E,"Completed"))&" to go)"'
N3='="⚠️ Overdue tasks: "&COUNTIFS('"'"'Master Tasks'"'"'!I:I,"<"&TODAY(),'"'"'Master Tasks'"'"'!E:E,"<>Completed",'"'"'Master Tasks'"'"'!E:E,"<>Cancelled")&" — knock a few out today!"'

values_update "Dashboard!A3" "{\"values\":[[\"$(jesc "$N1")\"]]}"
values_update "Dashboard!A4" "{\"values\":[[\"$(jesc "$N2")\"]]}"
values_update "Dashboard!A5" "{\"values\":[[\"$(jesc "$N3")\"]]}"

# ---- KPI cards (label row, value row, x6, A7:A18) --------------------------
values_update "Dashboard!A7:A18" '{
  "values": [
    ["TOTAL TASKS"],
    ["=COUNTA('"'"'Master Tasks'"'"'!B2:B)"],
    ["COMPLETION %"],
    ["=IFERROR(COUNTIF('"'"'Master Tasks'"'"'!E:E,\"Completed\")/COUNTA('"'"'Master Tasks'"'"'!B2:B),0)"],
    ["IN PROGRESS"],
    ["=COUNTIF('"'"'Master Tasks'"'"'!E:E,\"In Progress\")"],
    ["OVERDUE"],
    ["=COUNTIFS('"'"'Master Tasks'"'"'!I:I,\"<\"&TODAY(),'"'"'Master Tasks'"'"'!E:E,\"<>Completed\",'"'"'Master Tasks'"'"'!E:E,\"<>Cancelled\")"],
    ["DUE TODAY"],
    ["=COUNTIFS('"'"'Master Tasks'"'"'!I:I,TODAY(),'"'"'Master Tasks'"'"'!E:E,\"<>Completed\")"],
    ["DUE THIS WEEK"],
    ["=COUNTIFS('"'"'Master Tasks'"'"'!I:I,\">\"&TODAY(),'"'"'Master Tasks'"'"'!I:I,\"<=\"&TODAY()+7,'"'"'Master Tasks'"'"'!E:E,\"<>Completed\")"]
  ]
}'

# ---- Today / Overdue feeds --------------------------------------------------
values_update "Dashboard!A20" '{"values": [["📌 TODAY"]]}'
TODAY_FEED='=IFERROR(FILTER('"'"'Master Tasks'"'"'!B:B&" — "&'"'"'Master Tasks'"'"'!D:D,'"'"'Master Tasks'"'"'!I:I=TODAY(),'"'"'Master Tasks'"'"'!E:E<>"Completed",'"'"'Master Tasks'"'"'!E:E<>"Cancelled"),"Nothing due today 🎉")'
values_update "Dashboard!A21" "{\"values\":[[\"$(jesc "$TODAY_FEED")\"]]}"

values_update "Dashboard!A27" '{"values": [["⏰ OVERDUE"]]}'
OVERDUE_FEED='=IFERROR(FILTER(TEXT(TODAY()-'"'"'Master Tasks'"'"'!I:I,"0")&"d — "&'"'"'Master Tasks'"'"'!B:B,'"'"'Master Tasks'"'"'!I:I<TODAY(),'"'"'Master Tasks'"'"'!I:I<>"",'"'"'Master Tasks'"'"'!E:E<>"Completed",'"'"'Master Tasks'"'"'!E:E<>"Cancelled"),"No overdue tasks ✅")'
values_update "Dashboard!A28" "{\"values\":[[\"$(jesc "$OVERDUE_FEED")\"]]}"

# ---- Chart helper ranges (Section 7) ----------------------------------------
values_update "Dashboard!E1:F6" '{
  "values": [
    ["Status", "Count"],
    ["Not Started", "=COUNTIF('"'"'Master Tasks'"'"'!E:E,\"Not Started\")"],
    ["In Progress", "=COUNTIF('"'"'Master Tasks'"'"'!E:E,\"In Progress\")"],
    ["On Hold",     "=COUNTIF('"'"'Master Tasks'"'"'!E:E,\"On Hold\")"],
    ["Completed",   "=COUNTIF('"'"'Master Tasks'"'"'!E:E,\"Completed\")"],
    ["Cancelled",   "=COUNTIF('"'"'Master Tasks'"'"'!E:E,\"Cancelled\")"]
  ]
}'

values_update "Dashboard!H1:I7" '{
  "values": [
    ["Category", "Count"],
    ["Work",     "=COUNTIF('"'"'Master Tasks'"'"'!D:D,\"Work\")"],
    ["Growth",   "=COUNTIF('"'"'Master Tasks'"'"'!D:D,\"Growth\")"],
    ["Finance",  "=COUNTIF('"'"'Master Tasks'"'"'!D:D,\"Finance\")"],
    ["Home",     "=COUNTIF('"'"'Master Tasks'"'"'!D:D,\"Home\")"],
    ["Personal", "=COUNTIF('"'"'Master Tasks'"'"'!D:D,\"Personal\")"],
    ["Errands",  "=COUNTIF('"'"'Master Tasks'"'"'!D:D,\"Errands\")"]
  ]
}'

values_update "Dashboard!K1:L6" '{
  "values": [
    ["Priority", "Count"],
    ["Very High", "=COUNTIF('"'"'Master Tasks'"'"'!F:F,\"Very High\")"],
    ["High",      "=COUNTIF('"'"'Master Tasks'"'"'!F:F,\"High\")"],
    ["Medium",    "=COUNTIF('"'"'Master Tasks'"'"'!F:F,\"Medium\")"],
    ["Low",       "=COUNTIF('"'"'Master Tasks'"'"'!F:F,\"Low\")"],
    ["Very Low",  "=COUNTIF('"'"'Master Tasks'"'"'!F:F,\"Very Low\")"]
  ]
}'

# Priority x Category cross-tab helper for the stacked column chart (N1:S7)
values_update "Dashboard!N1:S1" '{"values": [["", "Very High", "High", "Medium", "Low", "Very Low"]]}'

CATEGORIES=(Work Growth Finance Home Personal Errands)
PRIORITIES=("Very High" High Medium Low "Very Low")
CROSS_ROWS=""
for i in "${!CATEGORIES[@]}"; do
  row=$((i + 2))
  cat="${CATEGORIES[$i]}"
  cells="\"${cat}\""
  for p in "${PRIORITIES[@]}"; do
    f="=COUNTIFS('Master Tasks'!\$D:\$D,\"${cat}\",'Master Tasks'!\$F:\$F,\"${p}\")"
    cells="$cells,\"$(jesc "$f")\""
  done
  if [[ -z "$CROSS_ROWS" ]]; then CROSS_ROWS="[$cells]"; else CROSS_ROWS="$CROSS_ROWS,[$cells]"; fi
done
values_update "Dashboard!N2:S7" "{\"values\":[$CROSS_ROWS]}"
