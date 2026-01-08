#!/bin/bash

# slack-random-status.sh - Set random Slack status from file

STATUSES_FILE="$HOME/slack_statuses.txt"
SLACK_STATUS_SCRIPT="$HOME/bin/finist_scripts/slack/slack-status.sh"

# Check if statuses file exists
if [ ! -f "$STATUSES_FILE" ]; then
  echo "Error: Statuses file not found: $STATUSES_FILE"
  echo "Create the file and add status lines (one per line)"
  exit 1
fi

# Check if slack-status.sh is available in PATH
if ! command -v "$SLACK_STATUS_SCRIPT" >/dev/null 2>&1; then
  echo "Error: slack-status.sh not found in PATH: $SLACK_STATUS_SCRIPT"
  exit 1
fi

# Read non-empty lines from file into array
mapfile -t statuses < <(grep -v '^[[:space:]]*$' "$STATUSES_FILE")

# Check if any statuses were found
if [ ${#statuses[@]} -eq 0 ]; then
  echo "Error: No non-empty status lines found in $STATUSES_FILE"
  exit 1
fi

# Select random status
random_index=$((RANDOM % ${#statuses[@]}))
selected_status="${statuses[$random_index]}"

# Trim whitespace from selected status
selected_status=$(echo "$selected_status" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

# Check if status exceeds maximum length (144 characters)
if [ ${#selected_status} -gt 144 ]; then
  echo "Error: Status too long (${#selected_status} characters, maximum is 144): $selected_status"
  exit 1
fi

# Check current status expiration - if set to "don't clear" (0), don't change it
current_expiration=$("$SLACK_STATUS_SCRIPT" get -f expiration 2>/dev/null)
if [ "$current_expiration" = "0" ]; then
  echo "Status is set to 'don't clear', skipping update"
  exit 0
fi

# Call slack-status.sh with the selected status (set for 3 hours)
"$SLACK_STATUS_SCRIPT" set "$selected_status" ":good_news:" 10800

