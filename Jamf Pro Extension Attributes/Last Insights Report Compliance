#!/bin/bash

# Filename:             JamfProtect_LastInsightsReportCompliance.sh
# Created by:           Ozzy van Brunschot, Matt Taylor (Jamf)
# Organisation:         Grafisch Lyceum Rotterdam
# E-mail:               brunschot@glr.nl
# Date:                 24.09.2021
# Version:              v1.0
# Edited by:
# Last edit:            24/9/21
# Purpose:              Extension Attribute for checking the Jamf Protect agent's latest Insights report submission and whether it cocurred within the permitted time skew
#                       This value can be used in various limiting access workflows. Expected values are:
#                       - "Protect binary not found"
#                       - "Compliant"
#                       - "Not Compliant"
#
# Please Note:          The default permitted time skew in this script for a successful Insights report is 1 week.
##############################################################################################################################################
################ Configuration ################
# The default permitted time skew for the Insights report is 1 week.  This can be adjusted as desired (S = second, M = minute, H = hour, d = day, w = week, m = month), see the -v flag in the /bin/date manual page for more details
# Note that the default Insights report frequency in Jamf Protect is daily (1440 minutes) so the minimum configuration should ideally be 2D
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
# Find the current date in format %m-%d-%Y and in seconds for later use
current_date=$(/bin/date +"%m-%d-%Y")
current_date_sec=$(/bin/date +"%s")

# Take the current date and skew backwards with the permitted time the permitted time to find the permitted time range
skewback_current_data_sec=$(/bin/date -j -v -"$permittedSkew" -f "%m-%d-%Y" "$current_date" +"%s")

# Find the date and time of the last Insights report and reformat as necessary as MM-DD-YY-HH-MM-SS
jamf_protect_lastinsights=$("$jamf_protect" info | /usr/bin/grep "Last Insights" | /usr/bin/awk '{ print $3, $4 }' | /usr/bin/sed -e 's/ /-/g' -e 's/:/-/g' -e 's/\./-/g')

# Convert the last Insights report date and time into seconds
lastinsights_date=$(/bin/date -j -f "%m-%d-%Y-%H-%M-%S" "$jamf_protect_lastinsights" +"%s")

# Calculate the maximum difference in seconds between the current date and time and the permitted time skew
max_diff_sec=$(echo "$current_date_sec"-"$skewback_current_data_sec" | /usr/bin/bc | /usr/bin/tr -d "-")

# Calculate the actual difference in seconds between the current date and time and the last Insights report
act_diff_insights_sec=$(echo "$current_date_sec"-"$lastinsights_date" | /usr/bin/bc | /usr/bin/tr -d "-")

# Compare the actual total seconds since the last Insights report to the maximum difference permitted by the time skew
# If the value is less than then the endpoint is in compliance with the configured skew
# If the value is greater than then the endpoint is not in compliance with the configured skew
if [[ "$act_diff_insights_sec" -lt "$max_diff_sec" ]]; then
  
    # The most recent Insights report is less than the configured time skew
    JPS="Compliant"
    
else
    
    #  The most recent Insights report is more than the configured time skew
    JPS="Not Compliant"

fi

# Name the EA something like "Latest Insights Report Date"
echo "<result>${JPS}</result>"

