#!/usr/bin/env bash
# Step 2 of the build order: populate the hidden Reference Data sheet.
# Must run before any dropdown validation and before Master Tasks formulas
# that assume these ranges exist.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

echo "Writing Reference Data..." >&2

values_update "Reference Data!A1:E7" '{
  "values": [
    ["Categories", "Statuses", "Priorities", "People", "Recurrence Patterns"],
    ["Work",     "Not Started", "Very High", "Alex",   "None"],
    ["Growth",   "In Progress", "High",      "Jamie",  "Daily"],
    ["Finance",  "On Hold",     "Medium",    "Morgan", "Weekly"],
    ["Home",     "Completed",   "Low",       "Taylor", "Biweekly"],
    ["Personal", "Cancelled",   "Very Low",  "Sam",    "Monthly"],
    ["Errands",  "",            "",          "",       ""]
  ]
}'
