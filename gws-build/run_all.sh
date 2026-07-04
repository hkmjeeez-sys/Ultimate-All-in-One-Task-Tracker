#!/usr/bin/env bash
# Runs every build step in order (Section: Build order in
# SPREADSHEET_PROMPT_GENERATOR.md / README.md in this folder).
#
# Usage:
#   ./run_all.sh                # real run (requires gws installed + authed)
#   DRY_RUN=1 ./run_all.sh       # print every gws command instead of running it
#   SPREADSHEET_ID=abc ./run_all.sh   # skip 01_create_spreadsheet.sh, build into an existing sheet
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

STEPS=(
  01_create_spreadsheet.sh
  02_reference_data.sh
  03_master_tasks_values.sh
  04_recurring_setup_values.sh
  05_recurring_engine_values.sh
  06_kanban_values.sh
  07_monthly_calendar_values.sh
  08_weekly_calendar_values.sh
  09_gantt_values.sh
  10_decision_matrix_values.sh
  11_analytics_values.sh
  12_dashboard_values.sh
  13_formatting.sh
  14_validation.sh
  15_conditional_formatting.sh
  16_charts.sh
  17_freeze_panes.sh
)

if [[ -n "${SPREADSHEET_ID:-}" ]]; then
  echo "Using existing SPREADSHEET_ID=$SPREADSHEET_ID -- skipping 01_create_spreadsheet.sh" >&2
  STEPS=("${STEPS[@]:1}")
fi

for step in "${STEPS[@]}"; do
  echo "=== $step ===" >&2
  bash "scripts/$step"
done

echo "Build complete." >&2
