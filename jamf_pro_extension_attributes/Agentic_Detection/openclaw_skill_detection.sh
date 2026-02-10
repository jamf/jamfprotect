#!/bin/bash

###########################################################################################################################
#
# Copyright 2026, Jamf Software LLC.
# This work is licensed under the terms of the Jamf Source Available License
# https://github.com/jamf/scripts/blob/main/LICENCE.md
#
###########################################################################################################################

# Function to find openclaw directory
find_openclaw_dir() {
    # Get the current console user
    CURRENT_USER=$(stat -f "%Su" /dev/console 2>/dev/null || who | awk '/console/ {print $1}' | head -n 1)
    
    # If we can't determine user, try logname or $USER
    if [ -z "$CURRENT_USER" ]; then
        CURRENT_USER=$(logname 2>/dev/null || echo "$USER")
    fi
    
    # Get user's home directory
    if [ -n "$CURRENT_USER" ]; then
        USER_HOME=$(eval echo "~$CURRENT_USER")
    else
        USER_HOME="$HOME"
    fi
    
    # Define openclaw config path
    OPENCLAW_DIR="${USER_HOME}/.openclaw"
    
    echo "$OPENCLAW_DIR"
}

# Main execution
OPENCLAW_DIR=$(find_openclaw_dir)
OPENCLAW_JSON="${OPENCLAW_DIR}/openclaw.json"

# Check if openclaw is installed
if [ ! -d "$OPENCLAW_DIR" ]; then
    echo "<result>Not Installed</result>"
    exit 0
fi

# Check if config file exists
if [ ! -f "$OPENCLAW_JSON" ]; then
    echo "<result>Config File Not Found</result>"
    exit 0
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "<result>jq Not Available</result>"
    exit 0
fi

# Extract global enabled skills from openclaw.json
GLOBAL_SKILLS=""
if [ -f "$OPENCLAW_JSON" ]; then
    GLOBAL_SKILLS=$(cat "$OPENCLAW_JSON" | jq -r '.skills.entries | to_entries | .[] | select(.value.enabled).key' 2>/dev/null || echo "")
fi

# Extract skills from sessions.json (current format)
SESSIONS_JSON="${OPENCLAW_DIR}/agents/main/sessions/sessions.json"
SESSION_SKILLS=""
if [ -f "$SESSIONS_JSON" ]; then
    SESSION_SKILLS=$(cat "$SESSIONS_JSON" | jq -r '.[] | select(.skillsSnapshot) | .skillsSnapshot.resolvedSkills[].name' 2>/dev/null || echo "")
fi

# Initialize output variables
GLOBAL_OUTPUT=""
SESSION_OUTPUT=""

# Format global skills output
if [ -n "$GLOBAL_SKILLS" ]; then
    GLOBAL_LIST=$(echo "$GLOBAL_SKILLS" | tr '\n' ',' | sed 's/,$//')
    GLOBAL_OUTPUT="GlobalEnabled:$GLOBAL_LIST"
else
    GLOBAL_OUTPUT="GlobalEnabled:none"
fi

# Format session skills output
if [ -n "$SESSION_SKILLS" ]; then
    SESSION_LIST=$(echo "$SESSION_SKILLS" | tr '\n' ',' | sed 's/,$//')
    SESSION_OUTPUT="SessionSkills:$SESSION_LIST"
fi

# Combine output
if [ -n "$SESSION_OUTPUT" ]; then
    echo "<result>$GLOBAL_OUTPUT;$SESSION_OUTPUT</result>"
else
    echo "<result>$GLOBAL_OUTPUT</result>"
fi

exit 0