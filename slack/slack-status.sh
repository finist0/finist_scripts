#!/bin/bash

# slack-status.sh - Get and update Slack user status from command line

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

# Parse command (get or set)
COMMAND="${1:-set}"

# Function to get current Slack status
# Usage: get_status [field]
# field can be: text, emoji, expiration (optional)
get_status() {
  local field="$1"
  local response
  response=$(curl -s -X POST "https://slack.com/api/users.profile.get" \
    -H "Authorization: Bearer $SLACK_TOKEN" \
    -H "Content-Type: application/json")

  # Check if API call was successful
  if ! echo "$response" | jq -e '.ok == true' >/dev/null 2>&1; then
    echo "Error: Failed to get status" >&2
    echo "$response" >&2
    return 1
  fi

  # Extract status information from JSON response using jq
  # jq handles null values gracefully: -r outputs raw strings, // "" provides default for null
  local status_text
  local status_emoji
  local status_expiration

  status_text=$(echo "$response" | jq -r '.profile.status_text // ""')
  status_emoji=$(echo "$response" | jq -r '.profile.status_emoji // ""')
  status_expiration=$(echo "$response" | jq -r '.profile.status_expiration // 0')

  # If field is specified, output only that field's value
  if [ -n "$field" ]; then
    case "$field" in
      text)
        echo "${status_text:-}"
        ;;
      emoji)
        echo "${status_emoji:-}"
        ;;
      expiration)
        echo "${status_expiration:-0}"
        ;;
      *)
        echo "Error: Invalid field '$field'. Valid fields are: text, emoji, expiration" >&2
        return 1
        ;;
    esac
    return 0
  fi

  # Output all status information (default behavior)
  echo "Status text: ${status_text:-<empty>}"
  echo "Status emoji: ${status_emoji:-<empty>}"
  echo "Status expiration: ${status_expiration:-0}"
}

# Function to set Slack status
set_status() {
  local status_text="$1"
  local status_emoji="$2"
  local duration="$3"

  # Check if status text is provided
  if [ -z "$status_text" ]; then
    echo "Usage: $0 set <status_text> [emoji] [duration_seconds]"
    echo "Example: $0 set 'Working'"
    echo "Example: $0 set 'In a meeting' ':calendar:' 3600"
    exit 1
  fi

  # Build JSON payload dynamically based on provided parameters
  local profile_json="\"status_text\": \"$status_text\""

  # Add emoji only if provided
  if [ -n "$status_emoji" ]; then
    profile_json="$profile_json, \"status_emoji\": \"$status_emoji\""
  fi

  # Add expiration only if duration is provided
  if [ -n "$duration" ]; then
    local status_expiration
    status_expiration=$(( $(date +%s) + duration ))
    profile_json="$profile_json, \"status_expiration\": $status_expiration"
  fi

  # Update Slack status via API
  local response
  response=$(curl -s -X POST "https://slack.com/api/users.profile.set" \
    -H "Authorization: Bearer $SLACK_TOKEN" \
    -H "Content-Type: application/json" \
    --data "{
      \"profile\": {
        $profile_json
      }
    }")

  if echo "$response" | grep -q '"ok":true'; then
    echo "Status updated: $status_text${status_emoji:+ $status_emoji}"
    return 0
  else
    echo "Error updating status" >&2
    echo "$response" >&2
    return 1
  fi
}

# Execute command
case "$COMMAND" in
  get)
    shift
    # Parse options for get command
    field=""
    while [ $# -gt 0 ]; do
      case "$1" in
        -f)
          if [ $# -lt 2 ]; then
            echo "Error: -f requires a field name (text, emoji, or expiration)" >&2
            exit 1
          fi
          field="$2"
          shift 2
          ;;
        *)
          echo "Error: Unknown option '$1' for get command" >&2
          echo "Usage: $0 get [-f <field>]" >&2
          echo "Fields: text, emoji, expiration" >&2
          exit 1
          ;;
      esac
    done
    get_status "$field"
    ;;
  set)
    shift
    set_status "$@"
    ;;
  *)
    # For backward compatibility, treat as set command
    set_status "$@"
    ;;
esac

