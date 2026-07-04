#!/usr/bin/env bash
# Step 3c: hidden Recurring Engine sheet. Calculates the next 6 occurrence
# dates per active recurring template. Two extra helper columns (I: start
# date, J: interval) are pulled by VLOOKUP on task name so the six occurrence
# formulas stay short and each row is independent of FILTER row-alignment.
#
# Recurring Tasks Setup!H (Next Due Date) reads back from this sheet's
# column C via INDEX/MATCH on task name -- see 04_recurring_setup_values.sh.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

echo "Writing Recurring Engine formulas..." >&2

values_update "Recurring Engine!A1:J1" '{
  "values": [["Task Name", "Pattern", "Occurrence 1", "Occurrence 2", "Occurrence 3", "Occurrence 4", "Occurrence 5", "Occurrence 6", "Start (helper)", "Interval (helper)"]]
}'

# A2/B2 are the only two cells that need a formula -- they spill down over
# every active ('Recurring Tasks Setup'!I=TRUE) row automatically.
values_update "Recurring Engine!A2:B2" '{
  "values": [[
    "=IFERROR(FILTER('"'"'Recurring Tasks Setup'"'"'!$A$2:$A,'"'"'Recurring Tasks Setup'"'"'!$I$2:$I=TRUE),\"\")",
    "=IFERROR(FILTER('"'"'Recurring Tasks Setup'"'"'!$E$2:$E,'"'"'Recurring Tasks Setup'"'"'!$I$2:$I=TRUE),\"\")"
  ]]
}'

# Rows 2-11 (headroom for up to 10 active templates): helper pulls + the six
# branching occurrence formulas, one row at a time so each references its own
# spilled $A / $B value.
BODY_ROWS=""
for row in $(seq 2 11); do
  helper_i="=IF(\$A${row}=\"\",\"\",IFERROR(VLOOKUP(\$A${row},'Recurring Tasks Setup'!\$A:\$G,7,FALSE),\"\"))"
  helper_j="=IF(\$A${row}=\"\",\"\",IFERROR(VLOOKUP(\$A${row},'Recurring Tasks Setup'!\$A:\$G,6,FALSE),\"\"))"

  occ_cols=""
  for n in 1 2 3 4 5 6; do
    f="=IF(\$A${row}=\"\",\"\",IFS(\$B${row}=\"Daily\",\$I${row}+\$J${row}*${n},\$B${row}=\"Weekly\",\$I${row}+\$J${row}*7*${n},\$B${row}=\"Biweekly\",\$I${row}+\$J${row}*14*${n},\$B${row}=\"Monthly\",EDATE(\$I${row},\$J${row}*${n})))"
    if [[ -z "$occ_cols" ]]; then occ_cols="\"$(jesc "$f")\""; else occ_cols="$occ_cols,\"$(jesc "$f")\""; fi
  done

  row_json="[$occ_cols,\"$(jesc "$helper_i")\",\"$(jesc "$helper_j")\"]"

  if [[ -z "$BODY_ROWS" ]]; then BODY_ROWS="$row_json"; else BODY_ROWS="$BODY_ROWS,$row_json"; fi
done

values_update "Recurring Engine!C2:J11" "{\"values\":[$BODY_ROWS]}"
