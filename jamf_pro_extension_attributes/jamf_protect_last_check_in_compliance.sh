#!/bin/bash

# Filename:             JamfProtect_LastCheckinCompliance.sh
# Created by:           Ozzy van Brunschot
# Organisation:         Grafisch Lyceum Rotterdam
# E-mail:               brunschot@glr.nl
# Date:                 15.04.2021
# Version:              v0.5
# Edited by:            Allen Golbig, Jamf
# Last edit:            25/10/23
# Purpose:              Extension Attribute for checking the Jamf Protect agent's checkin with the Jamf Protect Cloud tenant and whether it cocurred within the permitted time skew
#                       This value can be used in various limiting access workflows. Expected values are:
#                       - "Protect binary not found"
#                       - "Protected"
#                       - "Not Protected"
#
# Please Note:          The default permitted time skew in this script for a successful checkin is 1 week.
##############################################################################################################################################
################ Configuration ################
# The default permitted time skew for the checkin is 1 week.  This can be adjusted as desired (S = second, M = minute, H = hour, d = day, w = week, m = month), see the -v flag in the /bin/date manual page for more details
# Note that the default checkin frequency in Jamf Protect is every 5 minutes so the minimum configuration should be ideally be 10 minutes or more
permittedSkew="1w"

######### DO NOT EDIT BELOW THIS LINE #########
# Expected path for the Jamf Protect binary
jamf_protect="/usr/local/bin/protectctl"

# Check to confirm that the Jamf Protect binary is available and, if not, set the EA varibale as not present and end
if [[ ! -f "$jamf_protect" ]]; then

    # The Jamf Protect binary isn't found in the expected location
    JPS="Protect binary not found"
    
    # Echo the EA result
    echo "<result>${JPS}</result>"
    
    # Exit the script
    exit 0
    
fi

# If the Jamf Protect binary is available the script will proceed here
# Find the current date in format %Y-%m-%d-%H-%M-%S and in seconds for later use
current_date=$(/bin/date +"%Y-%m-%d-%H-%M-%S")
current_date_sec=$(/bin/date +"%s")

# Take the current date and skew backwards with the permitted time the permitted time to find the permitted time range
skewback_current_data_sec=$(/bin/date -j -v -"$permittedSkew" -f "%Y-%m-%d-%H-%M-%S" "$current_date" +"%s")

# Gather the required information from the Jamf Protect binary
jamf_protect_info=$("$jamf_protect" info)

# Check the protection status of the Jamf Protect installation
jamf_protect_status=$(echo "$jamf_protect_info" | /usr/bin/awk '/Status/ {print $4}')

# Find the date and time of the last checkin and reformat as necessary as YY-MM-DD-HH-MM-SS
jamf_protect_lastcheckininfo=$(echo "$jamf_protect_info" | /usr/bin/awk '/Last Check-in/ {print $5}')
jamf_protect_lastcheckin=$(/bin/date -j -f "%Y-%m-%dT%H:%M:%SZ" "$jamf_protect_lastcheckininfo" "+%Y-%m-%d-%H-%M-%S")

# Convert the last checkin date and time into seconds
lastcheckin_date=$(/bin/date -j -f "%Y-%m-%d-%H-%M-%S" "$jamf_protect_lastcheckin" +"%s")

# Calculate the maximum difference in seconds between the current date and time and the permitted time skew
max_diff_sec=$(echo "$current_date_sec"-"$skewback_current_data_sec" | /usr/bin/bc | /usr/bin/tr -d "-")

# Calculate the actual difference in seconds between the current date and time and the last checkin
act_diff_checkin_sec=$(echo "$current_date_sec"-"$lastcheckin_date" | /usr/bin/bc | /usr/bin/tr -d "-")

# Compare the actual total seconds since the last checkin to the maximum difference permitted by the time skew
# If the value is less than then the endpoint is in compliance with the configured skew
# If the value is greater than then the endpoint is not in compliance with the configured skew
if [[ "$jamf_protect_status" == "Protected" ]] && [[ "$act_diff_checkin_sec" -lt "$max_diff_sec" ]]; then
  
    # The status is Protected and the most recent checkin is less than the configured time skew
    JPS="Protected"
    
elif [[ "$jamf_protect_status" == "Protected" ]] && [[ "$act_diff_checkin_sec" -gt "$max_diff_sec" ]]; then
    
    # The status is Protected but the most recent checkin is more than the configured time skew
    JPS="Protected but agent checkin overdue"

elif [[ "$jamf_protect_status" == "Not Protected" ]]; then

    # The status is not Protected
    JPS="Not Protected"
    
fi

# Name the EA something like "Jamf Protect Protection Status"
echo "<result>${JPS}</result>"