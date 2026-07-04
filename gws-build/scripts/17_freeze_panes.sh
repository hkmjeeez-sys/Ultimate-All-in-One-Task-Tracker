#!/usr/bin/env bash
# Step 8 (final) of the build order: freeze panes (Section 10). Never freezes
# a column through a horizontal merge; row-only freezes are always safe even
# when row 1 contains row-spanning merges (Decision Matrix, Dashboard, etc.).
#
# Note on Kanban Board: the spec's Section 3 puts the "change Status in
# Master Tasks" note in row 1 (merged A1:H1) and lane headers in row 2, while
# Section 10 says "freeze row 1 (lane headers)" -- those two can't both be
# literally true in the same sheet. We freeze rows 1-2 so the note AND the
# lane headers both stay visible while scrolling, which satisfies the intent
# of both sections.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

echo "Building freeze pane requests..." >&2

REQS=()
add() { REQS+=("$1"); }

add "$(req_freeze "$SHEET_DASHBOARD" 1 0)"
add "$(req_freeze "$SHEET_MASTER_TASKS" 1 2)"
add "$(req_freeze "$SHEET_KANBAN" 2 0)"
add "$(req_freeze "$SHEET_MONTHLY_CAL" 3 0)"
add "$(req_freeze "$SHEET_WEEKLY_CAL" 3 0)"
add "$(req_freeze "$SHEET_GANTT" 1 1)"
add "$(req_freeze "$SHEET_DECISION_MATRIX" 1 0)"
add "$(req_freeze "$SHEET_RECURRING_SETUP" 1 0)"
add "$(req_freeze "$SHEET_ANALYTICS" 1 0)"

echo "Total freeze requests: ${#REQS[@]}" >&2
JOINED="$(IFS=,; echo "${REQS[*]}")"
batch_update "[$JOINED]"
