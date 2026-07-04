#!/usr/bin/env bash
# Step 3a of the build order: Master Tasks headers, formulas, and 35 rows of
# seed data. Master Tasks must be fully populated before Kanban, Gantt,
# Calendars, and Decision Matrix are built since all of them read from it live.
#
# Dates are written as STATIC values computed from "today" at the moment this
# script runs (that is "build time" per the spec) -- not as live TODAY()
# formulas -- so charts/rows don't shift on reopen. Only column K (Days Left)
# recalculates live.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

echo "Writing Master Tasks headers + 35 sample rows..." >&2

# Fields: TaskName|Description|Category|Status|Priority|AssignedTo|StartOffset|DueOffset|DoneOffset|Pct|Urgent|Important|Recurring|Pattern|Notes
# Offsets are signed integers in days relative to today; empty = blank cell.
ROWS=(
"Draft Q3 Budget Report|Prepare quarterly budget summary for leadership review|Finance|Completed|High|Alex|-20|-15|-14|100|1|1|0|None|Sent to accountant"
"Publish Blog Post: SEO Tips|Write and publish blog post on on-page SEO tactics|Growth|In Progress|Medium|Jamie|-5|2||60|0|1|0|None|Draft in Google Docs"
"Client Invoice Follow-up|Chase down payment on overdue client invoice|Finance|In Progress|Very High|Alex|-10|-3||40|1|1|0|None|Overdue — called client twice"
"Weekly Team Standup|Facilitate weekly sync with the team|Work|Not Started|Medium|Morgan|0|1||0|0|1|1|Weekly|Recurs every Monday"
"Grocery Run|Buy groceries for the week|Home|Completed|Low|Taylor|-2|-2|-2|100|0|0|1|Weekly|"
"Renew Business Insurance|Renew annual business liability insurance policy|Finance|Not Started|High|Sam|0|14||0|0|1|0|None|Reminder set"
"Design New Logo Concepts|Sketch three new logo directions for rebrand|Growth|On Hold|Low|Jamie|-15|10||20|0|0|0|None|Waiting on brand direction"
"Pay Rent|Pay monthly office rent|Home|Completed|Very High|Taylor|-1|-1|-1|100|1|1|1|Monthly|Auto-pay confirmed"
"Respond to Support Emails|Clear the support inbox for the day|Work|In Progress|Medium|Morgan|-1|0||50|1|0|1|Daily|"
"Plan Q4 Marketing Campaign|Outline messaging and channels for Q4 push|Growth|Not Started|High|Alex|0|21||0|0|1|0|None|"
"Backup Client Files|Run weekly backup of all client project files|Work|Completed|Medium|Sam|-8|-7|-7|100|0|1|1|Weekly|"
"Clean Home Office|Tidy and dust the home office|Home|Not Started|Low|Taylor|0|5||0|0|0|0|None|"
"Review Freelancer Contracts|Review contract terms before renewing freelancers|Finance|In Progress|High|Alex|-6|-1||70|1|1|0|None|Overdue — legal review pending"
"Schedule Dentist Appointment|Book routine dental checkup|Personal|Not Started|Low|Jamie|0|30||0|0|0|0|None|"
"Update Portfolio Website|Refresh portfolio site with recent projects|Growth|Cancelled|Medium|Morgan|-25|-10||0|0|0|0|None|Deprioritized this quarter"
"Organize Digital Files|Clean up and restructure shared drive folders|Work|Not Started|Low|Sam|0|12||0|0|0|0|None|"
"Renew Domain Names|Renew expiring company domain registrations|Errands|Not Started|Medium|Sam|0|9||0|0|1|0|None|"
"Water Office Plants|Water and check the office plants|Home|Completed|Very Low|Taylor|-30|-30|-30|100|0|0|0|None|"
"Submit Expense Report|Submit last month's travel expense report|Finance|Completed|Medium|Alex|-30|-25|-24|100|1|1|0|None|"
"Call Insurance Adjuster|Follow up on pending claim with adjuster|Errands|In Progress|High|Morgan|-4|1||40|1|1|0|None|"
"Pick Up Dry Cleaning|Grab dry cleaning before the shop closes|Errands|Not Started|Low|Taylor|0|3||0|1|0|0|None|"
"Return Amazon Package|Drop off return at the Amazon locker|Errands|Completed|Low|Jamie|-3|-3|-3|100|0|0|0|None|"
"Post Weekly Newsletter|Draft and send the weekly newsletter|Growth|In Progress|Medium|Jamie|-2|1||50|0|1|0|None|"
"Research Competitor Pricing|Compare pricing across top three competitors|Growth|Not Started|Medium|Morgan|0|15||0|0|1|0|None|"
"File Quarterly Taxes|Submit estimated quarterly tax payment|Finance|Not Started|Very High|Alex|0|-2||10|1|1|0|None|Overdue — need to file ASAP"
"Update Emergency Contact List|Update emergency contacts on file with HR|Personal|Not Started|Low|Sam|0|45||0|0|0|0|None|"
"Deep Clean Refrigerator|Empty and deep-clean the office fridge|Home|Not Started|Medium|Taylor|0|-1||0|0|0|0|None|Overdue"
"Plan Family Trip|Research destinations and dates for family trip|Personal|On Hold|Low|Morgan|-10|25||10|0|0|0|None|"
"Set Up New Laptop|Configure new laptop and migrate accounts|Work|In Progress|High|Sam|-3|2||70|1|0|0|None|"
"Cancel Unused Subscriptions|Audit and cancel unused software subscriptions|Finance|Cancelled|Low|Alex|-12|-5||0|0|0|0|None|"
"Write Client Case Study|Draft case study for recent client win|Growth|In Progress|High|Jamie|-6|4||55|1|1|0|None|"
"Sort Recycling|Sort recycling bins ahead of pickup|Home|Completed|Very Low|Taylor|-39|-39|-38|100|0|0|0|None|"
"Confirm Vendor Contracts|Confirm renewal terms with two vendors|Work|Not Started|High|Morgan|0|8||0|1|0|0|None|"
"Restock Office Supplies|Order paper, pens, and coffee for the office|Errands|Not Started|Medium|Sam|0|6||0|0|0|0|None|"
"Archive Old Email Threads|Archive last quarter's completed email threads|Work|Completed|Low|Alex|-49|-44|-43|100|0|0|0|None|"
)

HEADER='["ID","Task Name","Description","Category","Status","Priority","Assigned To","Start Date","Due Date","Date Completed","Days Left","Completion %","Urgent?","Important?","Recurring?","Recurrence Pattern","Notes"]'

BODY_ROWS=""
ROW_NUM=1  # header is row 1; data starts row 2
for line in "${ROWS[@]}"; do
  ROW_NUM=$((ROW_NUM + 1))
  IFS='|' read -r name desc cat status prio assignee startoff dueoff doneoff pct urg imp rec pattern notes <<< "$line"

  start_date="$(offset_date "$startoff")"
  due_date="$(offset_date "$dueoff")"
  if [[ -n "$doneoff" ]]; then
    done_date="\"$(offset_date "$doneoff")\""
  else
    done_date='""'
  fi

  id_formula="=ROW()-1"
  k_formula="=IF(E${ROW_NUM}=\"Completed\",\"✅ Done\",IF(I${ROW_NUM}=\"\",\"\",IF(I${ROW_NUM}<TODAY(),\"⚠️ \"&(TODAY()-I${ROW_NUM})&\"d overdue\",(I${ROW_NUM}-TODAY())&\"d left\")))"

  pct_val="$(awk -v p="$pct" 'BEGIN{printf "%.2f", p/100}')"
  urg_bool=$([[ "$urg" == "1" ]] && echo true || echo false)
  imp_bool=$([[ "$imp" == "1" ]] && echo true || echo false)
  rec_bool=$([[ "$rec" == "1" ]] && echo true || echo false)

  row_json=$(printf '["%s","%s","%s","%s","%s","%s","%s","%s","%s",%s,"%s",%s,%s,%s,%s,"%s","%s"]' \
    "$(jesc "$id_formula")" "$(jesc "$name")" "$(jesc "$desc")" "$(jesc "$cat")" "$(jesc "$status")" \
    "$(jesc "$prio")" "$(jesc "$assignee")" "$start_date" "$due_date" "$done_date" \
    "$(jesc "$k_formula")" "$pct_val" "$urg_bool" "$imp_bool" "$rec_bool" "$(jesc "$pattern")" "$(jesc "$notes")")

  if [[ -z "$BODY_ROWS" ]]; then
    BODY_ROWS="$row_json"
  else
    BODY_ROWS="$BODY_ROWS,$row_json"
  fi
done

VALUES_JSON="[$HEADER,$BODY_ROWS]"

values_update "Master Tasks!A1:Q$((ROW_NUM))" "{\"values\":$VALUES_JSON}"

echo "Wrote $((ROW_NUM - 1)) data rows to Master Tasks (rows 2-$ROW_NUM)." >&2
