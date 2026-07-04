#!/usr/bin/env bash
# Step 1 of the build order: create the spreadsheet with all 11 tabs,
# fixed sheetIds, and hidden flags set on Reference Data / Recurring Engine.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

TITLE="${SPREADSHEET_TITLE:-Ultimate All-in-One Task Tracker}"

sheet() {
  # sheet <sheetId> <title> <rows> <cols> <hidden:true|false>
  local id="$1" title="$2" rows="$3" cols="$4" hidden="$5"
  printf '{"properties":{"sheetId":%s,"title":"%s","index":%s,"gridProperties":{"rowCount":%s,"columnCount":%s},"hidden":%s}}' \
    "$id" "$(jesc "$title")" "$id" "$rows" "$cols" "$hidden"
}

REQUEST_BODY=$(cat <<EOF
{
  "properties": {"title": "$(jesc "$TITLE")"},
  "sheets": [
    $(sheet "$SHEET_DASHBOARD"        "Dashboard"              60  22 false),
    $(sheet "$SHEET_MASTER_TASKS"     "Master Tasks"          500  17 false),
    $(sheet "$SHEET_KANBAN"           "Kanban Board"          500   8 false),
    $(sheet "$SHEET_MONTHLY_CAL"      "Monthly Calendar"       12   7 false),
    $(sheet "$SHEET_WEEKLY_CAL"       "Weekly Calendar"        16   7 false),
    $(sheet "$SHEET_GANTT"            "Gantt Chart"           200  64 false),
    $(sheet "$SHEET_DECISION_MATRIX"  "Decision Matrix"        45  13 false),
    $(sheet "$SHEET_RECURRING_SETUP"  "Recurring Tasks Setup"  60  11 false),
    $(sheet "$SHEET_ANALYTICS"        "Analytics"              20   8 false),
    $(sheet "$SHEET_REFERENCE_DATA"   "Reference Data"         20   5 true),
    $(sheet "$SHEET_RECURRING_ENGINE" "Recurring Engine"       60   8 true)
  ]
}
EOF
)

echo "Creating spreadsheet '$TITLE'..." >&2

if [[ "${DRY_RUN:-0}" == "1" ]]; then
  run_gws sheets spreadsheets create --json "$REQUEST_BODY"
  echo "(dry run — no spreadsheet id saved)" >&2
  exit 0
fi

RESPONSE="$("$GWS_BIN" sheets spreadsheets create --json "$REQUEST_BODY")"
echo "$RESPONSE"

# Extract spreadsheetId without requiring jq.
NEW_ID="$(printf '%s' "$RESPONSE" | grep -o '"spreadsheetId"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"([^"]+)"$/\1/')"

if [[ -z "$NEW_ID" ]]; then
  echo "ERROR: could not find spreadsheetId in gws response above. Set it manually with:" >&2
  echo "  echo YOUR_ID > '$STATE_FILE'" >&2
  exit 1
fi

save_spreadsheet_id "$NEW_ID"
echo "Saved spreadsheetId=$NEW_ID to $STATE_FILE" >&2
