#!/bin/bash

# slack-status.sh - Update Slack user status from command line

# How to Get Slack Token (User OAuth Token)
#
# 1. Create a Slack App:
#    * Go to https://api.slack.com/apps
#    * Click "Create New App"
#    * Select "From scratch"
#    * Enter an app name and select your workspace
#
# 2. Configure OAuth & Permissions:
#    * In the app menu, select "OAuth & Permissions"
#    * Under "Scopes" → "User Token Scopes", add:
#    * users.profile:write — to update status
#    * users.profile:read — to read profile (optional)
#
# 3. Install the app to your workspace:
#    * Scroll to "OAuth Tokens for Your Workspace"
#    * Click "Install to Workspace"
#    * Confirm the permissions
#
# 4. Copy the token:
#    * After installation, you'll see a "User OAuth Token" (starts with xoxp-)
#    * Copy it
#
# 5. Save the token:
#    * Option 1: Save to file
#      # echo 'xoxp-your-token-here' > ~/.slack_token
#      # chmod 600 ~/.slack_token
#
#    * Option 2: Export as environment variable
#      # export SLACK_TOKEN='xoxp-your-token-here'
#

# Get Slack token from environment variable or from file
SLACK_TOKEN="${SLACK_TOKEN:-$(cat ~/.slack_token 2>/dev/null)}"

# Check if token is set
if [ -z "$SLACK_TOKEN" ]; then
  echo "Error: SLACK_TOKEN is not set"
  echo "Set it with: export SLACK_TOKEN='xoxp-your-token'"
  echo "Or save it to ~/.slack_token"
  exit 1
fi

# Get status parameters from command line arguments
STATUS_TEXT="$1"                      # Status text (required)
STATUS_EMOJI="$2"                     # Status emoji (optional)
DURATION="$3"                         # Duration in seconds (optional)

# Check if status text is provided
if [ -z "$STATUS_TEXT" ]; then
  echo "Usage: $0 <status_text> [emoji] [duration_seconds]"
  echo "Example: $0 'Working'"
  echo "Example: $0 'In a meeting' ':calendar:' 3600"
  exit 1
fi

# Build JSON payload dynamically based on provided parameters
PROFILE_JSON="\"status_text\": \"$STATUS_TEXT\""

# Add emoji only if provided
if [ -n "$STATUS_EMOJI" ]; then
  PROFILE_JSON="$PROFILE_JSON, \"status_emoji\": \"$STATUS_EMOJI\""
fi

# Add expiration only if duration is provided
if [ -n "$DURATION" ]; then
  STATUS_EXPIRATION=$(( $(date +%s) + DURATION ))
  PROFILE_JSON="$PROFILE_JSON, \"status_expiration\": $STATUS_EXPIRATION"
fi

# Update Slack status via API
curl -s -X POST "https://slack.com/api/users.profile.set" \
  -H "Authorization: Bearer $SLACK_TOKEN" \
  -H "Content-Type: application/json" \
  --data "{
    \"profile\": {
      $PROFILE_JSON
    }
  }" | grep -q '"ok":true' && echo "Status updated: $STATUS_TEXT${STATUS_EMOJI:+ $STATUS_EMOJI}" || echo "Error updating status"

