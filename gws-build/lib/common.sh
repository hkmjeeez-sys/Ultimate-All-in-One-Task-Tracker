#!/usr/bin/env bash
# Shared config, sheetId map, color helper, and gws wrapper for the
# Ultimate All-in-One Task Tracker build scripts.
#
# Source this file from every script in gws-build/scripts/:
#   source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

set -euo pipefail

GWS_BIN="${GWS_BIN:-gws}"
BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_FILE="$BUILD_DIR/.spreadsheet_id"

# sheetId map (fixed, matches the build prompt's Section 2 table)
SHEET_DASHBOARD=0
SHEET_MASTER_TASKS=1
SHEET_KANBAN=2
SHEET_MONTHLY_CAL=3
SHEET_WEEKLY_CAL=4
SHEET_GANTT=5
SHEET_DECISION_MATRIX=6
SHEET_RECURRING_SETUP=7
SHEET_ANALYTICS=8
SHEET_REFERENCE_DATA=9
SHEET_RECURRING_ENGINE=10

# ---- spreadsheet id persistence -------------------------------------------
save_spreadsheet_id() {
  printf '%s' "$1" > "$STATE_FILE"
}

load_spreadsheet_id() {
  if [[ -n "${SPREADSHEET_ID:-}" ]]; then
    echo "$SPREADSHEET_ID"
    return 0
  fi
  if [[ -f "$STATE_FILE" ]]; then
    cat "$STATE_FILE"
    return 0
  fi
  echo "ERROR: no spreadsheet id found. Run 01_create_spreadsheet.sh first, or export SPREADSHEET_ID=<id>." >&2
  exit 1
}

# ---- gws wrapper ------------------------------------------------------------
# Usage: run_gws <api-path...> -- --params '<json>' [--json '<json>']
# Set DRY_RUN=1 to print the command instead of executing it.
run_gws() {
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    printf '%s ' "$GWS_BIN" "$@"
    printf '\n\n'
  else
    "$GWS_BIN" "$@"
  fi
}

values_update() {
  # values_update <range> <json-body>
  local range="$1" body="$2"
  local id; id="$(load_spreadsheet_id)"
  run_gws sheets spreadsheets values update \
    --params "$(printf '{"spreadsheetId":"%s","range":"%s","valueInputOption":"USER_ENTERED"}' "$id" "$range")" \
    --json "$body"
}

batch_update() {
  # batch_update <requests-json-array-as-string>
  local requests="$1"
  local id; id="$(load_spreadsheet_id)"
  run_gws sheets spreadsheets batchUpdate \
    --params "$(printf '{"spreadsheetId":"%s"}' "$id")" \
    --json "$(printf '{"requests":%s}' "$requests")"
}

# ---- color helper -----------------------------------------------------------
# hex2rgb RRGGBB -> {"red":0.xxxx,"green":0.xxxx,"blue":0.xxxx}
hex2rgb() {
  local hex="${1#\#}"
  local r=$((16#${hex:0:2}))
  local g=$((16#${hex:2:2}))
  local b=$((16#${hex:4:2}))
  awk -v r="$r" -v g="$g" -v b="$b" \
    'BEGIN{printf "{\"red\":%.4f,\"green\":%.4f,\"blue\":%.4f}", r/255, g/255, b/255}'
}

# hex_tint RRGGBB <fraction toward white, 0..1> -> {"red":..,"green":..,"blue":..}
# Used for "light tint" backgrounds (e.g. Priority palette CF rule 2 in
# Section 8, which asks for pale versions of otherwise-saturated colors).
hex_tint() {
  local hex="${1#\#}" frac="$2"
  local r=$((16#${hex:0:2}))
  local g=$((16#${hex:2:2}))
  local b=$((16#${hex:4:2}))
  awk -v r="$r" -v g="$g" -v b="$b" -v f="$frac" \
    'BEGIN{printf "{\"red\":%.4f,\"green\":%.4f,\"blue\":%.4f}", (r+(255-r)*f)/255, (g+(255-g)*f)/255, (b+(255-b)*f)/255}'
}

# ---- date helper ------------------------------------------------------------
# offset_date <+/-N> -> YYYY-MM-DD, N days from today (portable GNU/BSD date)
offset_date() {
  local n="$1"
  if date --version >/dev/null 2>&1; then
    date -d "${n} days" +%Y-%m-%d           # GNU date
  else
    date -v"${n}"d +%Y-%m-%d                # BSD/macOS date
  fi
}

today_date() { offset_date 0; }

# ---- palette (Section 6) ----------------------------------------------------
COLOR_HEADER_BG="E8DFF5"     # soft lavender banner
COLOR_HEADER_TEXT="2C3E50"   # dark charcoal
COLOR_DARK_HEADER_BG="2C3E50"
COLOR_WHITE="FFFFFF"

COLOR_CAT_WORK="4A90D9"
COLOR_CAT_GROWTH="43A047"
COLOR_CAT_FINANCE="8E24AA"
COLOR_CAT_HOME="EC7FA9"
COLOR_CAT_PERSONAL="FF8A65"
COLOR_CAT_ERRANDS="26A69A"

COLOR_STATUS_NOTSTARTED_TEXT="9AA0A6"; COLOR_STATUS_NOTSTARTED_BG="EDEDED"
COLOR_STATUS_INPROGRESS_TEXT="4285F4"; COLOR_STATUS_INPROGRESS_BG="D2E3FC"
COLOR_STATUS_ONHOLD_TEXT="F9AB00";     COLOR_STATUS_ONHOLD_BG="FEF0C7"
COLOR_STATUS_COMPLETED_TEXT="34A853";  COLOR_STATUS_COMPLETED_BG="CEEAD6"
COLOR_STATUS_CANCELLED_TEXT="EA4335";  COLOR_STATUS_CANCELLED_BG="FADCD9"

COLOR_PRIORITY_VERYHIGH="D93025"
COLOR_PRIORITY_HIGH="F57C00"
COLOR_PRIORITY_MEDIUM="FBC02D"
COLOR_PRIORITY_LOW="7CB342"
COLOR_PRIORITY_VERYLOW="90A4AE"

COLOR_ALT_ROW="F8F9FA"

COLOR_GRADIENT_MIN="F4A6A6"
COLOR_GRADIENT_MID="FEF0C7"
COLOR_GRADIENT_MAX="CEEAD6"

# chart_position <sheetId> <anchorRow 1-indexed> <anchorCol 1-indexed> <widthPx> <heightPx>
chart_position() {
  local sheetId="$1" row="$2" col="$3" w="$4" h="$5"
  printf '{"overlayPosition":{"anchorCell":{"sheetId":%s,"rowIndex":%s,"columnIndex":%s},"widthPixels":%s,"heightPixels":%s}}' \
    "$sheetId" "$((row - 1))" "$((col - 1))" "$w" "$h"
}

# req_add_chart <spec-json> <position-json>
req_add_chart() {
  printf '{"addChart":{"chart":{"spec":%s,"position":%s}}}' "$1" "$2"
}

# req_freeze <sheetId> <frozenRowCount> <frozenColumnCount>
req_freeze() {
  local sheetId="$1" rows="$2" cols="$3"
  printf '{"updateSheetProperties":{"properties":{"sheetId":%s,"gridProperties":{"frozenRowCount":%s,"frozenColumnCount":%s}},"fields":"gridProperties.frozenRowCount,gridProperties.frozenColumnCount"}}' \
    "$sheetId" "$rows" "$cols"
}

# ---- misc --------------------------------------------------------------------
# json-escape a string for embedding inside a JSON string literal
jesc() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

# ---- batchUpdate request builders --------------------------------------------
# All ranges are given as 1-indexed, inclusive row/col numbers (spreadsheet-
# style) and converted here to the API's 0-indexed, end-exclusive GridRange.
grid_range() {
  # grid_range <sheetId> <row1> <row2> <col1> <col2>
  local sheetId="$1" r1="$2" r2="$3" c1="$4" c2="$5"
  printf '{"sheetId":%s,"startRowIndex":%s,"endRowIndex":%s,"startColumnIndex":%s,"endColumnIndex":%s}' \
    "$sheetId" "$((r1 - 1))" "$r2" "$((c1 - 1))" "$c2"
}

# req_cell_format <sheetId> <r1> <r2> <c1> <c2> <bgHex|-> <textHex|-> <bold:true|false> <fontSize|->
req_cell_format() {
  local sheetId="$1" r1="$2" r2="$3" c1="$4" c2="$5" bg="$6" text="$7" bold="$8" size="$9"
  local fmt_parts="" fields="userEnteredFormat("
  local need_comma=0
  if [[ "$bg" != "-" ]]; then
    fmt_parts="\"backgroundColor\":$(hex2rgb "$bg")"
    fields="${fields}backgroundColor"
    need_comma=1
  fi
  local text_fmt=""
  if [[ "$text" != "-" ]]; then text_fmt="\"foregroundColor\":$(hex2rgb "$text")"; fi
  if [[ "$bold" != "-" ]]; then
    [[ -n "$text_fmt" ]] && text_fmt="$text_fmt,"
    text_fmt="${text_fmt}\"bold\":$bold"
  fi
  if [[ "$size" != "-" ]]; then
    [[ -n "$text_fmt" ]] && text_fmt="$text_fmt,"
    text_fmt="${text_fmt}\"fontSize\":$size"
  fi
  if [[ -n "$text_fmt" ]]; then
    [[ $need_comma -eq 1 ]] && fmt_parts="${fmt_parts},"
    fmt_parts="${fmt_parts}\"textFormat\":{${text_fmt}}"
    fields="${fields}$([[ $need_comma -eq 1 ]] && echo ,)textFormat"
    need_comma=1
  fi
  fields="${fields})"
  printf '{"repeatCell":{"range":%s,"cell":{"userEnteredFormat":{%s}},"fields":"%s"}}' \
    "$(grid_range "$sheetId" "$r1" "$r2" "$c1" "$c2")" "$fmt_parts" "$fields"
}

# req_number_format <sheetId> <r1> <r2> <c1> <c2> <type: DATE|PERCENT|NUMBER> <pattern>
req_number_format() {
  local sheetId="$1" r1="$2" r2="$3" c1="$4" c2="$5" type="$6" pattern="$7"
  printf '{"repeatCell":{"range":%s,"cell":{"userEnteredFormat":{"numberFormat":{"type":"%s","pattern":"%s"}}},"fields":"userEnteredFormat.numberFormat"}}' \
    "$(grid_range "$sheetId" "$r1" "$r2" "$c1" "$c2")" "$type" "$(jesc "$pattern")"
}

# req_wrap <sheetId> <r1> <r2> <c1> <c2> <wrapStrategy: WRAP|CLIP|OVERFLOW_CELL> <vAlign: TOP|MIDDLE|BOTTOM>
req_wrap() {
  local sheetId="$1" r1="$2" r2="$3" c1="$4" c2="$5" wrap="$6" valign="$7"
  printf '{"repeatCell":{"range":%s,"cell":{"userEnteredFormat":{"wrapStrategy":"%s","verticalAlignment":"%s"}},"fields":"userEnteredFormat.wrapStrategy,userEnteredFormat.verticalAlignment"}}' \
    "$(grid_range "$sheetId" "$r1" "$r2" "$c1" "$c2")" "$wrap" "$valign"
}

# req_col_width <sheetId> <col1> <col2 inclusive> <px>
req_col_width() {
  local sheetId="$1" c1="$2" c2="$3" px="$4"
  printf '{"updateDimensionProperties":{"range":{"sheetId":%s,"dimension":"COLUMNS","startIndex":%s,"endIndex":%s},"properties":{"pixelSize":%s},"fields":"pixelSize"}}' \
    "$sheetId" "$((c1 - 1))" "$c2" "$px"
}

# req_row_height <sheetId> <row1> <row2 inclusive> <px>
req_row_height() {
  local sheetId="$1" r1="$2" r2="$3" px="$4"
  printf '{"updateDimensionProperties":{"range":{"sheetId":%s,"dimension":"ROWS","startIndex":%s,"endIndex":%s},"properties":{"pixelSize":%s},"fields":"pixelSize"}}' \
    "$sheetId" "$((r1 - 1))" "$r2" "$px"
}

# req_merge <sheetId> <r1> <r2> <c1> <c2> [mergeType]
req_merge() {
  local sheetId="$1" r1="$2" r2="$3" c1="$4" c2="$5" type="${6:-MERGE_ALL}"
  printf '{"mergeCells":{"range":%s,"mergeType":"%s"}}' "$(grid_range "$sheetId" "$r1" "$r2" "$c1" "$c2")" "$type"
}

# req_validation_range <sheetId> <r1> <r2> <c1> <c2> <"Sheet Name!A2:A7"> <strict:true|false>
req_validation_range() {
  local sheetId="$1" r1="$2" r2="$3" c1="$4" c2="$5" srcRange="$6" strict="$7"
  printf '{"setDataValidation":{"range":%s,"rule":{"condition":{"type":"ONE_OF_RANGE","values":[{"userEnteredValue":"=%s"}]},"strict":%s,"showCustomUi":true}}}' \
    "$(grid_range "$sheetId" "$r1" "$r2" "$c1" "$c2")" "$(jesc "$srcRange")" "$strict"
}

# req_validation_list <sheetId> <r1> <r2> <c1> <c2> <strict> <value1> [value2 ...]
req_validation_list() {
  local sheetId="$1" r1="$2" r2="$3" c1="$4" c2="$5" strict="$6"; shift 6
  local values="" v
  for v in "$@"; do
    [[ -n "$values" ]] && values="${values},"
    values="${values}{\"userEnteredValue\":\"$(jesc "$v")\"}"
  done
  printf '{"setDataValidation":{"range":%s,"rule":{"condition":{"type":"ONE_OF_LIST","values":[%s]},"strict":%s,"showCustomUi":true}}}' \
    "$(grid_range "$sheetId" "$r1" "$r2" "$c1" "$c2")" "$values" "$strict"
}

# req_validation_checkbox <sheetId> <r1> <r2> <c1> <c2>
req_validation_checkbox() {
  local sheetId="$1" r1="$2" r2="$3" c1="$4" c2="$5"
  printf '{"setDataValidation":{"range":%s,"rule":{"condition":{"type":"BOOLEAN"},"strict":true}}}' \
    "$(grid_range "$sheetId" "$r1" "$r2" "$c1" "$c2")"
}

# req_validation_number_between <sheetId> <r1> <r2> <c1> <c2> <min> <max>
req_validation_number_between() {
  local sheetId="$1" r1="$2" r2="$3" c1="$4" c2="$5" min="$6" max="$7"
  printf '{"setDataValidation":{"range":%s,"rule":{"condition":{"type":"NUMBER_BETWEEN","values":[{"userEnteredValue":"%s"},{"userEnteredValue":"%s"}]},"strict":true,"showCustomUi":true}}}' \
    "$(grid_range "$sheetId" "$r1" "$r2" "$c1" "$c2")" "$min" "$max"
}

# req_validation_custom <sheetId> <r1> <r2> <c1> <c2> <formula> <strict>
req_validation_custom() {
  local sheetId="$1" r1="$2" r2="$3" c1="$4" c2="$5" formula="$6" strict="$7"
  printf '{"setDataValidation":{"range":%s,"rule":{"condition":{"type":"CUSTOM_FORMULA","values":[{"userEnteredValue":"%s"}]},"strict":%s,"showCustomUi":true}}}' \
    "$(grid_range "$sheetId" "$r1" "$r2" "$c1" "$c2")" "$(jesc "$formula")" "$strict"
}

# req_validation_date <sheetId> <r1> <r2> <c1> <c2>
req_validation_date() {
  local sheetId="$1" r1="$2" r2="$3" c1="$4" c2="$5"
  printf '{"setDataValidation":{"range":%s,"rule":{"condition":{"type":"DATE_IS_VALID_DATE"},"strict":true,"showCustomUi":true}}}' \
    "$(grid_range "$sheetId" "$r1" "$r2" "$c1" "$c2")"
}

# ---- conditional formatting builders -----------------------------------------
_cf_format_json() {
  # _cf_format_json <bgHex|bg-{json}|-> <textHex|-> <bold:true|false|->
  local bg="$1" text="$2" bold="$3"
  local parts="" tf=""
  if [[ "$bg" != "-" ]]; then
    if [[ "$bg" == \{* ]]; then parts="\"backgroundColor\":${bg}"; else parts="\"backgroundColor\":$(hex2rgb "$bg")"; fi
  fi
  if [[ "$text" != "-" ]]; then tf="\"foregroundColor\":$(hex2rgb "$text")"; fi
  if [[ "$bold" != "-" ]]; then
    [[ -n "$tf" ]] && tf="${tf},"
    tf="${tf}\"bold\":${bold}"
  fi
  if [[ -n "$tf" ]]; then
    [[ -n "$parts" ]] && parts="${parts},"
    parts="${parts}\"textFormat\":{${tf}}"
  fi
  printf '{%s}' "$parts"
}

# req_cf_custom <sheetId> <r1> <r2> <c1> <c2> <formula> <bgHex|-> <textHex|-> <bold> <index>
req_cf_custom() {
  local sheetId="$1" r1="$2" r2="$3" c1="$4" c2="$5" formula="$6" bg="$7" text="$8" bold="$9" index="${10}"
  printf '{"addConditionalFormatRule":{"rule":{"ranges":[%s],"booleanRule":{"condition":{"type":"CUSTOM_FORMULA","values":[{"userEnteredValue":"%s"}]},"format":%s}},"index":%s}}' \
    "$(grid_range "$sheetId" "$r1" "$r2" "$c1" "$c2")" "$(jesc "$formula")" "$(_cf_format_json "$bg" "$text" "$bold")" "$index"
}

# req_cf_text_eq <sheetId> <r1> <r2> <c1> <c2> <text> <bgHex|-> <textHex|-> <bold> <index>
req_cf_text_eq() {
  local sheetId="$1" r1="$2" r2="$3" c1="$4" c2="$5" val="$6" bg="$7" text="$8" bold="$9" index="${10}"
  printf '{"addConditionalFormatRule":{"rule":{"ranges":[%s],"booleanRule":{"condition":{"type":"TEXT_EQ","values":[{"userEnteredValue":"%s"}]},"format":%s}},"index":%s}}' \
    "$(grid_range "$sheetId" "$r1" "$r2" "$c1" "$c2")" "$(jesc "$val")" "$(_cf_format_json "$bg" "$text" "$bold")" "$index"
}

# req_cf_gradient <sheetId> <r1> <r2> <c1> <c2> <minHex> <midHex> <maxHex> <index>
req_cf_gradient() {
  local sheetId="$1" r1="$2" r2="$3" c1="$4" c2="$5" minHex="$6" midHex="$7" maxHex="$8" index="$9"
  printf '{"addConditionalFormatRule":{"rule":{"ranges":[%s],"gradientRule":{"minpoint":{"color":%s,"type":"NUMBER","value":"0"},"midpoint":{"color":%s,"type":"NUMBER","value":"0.5"},"maxpoint":{"color":%s,"type":"NUMBER","value":"1"}}},"index":%s}}' \
    "$(grid_range "$sheetId" "$r1" "$r2" "$c1" "$c2")" "$(hex2rgb "$minHex")" "$(hex2rgb "$midHex")" "$(hex2rgb "$maxHex")" "$index"
}

# req_banding <sheetId> <r1> <r2> <c1> <c2> <firstHex> <secondHex> [headerHex]
req_banding() {
  local sheetId="$1" r1="$2" r2="$3" c1="$4" c2="$5" first="$6" second="$7" header="${8:-}"
  local body="\"bandedRange\":{\"range\":$(grid_range "$sheetId" "$r1" "$r2" "$c1" "$c2"),\"rowProperties\":{\"firstBandColor\":$(hex2rgb "$first"),\"secondBandColor\":$(hex2rgb "$second")"
  if [[ -n "$header" ]]; then
    body="${body},\"headerColor\":$(hex2rgb "$header")"
  fi
  body="${body}}}"
  printf '{%s}' "$body"
}
