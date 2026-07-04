#!/usr/bin/env bash
# Step 3b: Recurring Tasks Setup headers, note, and the 5 recurring templates
# pulled from Master Tasks (Weekly Team Standup, Grocery Run, Pay Rent,
# Respond to Support Emails, Backup Client Files).
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

echo "Writing Recurring Tasks Setup..." >&2

values_update "Recurring Tasks Setup!A1:I6" '{
  "values": [
    ["Task Name", "Category", "Priority", "Assigned To", "Recurrence Pattern", "Interval", "Start Date", "Next Due Date", "Active?"],
    ["Weekly Team Standup",     "Work",  "Medium",    "Morgan", "Weekly",  1, "'"$(offset_date 0)"'",  "=IFERROR(INDEX('"'"'Recurring Engine'"'"'!C:C,MATCH(A2,'"'"'Recurring Engine'"'"'!A:A,0)),\"\")", true],
    ["Grocery Run",             "Home",  "Low",       "Taylor", "Weekly",  1, "'"$(offset_date -2)"'", "=IFERROR(INDEX('"'"'Recurring Engine'"'"'!C:C,MATCH(A3,'"'"'Recurring Engine'"'"'!A:A,0)),\"\")", true],
    ["Pay Rent",                "Home",  "Very High", "Taylor", "Monthly", 1, "'"$(offset_date -1)"'", "=IFERROR(INDEX('"'"'Recurring Engine'"'"'!C:C,MATCH(A4,'"'"'Recurring Engine'"'"'!A:A,0)),\"\")", true],
    ["Respond to Support Emails","Work", "Medium",    "Morgan", "Daily",   1, "'"$(offset_date -1)"'", "=IFERROR(INDEX('"'"'Recurring Engine'"'"'!C:C,MATCH(A5,'"'"'Recurring Engine'"'"'!A:A,0)),\"\")", true],
    ["Backup Client Files",     "Work",  "Medium",    "Sam",    "Weekly",  1, "'"$(offset_date -8)"'", "=IFERROR(INDEX('"'"'Recurring Engine'"'"'!C:C,MATCH(A6,'"'"'Recurring Engine'"'"'!A:A,0)),\"\")", true]
  ]
}'

# Instructional note (merged K1:M1 in the formatting step).
values_update "Recurring Tasks Setup!K1" '{
  "values": [["Next Due Date shows automatically. Copy the task into Master Tasks when you'"'"'re ready to start it."]]
}'
