#!/usr/bin/env bash
# Step 5 of the build order: data validation (dropdowns + checkboxes). All
# dropdowns are strict except Weekly Calendar's Monday-nudge (see Section 9:
# "must be a Monday if feasible, otherwise plain date input").
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

echo "Building data validation requests..." >&2

REQS=()
add() { REQS+=("$1"); }

# ---- Master Tasks -----------------------------------------------------------
add "$(req_validation_range "$SHEET_MASTER_TASKS" 2 500 4 4 "'Reference Data'!\$A\$2:\$A\$7" true)"   # Category
add "$(req_validation_range "$SHEET_MASTER_TASKS" 2 500 5 5 "'Reference Data'!\$B\$2:\$B\$6" true)"   # Status
add "$(req_validation_range "$SHEET_MASTER_TASKS" 2 500 6 6 "'Reference Data'!\$C\$2:\$C\$6" true)"   # Priority
add "$(req_validation_range "$SHEET_MASTER_TASKS" 2 500 7 7 "'Reference Data'!\$D\$2:\$D\$6" true)"   # Assigned To
add "$(req_validation_range "$SHEET_MASTER_TASKS" 2 500 16 16 "'Reference Data'!\$E\$2:\$E\$6" true)" # Recurrence Pattern
add "$(req_validation_checkbox "$SHEET_MASTER_TASKS" 2 500 13 13)"  # Urgent?
add "$(req_validation_checkbox "$SHEET_MASTER_TASKS" 2 500 14 14)"  # Important?
add "$(req_validation_checkbox "$SHEET_MASTER_TASKS" 2 500 15 15)"  # Recurring?

# ---- Recurring Tasks Setup ---------------------------------------------------
add "$(req_validation_range "$SHEET_RECURRING_SETUP" 2 60 2 2 "'Reference Data'!\$A\$2:\$A\$7" true)"  # Category
add "$(req_validation_range "$SHEET_RECURRING_SETUP" 2 60 3 3 "'Reference Data'!\$C\$2:\$C\$6" true)"  # Priority
add "$(req_validation_range "$SHEET_RECURRING_SETUP" 2 60 4 4 "'Reference Data'!\$D\$2:\$D\$6" true)"  # Assigned To
add "$(req_validation_range "$SHEET_RECURRING_SETUP" 2 60 5 5 "'Reference Data'!\$E\$3:\$E\$6" true)"  # Recurrence Pattern (Daily..Monthly, excludes "None")
add "$(req_validation_checkbox "$SHEET_RECURRING_SETUP" 2 60 9 9)"  # Active?

# ---- Monthly Calendar ---------------------------------------------------------
add "$(req_validation_list "$SHEET_MONTHLY_CAL" 1 1 2 2 true \
  January February March April May June July August September October November December)"
add "$(req_validation_number_between "$SHEET_MONTHLY_CAL" 1 1 4 4 2024 2035)"

# ---- Weekly Calendar -----------------------------------------------------------
# Single rule: nudge toward Monday but don't hard-block non-Monday dates
# (setDataValidation on the same range only keeps the last rule anyway).
add "$(req_validation_custom "$SHEET_WEEKLY_CAL" 1 1 2 2 "=WEEKDAY(\$B\$1,2)=1" false)"

echo "Total validation requests: ${#REQS[@]}" >&2

JOINED="$(IFS=,; echo "${REQS[*]}")"
batch_update "[$JOINED]"
