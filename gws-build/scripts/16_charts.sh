#!/usr/bin/env bash
# Step 7 of the build order: charts. Run after Analytics + Dashboard helper
# ranges exist.
#
# API limitation worth knowing about (not covered in SPREADSHEET_PROMPT_
# GENERATOR.md's capability list): PieChartSpec has no per-slice color field,
# and a single-series BasicChart has no per-bar color field either -- the
# Sheets REST API only exposes per-*series* colors, not per-slice/per-point.
# So the two donut charts (#1, #2) and the single-series Priority Distribution
# column chart (#3) will render with Sheets' default palette rather than our
# exact Status/Category/Priority hexes; only charts with one series per
# category (#4 Priority-by-Category stacked, #5 timeline, #6 trend line) can
# get exact colors, and those are set below. Helper-table row order still
# matches each palette's semantic order for readability.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

echo "Building chart requests..." >&2

REQS=()
add() { REQS+=("$1"); }

series_color() {
  # series_color <hex> -> {"color":{...}} fragment for a basicChart series
  printf '"color":%s' "$(hex2rgb "$1")"
}

# ---- 1. Status Donut (Dashboard) --------------------------------------------
STATUS_DONUT_SPEC=$(printf '{"title":"Tasks by Status","pieChart":{"legendPosition":"RIGHT","domain":{"sourceRange":{"sources":[%s]}},"series":{"sourceRange":{"sources":[%s]}},"pieHole":0.6}}' \
  "$(grid_range "$SHEET_DASHBOARD" 2 6 5 5)" "$(grid_range "$SHEET_DASHBOARD" 2 6 6 6)")
add "$(req_add_chart "$STATUS_DONUT_SPEC" "$(chart_position "$SHEET_DASHBOARD" 6 7 350 250)")"

# ---- 2. Category Donut (Dashboard) ------------------------------------------
CATEGORY_DONUT_SPEC=$(printf '{"title":"Tasks by Category","pieChart":{"legendPosition":"RIGHT","domain":{"sourceRange":{"sources":[%s]}},"series":{"sourceRange":{"sources":[%s]}},"pieHole":0.6}}' \
  "$(grid_range "$SHEET_DASHBOARD" 2 7 8 8)" "$(grid_range "$SHEET_DASHBOARD" 2 7 9 9)")
add "$(req_add_chart "$CATEGORY_DONUT_SPEC" "$(chart_position "$SHEET_DASHBOARD" 6 11 350 250)")"

# ---- 3. Priority Distribution column chart (Dashboard) ----------------------
PRIORITY_DIST_SPEC=$(printf '{"title":"Priority Distribution","basicChart":{"chartType":"COLUMN","legendPosition":"NONE","domains":[{"domain":{"sourceRange":{"sources":[%s]}}}],"series":[{"series":{"sourceRange":{"sources":[%s]}}}],"headerCount":0}}' \
  "$(grid_range "$SHEET_DASHBOARD" 2 6 11 11)" "$(grid_range "$SHEET_DASHBOARD" 2 6 12 12)")
add "$(req_add_chart "$PRIORITY_DIST_SPEC" "$(chart_position "$SHEET_DASHBOARD" 22 7 400 250)")"

# ---- 4. Priority by Category stacked column chart (Dashboard) --------------
PRIORITY_BY_CAT_SERIES=""
declare -A PRI_COL=( ["15"]="$COLOR_PRIORITY_VERYHIGH" ["16"]="$COLOR_PRIORITY_HIGH" ["17"]="$COLOR_PRIORITY_MEDIUM" ["18"]="$COLOR_PRIORITY_LOW" ["19"]="$COLOR_PRIORITY_VERYLOW" )
for col in 15 16 17 18 19; do
  s=$(printf '{"series":{"sourceRange":{"sources":[%s]}},%s}' "$(grid_range "$SHEET_DASHBOARD" 1 7 "$col" "$col")" "$(series_color "${PRI_COL[$col]}")")
  if [[ -z "$PRIORITY_BY_CAT_SERIES" ]]; then PRIORITY_BY_CAT_SERIES="$s"; else PRIORITY_BY_CAT_SERIES="$PRIORITY_BY_CAT_SERIES,$s"; fi
done
PRIORITY_BY_CAT_SPEC=$(printf '{"title":"Priority by Category","basicChart":{"chartType":"COLUMN","legendPosition":"TOP","stackedType":"STACKED","domains":[{"domain":{"sourceRange":{"sources":[%s]}}}],"series":[%s],"headerCount":1}}' \
  "$(grid_range "$SHEET_DASHBOARD" 1 7 14 14)" "$PRIORITY_BY_CAT_SERIES")
add "$(req_add_chart "$PRIORITY_BY_CAT_SPEC" "$(chart_position "$SHEET_DASHBOARD" 22 14 450 250)")"

# ---- 5. Task Activity Timeline (Dashboard, reads Analytics!A1:D9) ----------
TIMELINE_SPEC=$(printf '{"title":"Task Activity Timeline","basicChart":{"chartType":"COLUMN","legendPosition":"TOP","domains":[{"domain":{"sourceRange":{"sources":[%s]}}}],"series":[{"series":{"sourceRange":{"sources":[%s]}},%s},{"series":{"sourceRange":{"sources":[%s]}},%s}],"headerCount":1}}' \
  "$(grid_range "$SHEET_ANALYTICS" 1 9 1 1)" \
  "$(grid_range "$SHEET_ANALYTICS" 1 9 3 3)" "$(series_color "$COLOR_STATUS_COMPLETED_TEXT")" \
  "$(grid_range "$SHEET_ANALYTICS" 1 9 4 4)" "$(series_color "$COLOR_STATUS_INPROGRESS_TEXT")")
add "$(req_add_chart "$TIMELINE_SPEC" "$(chart_position "$SHEET_DASHBOARD" 38 7 700 280)")"

echo "Total dashboard chart requests: ${#REQS[@]}" >&2
JOINED="$(IFS=,; echo "${REQS[*]}")"
batch_update "[$JOINED]"

# ---- 6. Completion Trend Line Chart (Analytics tab) -------------------------
TREND_SPEC=$(printf '{"title":"Completion Trend","basicChart":{"chartType":"LINE","legendPosition":"NONE","domains":[{"domain":{"sourceRange":{"sources":[%s]}}}],"series":[{"series":{"sourceRange":{"sources":[%s]}},%s}],"headerCount":0}}' \
  "$(grid_range "$SHEET_ANALYTICS" 2 9 1 1)" \
  "$(grid_range "$SHEET_ANALYTICS" 2 9 3 3)" "$(series_color "$COLOR_STATUS_COMPLETED_TEXT")")
batch_update "[$(req_add_chart "$TREND_SPEC" "$(chart_position "$SHEET_ANALYTICS" 11 1 500 250)")]"
