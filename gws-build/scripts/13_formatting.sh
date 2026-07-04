#!/usr/bin/env bash
# Step 4 of the build order: formatting (colors, fonts, number formats,
# column widths, merges, alternating rows) across every tab. Run after all
# values/formulas are written and before validation/conditional formatting.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

echo "Building formatting requests..." >&2

REQS=()
add() { REQS+=("$1"); }

# =============================================================================
# Master Tasks (sheetId 1)
# =============================================================================
add "$(req_cell_format "$SHEET_MASTER_TASKS" 1 1 1 17 "$COLOR_DARK_HEADER_BG" "$COLOR_WHITE" true 11)"
add "$(req_cell_format "$SHEET_MASTER_TASKS" 2 500 1 17 - - false 10)"
add "$(req_col_width "$SHEET_MASTER_TASKS" 1 1 50)"    # ID
add "$(req_col_width "$SHEET_MASTER_TASKS" 2 2 220)"   # Task Name
add "$(req_col_width "$SHEET_MASTER_TASKS" 3 3 260)"   # Description
add "$(req_col_width "$SHEET_MASTER_TASKS" 4 4 110)"   # Category
add "$(req_col_width "$SHEET_MASTER_TASKS" 5 5 110)"   # Status
add "$(req_col_width "$SHEET_MASTER_TASKS" 6 6 110)"   # Priority
add "$(req_col_width "$SHEET_MASTER_TASKS" 7 7 110)"   # Assigned To
add "$(req_col_width "$SHEET_MASTER_TASKS" 8 8 100)"   # Start Date
add "$(req_col_width "$SHEET_MASTER_TASKS" 9 9 100)"   # Due Date
add "$(req_col_width "$SHEET_MASTER_TASKS" 10 10 100)" # Date Completed
add "$(req_col_width "$SHEET_MASTER_TASKS" 11 11 100)" # Days Left
add "$(req_col_width "$SHEET_MASTER_TASKS" 12 12 90)"  # Completion %
add "$(req_col_width "$SHEET_MASTER_TASKS" 13 15 70)"  # Urgent/Important/Recurring
add "$(req_col_width "$SHEET_MASTER_TASKS" 16 16 140)" # Recurrence Pattern
add "$(req_col_width "$SHEET_MASTER_TASKS" 17 17 220)" # Notes
add "$(req_number_format "$SHEET_MASTER_TASKS" 2 500 8 10 DATE "mmm d, yyyy")"
add "$(req_number_format "$SHEET_MASTER_TASKS" 2 500 12 12 PERCENT "0%")"
add "$(req_banding "$SHEET_MASTER_TASKS" 2 500 1 17 "$COLOR_ALT_ROW" "$COLOR_WHITE")"

# =============================================================================
# Kanban Board (sheetId 2)
# =============================================================================
add "$(req_merge "$SHEET_KANBAN" 1 1 1 8)"
add "$(req_cell_format "$SHEET_KANBAN" 1 1 1 8 "$COLOR_HEADER_BG" "$COLOR_HEADER_TEXT" true -)"
add "$(req_wrap "$SHEET_KANBAN" 1 1 1 8 WRAP MIDDLE)"
add "$(req_cell_format "$SHEET_KANBAN" 2 2 1 8 "$COLOR_DARK_HEADER_BG" "$COLOR_WHITE" true 11)"
add "$(req_cell_format "$SHEET_KANBAN" 3 500 1 8 - - false 10)"
add "$(req_wrap "$SHEET_KANBAN" 3 500 1 8 WRAP TOP)"
add "$(req_col_width "$SHEET_KANBAN" 1 1 220)"
add "$(req_col_width "$SHEET_KANBAN" 2 2 24)"
add "$(req_col_width "$SHEET_KANBAN" 3 3 220)"
add "$(req_col_width "$SHEET_KANBAN" 4 4 24)"
add "$(req_col_width "$SHEET_KANBAN" 5 5 220)"
add "$(req_col_width "$SHEET_KANBAN" 6 6 24)"
add "$(req_col_width "$SHEET_KANBAN" 7 7 220)"

# =============================================================================
# Monthly Calendar (sheetId 3)
# =============================================================================
add "$(req_cell_format "$SHEET_MONTHLY_CAL" 1 1 1 1 - "$COLOR_HEADER_TEXT" true -)"
add "$(req_cell_format "$SHEET_MONTHLY_CAL" 1 1 3 3 - "$COLOR_HEADER_TEXT" true -)"
add "$(req_cell_format "$SHEET_MONTHLY_CAL" 1 1 2 2 "$COLOR_HEADER_BG" "$COLOR_HEADER_TEXT" true -)"
add "$(req_cell_format "$SHEET_MONTHLY_CAL" 1 1 4 4 "$COLOR_HEADER_BG" "$COLOR_HEADER_TEXT" true -)"
add "$(req_merge "$SHEET_MONTHLY_CAL" 2 2 1 7)"
add "$(req_cell_format "$SHEET_MONTHLY_CAL" 2 2 1 7 "$COLOR_HEADER_BG" "$COLOR_HEADER_TEXT" true 18)"
add "$(req_row_height "$SHEET_MONTHLY_CAL" 2 2 44)"
add "$(req_cell_format "$SHEET_MONTHLY_CAL" 3 3 1 7 "$COLOR_DARK_HEADER_BG" "$COLOR_WHITE" true 11)"
add "$(req_cell_format "$SHEET_MONTHLY_CAL" 4 9 1 7 - - false 10)"
add "$(req_wrap "$SHEET_MONTHLY_CAL" 4 9 1 7 WRAP TOP)"
add "$(req_row_height "$SHEET_MONTHLY_CAL" 4 9 70)"
add "$(req_col_width "$SHEET_MONTHLY_CAL" 1 7 110)"

# =============================================================================
# Weekly Calendar (sheetId 4)
# =============================================================================
add "$(req_cell_format "$SHEET_WEEKLY_CAL" 1 1 1 1 - "$COLOR_HEADER_TEXT" true -)"
add "$(req_cell_format "$SHEET_WEEKLY_CAL" 1 1 2 2 "$COLOR_HEADER_BG" "$COLOR_HEADER_TEXT" true -)"
add "$(req_cell_format "$SHEET_WEEKLY_CAL" 3 3 1 7 "$COLOR_DARK_HEADER_BG" "$COLOR_WHITE" true 11)"
add "$(req_number_format "$SHEET_WEEKLY_CAL" 3 3 1 7 DATE "ddd, mmm d")"
for col in 1 2 3 4 5 6 7; do
  add "$(req_merge "$SHEET_WEEKLY_CAL" 4 15 "$col" "$col")"
done
add "$(req_cell_format "$SHEET_WEEKLY_CAL" 4 15 1 7 - - false 10)"
add "$(req_wrap "$SHEET_WEEKLY_CAL" 4 15 1 7 WRAP TOP)"
add "$(req_col_width "$SHEET_WEEKLY_CAL" 1 7 150)"

# =============================================================================
# Gantt Chart (sheetId 5)
# =============================================================================
add "$(req_cell_format "$SHEET_GANTT" 1 1 1 62 "$COLOR_DARK_HEADER_BG" "$COLOR_WHITE" true 10)"
add "$(req_number_format "$SHEET_GANTT" 1 1 3 62 DATE "M/d")"
add "$(req_cell_format "$SHEET_GANTT" 2 200 1 62 - - false 9)"
add "$(req_col_width "$SHEET_GANTT" 1 1 220)"
add "$(req_col_width "$SHEET_GANTT" 2 2 110)"
add "$(req_col_width "$SHEET_GANTT" 3 62 40)"

# =============================================================================
# Decision Matrix (sheetId 6)
# =============================================================================
add "$(req_merge "$SHEET_DECISION_MATRIX" 1 1 1 6)"
add "$(req_merge "$SHEET_DECISION_MATRIX" 1 1 8 13)"
add "$(req_merge "$SHEET_DECISION_MATRIX" 22 22 1 6)"
add "$(req_merge "$SHEET_DECISION_MATRIX" 22 22 8 13)"
add "$(req_cell_format "$SHEET_DECISION_MATRIX" 1 1 1 6 "$COLOR_STATUS_CANCELLED_BG" "$COLOR_PRIORITY_VERYHIGH" true 14)"
add "$(req_cell_format "$SHEET_DECISION_MATRIX" 1 1 8 13 "$COLOR_STATUS_ONHOLD_BG" "$COLOR_STATUS_ONHOLD_TEXT" true 14)"
add "$(req_cell_format "$SHEET_DECISION_MATRIX" 22 22 1 6 "$COLOR_STATUS_INPROGRESS_BG" "$COLOR_STATUS_INPROGRESS_TEXT" true 14)"
add "$(req_cell_format "$SHEET_DECISION_MATRIX" 22 22 8 13 "$COLOR_STATUS_NOTSTARTED_BG" "$COLOR_STATUS_NOTSTARTED_TEXT" true 14)"
add "$(req_cell_format "$SHEET_DECISION_MATRIX" 3 20 1 1 - - false 10)"
add "$(req_cell_format "$SHEET_DECISION_MATRIX" 3 20 8 8 - - false 10)"
add "$(req_cell_format "$SHEET_DECISION_MATRIX" 24 41 1 1 - - false 10)"
add "$(req_cell_format "$SHEET_DECISION_MATRIX" 24 41 8 8 - - false 10)"
add "$(req_col_width "$SHEET_DECISION_MATRIX" 1 1 260)"
add "$(req_col_width "$SHEET_DECISION_MATRIX" 8 8 260)"

# =============================================================================
# Recurring Tasks Setup (sheetId 7)
# =============================================================================
add "$(req_cell_format "$SHEET_RECURRING_SETUP" 1 1 1 9 "$COLOR_DARK_HEADER_BG" "$COLOR_WHITE" true 11)"
add "$(req_cell_format "$SHEET_RECURRING_SETUP" 2 60 1 9 - - false 10)"
add "$(req_merge "$SHEET_RECURRING_SETUP" 1 1 11 13)"
add "$(req_cell_format "$SHEET_RECURRING_SETUP" 1 1 11 13 "$COLOR_HEADER_BG" "$COLOR_HEADER_TEXT" false -)"
add "$(req_wrap "$SHEET_RECURRING_SETUP" 1 1 11 13 WRAP MIDDLE)"
add "$(req_number_format "$SHEET_RECURRING_SETUP" 2 60 7 8 DATE "mmm d, yyyy")"
add "$(req_col_width "$SHEET_RECURRING_SETUP" 1 1 220)"
add "$(req_col_width "$SHEET_RECURRING_SETUP" 2 4 110)"
add "$(req_col_width "$SHEET_RECURRING_SETUP" 5 5 130)"
add "$(req_col_width "$SHEET_RECURRING_SETUP" 6 6 70)"
add "$(req_col_width "$SHEET_RECURRING_SETUP" 7 8 100)"
add "$(req_col_width "$SHEET_RECURRING_SETUP" 9 9 70)"
add "$(req_col_width "$SHEET_RECURRING_SETUP" 11 13 200)"

# =============================================================================
# Analytics (sheetId 8)
# =============================================================================
add "$(req_cell_format "$SHEET_ANALYTICS" 1 1 1 4 "$COLOR_DARK_HEADER_BG" "$COLOR_WHITE" true 11)"
add "$(req_cell_format "$SHEET_ANALYTICS" 1 1 6 8 "$COLOR_DARK_HEADER_BG" "$COLOR_WHITE" true 11)"
add "$(req_cell_format "$SHEET_ANALYTICS" 2 9 1 8 - - false 10)"
add "$(req_number_format "$SHEET_ANALYTICS" 2 9 1 2 DATE "mmm d, yyyy")"
add "$(req_number_format "$SHEET_ANALYTICS" 2 7 8 8 PERCENT "0%")"
add "$(req_col_width "$SHEET_ANALYTICS" 1 2 110)"
add "$(req_col_width "$SHEET_ANALYTICS" 3 4 120)"
add "$(req_col_width "$SHEET_ANALYTICS" 6 6 110)"
add "$(req_col_width "$SHEET_ANALYTICS" 7 8 90)"

# =============================================================================
# Reference Data (sheetId 9, hidden)
# =============================================================================
add "$(req_cell_format "$SHEET_REFERENCE_DATA" 1 1 1 5 "$COLOR_DARK_HEADER_BG" "$COLOR_WHITE" true 11)"
add "$(req_col_width "$SHEET_REFERENCE_DATA" 1 5 130)"

# =============================================================================
# Dashboard (sheetId 0)
# =============================================================================
add "$(req_merge "$SHEET_DASHBOARD" 1 1 1 22)"
add "$(req_cell_format "$SHEET_DASHBOARD" 1 1 1 22 "$COLOR_HEADER_BG" "$COLOR_HEADER_TEXT" true 18)"
add "$(req_row_height "$SHEET_DASHBOARD" 1 1 48)"
add "$(req_col_width "$SHEET_DASHBOARD" 1 4 165)"

# Notifications
add "$(req_merge "$SHEET_DASHBOARD" 3 3 1 4)"
add "$(req_merge "$SHEET_DASHBOARD" 4 4 1 4)"
add "$(req_merge "$SHEET_DASHBOARD" 5 5 1 4)"
add "$(req_cell_format "$SHEET_DASHBOARD" 3 5 1 4 "$COLOR_HEADER_BG" "$COLOR_HEADER_TEXT" false 10)"
add "$(req_wrap "$SHEET_DASHBOARD" 3 5 1 4 WRAP MIDDLE)"
add "$(req_row_height "$SHEET_DASHBOARD" 3 5 34)"

# KPI cards: label row (bold, small, colored bg) + value row (big bold, same bg)
kpi_card() {
  # kpi_card <labelRow> <valueRow> <bgHex> <textHex>
  local lr="$1" vr="$2" bg="$3" text="$4"
  add "$(req_merge "$SHEET_DASHBOARD" "$lr" "$lr" 1 4)"
  add "$(req_merge "$SHEET_DASHBOARD" "$vr" "$vr" 1 4)"
  add "$(req_cell_format "$SHEET_DASHBOARD" "$lr" "$lr" 1 4 "$bg" "$text" true 9)"
  add "$(req_cell_format "$SHEET_DASHBOARD" "$vr" "$vr" 1 4 "$bg" "$COLOR_HEADER_TEXT" true 20)"
}
kpi_card 7  8  "$COLOR_HEADER_BG"             "$COLOR_HEADER_TEXT"
kpi_card 9  10 "$COLOR_STATUS_COMPLETED_BG"   "$COLOR_STATUS_COMPLETED_TEXT"
kpi_card 11 12 "$COLOR_STATUS_INPROGRESS_BG"  "$COLOR_STATUS_INPROGRESS_TEXT"
kpi_card 13 14 "$COLOR_STATUS_CANCELLED_BG"   "$COLOR_PRIORITY_VERYHIGH"
kpi_card 15 16 "$COLOR_STATUS_ONHOLD_BG"      "$COLOR_STATUS_ONHOLD_TEXT"
kpi_card 17 18 "$COLOR_STATUS_NOTSTARTED_BG"  "$COLOR_STATUS_NOTSTARTED_TEXT"
add "$(req_number_format "$SHEET_DASHBOARD" 10 10 1 4 PERCENT "0.0%")"

# Today / Overdue feeds
add "$(req_merge "$SHEET_DASHBOARD" 20 20 1 4)"
add "$(req_cell_format "$SHEET_DASHBOARD" 20 20 1 4 "$COLOR_STATUS_COMPLETED_BG" "$COLOR_STATUS_COMPLETED_TEXT" true 11)"
add "$(req_merge "$SHEET_DASHBOARD" 21 25 1 4)"
add "$(req_wrap "$SHEET_DASHBOARD" 21 25 1 4 WRAP TOP)"
add "$(req_cell_format "$SHEET_DASHBOARD" 21 25 1 4 "$COLOR_WHITE" - false 10)"

add "$(req_merge "$SHEET_DASHBOARD" 27 27 1 4)"
add "$(req_cell_format "$SHEET_DASHBOARD" 27 27 1 4 "$COLOR_STATUS_CANCELLED_BG" "$COLOR_STATUS_CANCELLED_TEXT" true 11)"
add "$(req_merge "$SHEET_DASHBOARD" 28 32 1 4)"
add "$(req_wrap "$SHEET_DASHBOARD" 28 32 1 4 WRAP TOP)"
add "$(req_cell_format "$SHEET_DASHBOARD" 28 32 1 4 "$COLOR_WHITE" - false 10)"

# Chart helper range headers
add "$(req_cell_format "$SHEET_DASHBOARD" 1 1 5 6 "$COLOR_ALT_ROW" "$COLOR_HEADER_TEXT" true -)"
add "$(req_cell_format "$SHEET_DASHBOARD" 1 1 8 9 "$COLOR_ALT_ROW" "$COLOR_HEADER_TEXT" true -)"
add "$(req_cell_format "$SHEET_DASHBOARD" 1 1 11 12 "$COLOR_ALT_ROW" "$COLOR_HEADER_TEXT" true -)"
add "$(req_cell_format "$SHEET_DASHBOARD" 1 1 14 19 "$COLOR_ALT_ROW" "$COLOR_HEADER_TEXT" true -)"

echo "Total formatting requests: ${#REQS[@]}" >&2

JOINED="$(IFS=,; echo "${REQS[*]}")"
batch_update "[$JOINED]"
