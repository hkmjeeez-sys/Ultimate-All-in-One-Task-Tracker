#!/usr/bin/env bash
# Step 3g: Gantt Chart. Column A spills every Master Tasks task name via
# FILTER; column B looks up each row's Category; C1:BL1 (60 columns) are
# date headers running from TODAY()-10. Conditional formatting (added later)
# renders the actual timeline bars since the API has no native Gantt type.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

echo "Writing Gantt Chart..." >&2

col_letter() {
  # 1-indexed column number -> A1 column letter(s)
  local n="$1" s=""
  while (( n > 0 )); do
    local rem=$(( (n - 1) % 26 ))
    s="$(printf \\$(printf '%03o' $((65 + rem))))$s"
    n=$(( (n - 1) / 26 ))
  done
  printf '%s' "$s"
}

LAST_COL_LETTER="$(col_letter 62)"   # C(3) .. 60 columns => column 62 = BL
echo "Date header range: C1:${LAST_COL_LETTER}1" >&2

values_update "Gantt Chart!A1:B1" '{"values": [["Task Name", "Category"]]}'

values_update "Gantt Chart!A2" '{
  "values": [["=FILTER('"'"'Master Tasks'"'"'!B2:B,'"'"'Master Tasks'"'"'!B2:B<>\"\")"]]
}'

# B2:B36 -- one row-specific VLOOKUP per Master Tasks row (35 tasks, rows 2-36)
BODY_ROWS=""
for row in $(seq 2 36); do
  f="=IF(A${row}=\"\",\"\",VLOOKUP(A${row},'Master Tasks'!\$B:\$D,3,FALSE))"
  esc="[\"$(jesc "$f")\"]"
  if [[ -z "$BODY_ROWS" ]]; then BODY_ROWS="$esc"; else BODY_ROWS="$BODY_ROWS,$esc"; fi
done
values_update "Gantt Chart!B2:B36" "{\"values\":[$BODY_ROWS]}"

# C1:BL1 -- 60 identical date-header formulas (COLUMN() makes each resolve
# to a different offset day automatically).
HEADER_FORMULA='=TODAY()-10+COLUMN()-3'
ROW_CELLS=""
for i in $(seq 1 60); do
  esc="\"$(jesc "$HEADER_FORMULA")\""
  if [[ -z "$ROW_CELLS" ]]; then ROW_CELLS="$esc"; else ROW_CELLS="$ROW_CELLS,$esc"; fi
done
values_update "Gantt Chart!C1:${LAST_COL_LETTER}1" "{\"values\":[[$ROW_CELLS]]}"
