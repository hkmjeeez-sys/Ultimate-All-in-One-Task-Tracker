# Ultimate All-in-One Task Tracker — gws CLI build script

This is a raw `gws` CLI build script for the spreadsheet described in the
build prompt (see repo root), following the workflow defined in
`SPREADSHEET_PROMPT_GENERATOR.md`: create sheets → reference/hidden data →
cell data/formulas → formatting → validation → conditional formatting →
charts → freeze panes.

It was written and JSON-validated in an environment with **no `gws` CLI and
no Google OAuth credentials** (this is a cloud/remote Claude Code session,
not the machine where you installed `gws`), so every script was exercised
with `DRY_RUN=1` to confirm the exact commands and JSON payloads are
well-formed, but **none of it has actually been run against a live Google
Sheet**. Run it yourself wherever `gws` is installed and authenticated
(e.g. your Windows machine per `1. Install GWS CLI.docx`).

## Interactive preview

`preview.html` is a self-contained, offline mockup of the tracker — open it
directly in a browser (no server needed). It seeds from the same 35-row
Master Tasks dataset and 5 recurring templates as the build scripts, then
recomputes everything in JavaScript rather than Google Sheets formulas:

- **Dashboard, Master Tasks, Kanban Board, Monthly/Weekly Calendar, Gantt
  Chart, Decision Matrix, Recurring Tasks Setup, and Analytics are all live.**
  Edit any cell on Master Tasks (or the Recurring Tasks Setup table) and
  every other tab recomputes instantly, mirroring the `COUNTIF`/`COUNTIFS`/
  `FILTER`/`VLOOKUP` chains the real spreadsheet will run.
- "Today" comes from your actual clock, so overdue flags, the Gantt's
  today-column, and recurring next-due dates all shift correctly day to day.
- It's a **preview of the design and behavior only** — it doesn't write
  anything to Google Sheets. Reference Data and Recurring Engine stay dimmed
  since they're hidden helper sheets in the real workbook too.
- Known approximation: the Sheets API has no field for custom colors on
  individual pie slices or bars within a single chart series, so the two
  donuts and the Priority Distribution bar use a default palette here instead
  of the exact Status/Priority hexes (everything else gets exact colors).

## Prerequisites

- `gws` installed and authenticated (`gws auth setup`, or one of the other
  methods in the CLI's own docs) — must have Sheets scope access.
- `bash` (the scripts use bash arrays / `set -euo pipefail`; no `jq`
  dependency, JSON is built with plain string formatting).
- GNU `date` or BSD/macOS `date` (both are auto-detected).

## Usage

```bash
cd gws-build

# 1. Create the spreadsheet (writes the new spreadsheetId to .spreadsheet_id)
bash scripts/01_create_spreadsheet.sh

# 2. Run everything else in order
bash run_all.sh
```

Or run the whole thing in one shot:

```bash
bash run_all.sh
```

To point at a spreadsheet you already created, skip step 1:

```bash
SPREADSHEET_ID=1AbCdEfGhIjKlMnOpQrStUvWxYz ./run_all.sh
```

To see every command without executing it:

```bash
DRY_RUN=1 ./run_all.sh
```

## Layout

```
lib/common.sh          shared config (sheetId map, palette), gws wrapper,
                        and JSON request builders (cell format, merges,
                        column widths, data validation, conditional
                        formatting, charts, freeze panes)
scripts/01..17_*.sh     one script per build step, run in numeric order
run_all.sh              runs every script in order
.spreadsheet_id         written by 01_create_spreadsheet.sh, read by every
                        later script (or set SPREADSHEET_ID yourself)
```

Every script is also independently re-runnable (e.g. if you only need to
redo conditional formatting: `bash scripts/15_conditional_formatting.sh`).

## Sample data & dates

Master Tasks' 35 seed rows are stored as day **offsets** from "today" (e.g.
`-3` = 3 days ago), and `offset_date` in `lib/common.sh` resolves them to
literal `YYYY-MM-DD` values using the date the script is *run*, matching the
prompt's "static values computed at build time" requirement — re-running the
scripts later will re-seed with fresh dates relative to that day.

## Known deviations from the literal prompt text

The build prompt has a few internal inconsistencies; where the literal text
couldn't all be true at once, here's what this script actually does instead
(all are called out again in the relevant script's header comment):

- **Monthly Calendar B1/D1 vs. merged title A1:G1**: the prompt puts the
  Month/Year selectors *and* a merged `A1:G1` title in row 1, which can't both
  be literally true in the same row. This script keeps the selectors at
  `B1`/`D1` (with `A1`/`C1` labels) and moves the merged title banner to row 2.
- **Gantt "60 columns (C→BL)"**: C→BL is actually 62 columns, not 60. This
  script keeps exactly 60 columns as stated (`C1:BJ1`), so the header dates
  run `TODAY()-10` .. `TODAY()+49`.
- **Kanban Board freeze**: Section 3 puts the "change Status in Master Tasks"
  note in row 1 and lane headers in row 2, but Section 10 says "freeze row 1
  (lane headers)". This script freezes rows 1-2 so both stay visible.
- **Pie-slice / per-bar chart colors**: the Sheets REST API has no field for
  custom colors on individual pie slices or individual bars within a single
  BasicChart series (only whole-series colors). So the two donut charts and
  the single-series Priority Distribution column chart render with Sheets'
  default palette, not the exact Status/Category/Priority hexes; the
  Priority-by-Category stacked chart and the two line/column charts with one
  series per metric *do* get exact colors, since per-series color is
  supported.
- **Dashboard KPI/notification/feed cell addresses**: the prompt gives exact
  helper-range addresses for 3 of the 5 charts (`E2:F6`, `H2:I7`, `K2:L6`) but
  leaves notification/KPI/Today/Overdue layout to our discretion. This script
  puts those in the left sidebar (columns A-D) so they never collide with the
  helper ranges and chart anchors living in columns E onward.

## Verifying after a real run

- Open Reference Data / Recurring Engine and un-hide them temporarily if you
  want to sanity-check the FILTER/VLOOKUP chains.
- Check Master Tasks conditional formatting: 4 rows should show the red
  overdue highlight, Completion % should show a red→yellow→green gradient.
- Kanban Board's four lanes should each list a handful of tasks.
- Decision Matrix's four quadrants should each have at least a few tasks.
- Dashboard's two donuts, priority bar, stacked bar, and timeline chart
  should all render with non-empty data; Analytics' trend line likewise.
