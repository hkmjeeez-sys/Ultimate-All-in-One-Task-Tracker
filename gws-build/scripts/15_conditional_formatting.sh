#!/usr/bin/env bash
# Step 6 of the build order: conditional formatting (Section 8). Rule
# "index" is per-sheet, so each sheet's rule list restarts at 0.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

echo "Building conditional formatting requests..." >&2

REQS=()
add() { REQS+=("$1"); }

# =============================================================================
# Master Tasks
# =============================================================================
# 1. Overdue flag on column I (Due Date) -- priority 0 (highest)
add "$(req_cf_custom "$SHEET_MASTER_TASKS" 2 500 9 9 \
  '=AND($I2<TODAY(),$E2<>"Completed",$E2<>"Cancelled")' \
  "$COLOR_STATUS_CANCELLED_BG" "$COLOR_PRIORITY_VERYHIGH" - 0)"

# 2. Priority column F -- 5 TEXT_EQ rules, light-tint bg, bold text, priority 1-5
add "$(req_cf_text_eq "$SHEET_MASTER_TASKS" 2 500 6 6 "Very High" "$(hex_tint "$COLOR_PRIORITY_VERYHIGH" 0.82)" "$COLOR_PRIORITY_VERYHIGH" true 1)"
add "$(req_cf_text_eq "$SHEET_MASTER_TASKS" 2 500 6 6 "High"      "$(hex_tint "$COLOR_PRIORITY_HIGH" 0.82)"     "$COLOR_PRIORITY_HIGH" true 2)"
add "$(req_cf_text_eq "$SHEET_MASTER_TASKS" 2 500 6 6 "Medium"    "$(hex_tint "$COLOR_PRIORITY_MEDIUM" 0.82)"   "$COLOR_PRIORITY_MEDIUM" true 3)"
add "$(req_cf_text_eq "$SHEET_MASTER_TASKS" 2 500 6 6 "Low"       "$(hex_tint "$COLOR_PRIORITY_LOW" 0.82)"      "$COLOR_PRIORITY_LOW" true 4)"
add "$(req_cf_text_eq "$SHEET_MASTER_TASKS" 2 500 6 6 "Very Low"  "$(hex_tint "$COLOR_PRIORITY_VERYLOW" 0.82)"  "$COLOR_PRIORITY_VERYLOW" true 5)"

# 3. Status column E -- 5 TEXT_EQ rules, priority 6-10
add "$(req_cf_text_eq "$SHEET_MASTER_TASKS" 2 500 5 5 "Not Started" "$COLOR_STATUS_NOTSTARTED_BG" "$COLOR_STATUS_NOTSTARTED_TEXT" - 6)"
add "$(req_cf_text_eq "$SHEET_MASTER_TASKS" 2 500 5 5 "In Progress" "$COLOR_STATUS_INPROGRESS_BG" "$COLOR_STATUS_INPROGRESS_TEXT" - 7)"
add "$(req_cf_text_eq "$SHEET_MASTER_TASKS" 2 500 5 5 "On Hold"     "$COLOR_STATUS_ONHOLD_BG"     "$COLOR_STATUS_ONHOLD_TEXT" - 8)"
add "$(req_cf_text_eq "$SHEET_MASTER_TASKS" 2 500 5 5 "Completed"   "$COLOR_STATUS_COMPLETED_BG"  "$COLOR_STATUS_COMPLETED_TEXT" - 9)"
add "$(req_cf_text_eq "$SHEET_MASTER_TASKS" 2 500 5 5 "Cancelled"   "$COLOR_STATUS_CANCELLED_BG"  "$COLOR_STATUS_CANCELLED_TEXT" - 10)"

# 4. Completion % gradient (column L)
add "$(req_cf_gradient "$SHEET_MASTER_TASKS" 2 500 12 12 "$COLOR_GRADIENT_MIN" "$COLOR_GRADIENT_MID" "$COLOR_GRADIENT_MAX" 11)"

# =============================================================================
# Gantt Chart -- one CUSTOM_FORMULA rule per category (also gates on date range)
# =============================================================================
gantt_bar_formula() {
  local cat="$1"
  printf '=AND($B2="%s",C$1>=VLOOKUP($A2,'"'"'Master Tasks'"'"'!$B:$I,7,FALSE),C$1<=VLOOKUP($A2,'"'"'Master Tasks'"'"'!$B:$I,8,FALSE))' "$cat"
}
add "$(req_cf_custom "$SHEET_GANTT" 2 200 3 62 "$(gantt_bar_formula "Work")"     "$COLOR_CAT_WORK" "$COLOR_WHITE" - 0)"
add "$(req_cf_custom "$SHEET_GANTT" 2 200 3 62 "$(gantt_bar_formula "Growth")"   "$COLOR_CAT_GROWTH" "$COLOR_WHITE" - 1)"
add "$(req_cf_custom "$SHEET_GANTT" 2 200 3 62 "$(gantt_bar_formula "Finance")"  "$COLOR_CAT_FINANCE" "$COLOR_WHITE" - 2)"
add "$(req_cf_custom "$SHEET_GANTT" 2 200 3 62 "$(gantt_bar_formula "Home")"     "$COLOR_CAT_HOME" "$COLOR_WHITE" - 3)"
add "$(req_cf_custom "$SHEET_GANTT" 2 200 3 62 "$(gantt_bar_formula "Personal")" "$COLOR_CAT_PERSONAL" "$COLOR_WHITE" - 4)"
add "$(req_cf_custom "$SHEET_GANTT" 2 200 3 62 "$(gantt_bar_formula "Errands")"  "$COLOR_CAT_ERRANDS" "$COLOR_WHITE" - 5)"

# =============================================================================
# Weekly Calendar -- highlight today's date header (relative formula: applies
# per-column since Sheets evaluates the top-left-relative formula per cell)
# =============================================================================
add "$(req_cf_custom "$SHEET_WEEKLY_CAL" 3 3 1 7 '=A3=TODAY()' "$COLOR_HEADER_BG" - true 0)"

# =============================================================================
# Monthly Calendar -- highlight today's cell in the 6x7 grid. Self-contained
# via COLUMN()/ROW() so one rule covers the whole grid (mirrors the day-number
# formula written in 07_monthly_calendar_values.sh).
# =============================================================================
MONTHLY_TODAY_FORMULA='=AND($B$1=TEXT(TODAY(),"mmmm"),$D$1=YEAR(TODAY()),(COLUMN()-WEEKDAY(DATEVALUE($B$1&" 1, "&$D$1),1)+1+(ROW()-4)*7)=DAY(TODAY()))'
add "$(req_cf_custom "$SHEET_MONTHLY_CAL" 4 9 1 7 "$MONTHLY_TODAY_FORMULA" "$COLOR_HEADER_BG" - true 0)"

echo "Total conditional formatting requests: ${#REQS[@]}" >&2

JOINED="$(IFS=,; echo "${REQS[*]}")"
batch_update "[$JOINED]"
