# Slack Status Management Scripts

Command-line tools for managing your Slack user status via the Slack API.

## Requirements

- `bash` (version 4.0 or higher)
- `jq` - JSON processor (install with: `sudo apt-get install jq` or `brew install jq`)
- `curl` - usually pre-installed on most systems
- A Slack User OAuth Token (see setup instructions below)

## Scripts

### slack-status.sh

Main script for getting and setting Slack status.

**Usage:**

```bash
# Get current status (all fields)
./slack-status.sh get

# Get specific field
./slack-status.sh get -f text      # Get status text only
./slack-status.sh get -f emoji     # Get emoji only
./slack-status.sh get -f expiration # Get expiration timestamp (0 = don't clear)

# Set status
./slack-status.sh set "Working"                    # Set status without expiration
./slack-status.sh set "In a meeting" ":calendar:"   # Set status with emoji
./slack-status.sh set "Lunch" ":fork_and_knife:" 3600  # Set status for 1 hour

# Backward compatibility (without 'set' command)
./slack-status.sh "Working" ":coffee:"
```

**Fields for `-f` option:**
- `text` - Status text
- `emoji` - Status emoji
- `expiration` - Expiration timestamp (Unix timestamp, 0 means "don't clear")

### slack-random-status.sh

Automatically sets a random status from a predefined list. Respects manually set "don't clear" statuses (won't overwrite them).

**Usage:**

```bash
./slack-random-status.sh
```

**Configuration:**

1. Create a file `~/slack_statuses.txt` with one status per line:
   ```
   Working on a project
   In a meeting
   Lunch break
   Deep focus mode
   ```

2. The script will:
   - Select a random status from the file
   - Check if current status is set to "don't clear" (if so, skip update)
   - Set the selected status for 3 hours
   - Use `:good_news:` emoji by default

**Cron example:**

To run every 2 hours:
```cron
0 */2 * * * /path/to/slack-random-status.sh
```

## Setup

### 1. Get Slack Token (User OAuth Token)

1. **Create a Slack App:**
   - Go to https://api.slack.com/apps
   - Click "Create New App"
   - Select "From scratch"
   - Enter an app name and select your workspace

2. **Configure OAuth & Permissions:**
   - In the app menu, select "OAuth & Permissions"
   - Under "Scopes" → "User Token Scopes", add:
     - `users.profile:write` — to update status
     - `users.profile:read` — to read profile (required for `get` command)

3. **Install the app to your workspace:**
   - Scroll to "OAuth Tokens for Your Workspace"
   - Click "Install to Workspace"
   - Confirm the permissions

4. **Copy the token:**
   - After installation, you'll see a "User OAuth Token" (starts with `xoxp-`)
   - Copy it

### 2. Save the Token

You have two options:

**Option 1: Save to file (recommended)**
```bash
echo 'xoxp-your-token-here' > ~/.slack_token
chmod 600 ~/.slack_token
```

**Option 2: Export as environment variable**
```bash
export SLACK_TOKEN='xoxp-your-token-here'
```

Add this to your `~/.bashrc` or `~/.zshrc` if you want it to persist across sessions.

### 3. Make Scripts Executable

```bash
chmod +x slack-status.sh slack-random-status.sh
```

## Examples

### Basic Usage

```bash
# Set a status
./slack-status.sh set "Working from home" ":house:"

# Set a status for 2 hours
./slack-status.sh set "Lunch" ":fork_and_knife:" 7200

# Check current status
./slack-status.sh get

# Get only the status text
./slack-status.sh get -f text
```

### Automated Status Updates

1. Create `~/slack_statuses.txt`:
   ```
   Working on a project
   In a meeting
   Lunch break
   Deep focus mode
   Coffee break
   ```

2. Add to crontab (`crontab -e`):
   ```cron
   0 */2 * * * /path/to/slack-random-status.sh
   ```

This will update your status every 2 hours with a random status from the list.

### Respecting Manual Status

If you manually set a status in Slack UI with "don't clear" option (e.g., "Vacationing"), the `slack-random-status.sh` script will detect this and skip the update, preserving your manual status.

## Notes

- Status text maximum length is 144 characters
- Expiration is specified in seconds (Unix timestamp)
- Status expiration of `0` means "don't clear" (permanent until manually changed)
- The scripts check for token availability and provide helpful error messages if something is missing
