#!/bin/sh
# This Extension Attribute will report on the time of the last Inights report submitted by the Jamf Protect binary.
#
# Data Type: Date (YYYY-MM-DD hh:mm:ss)
# Input Type: Script
#
##### Script starts here #####

#Jamf Protect Location
jamfProtectBinaryLocation="/usr/local/bin/protectctl"

if [[ -f "$jamfProtectBinaryLocation" ]]; then
	plist=$($jamfProtectBinaryLocation info --plist)
	jamfProtectInfoInsightsSync=$(/usr/libexec/PlistBuddy -c "Print LastInsightsSync" /dev/stdin <<<"$plist")
    read d m dn t tz y <<< ${jamfProtectInfoInsightsSync//[- ]/ }
	m=$(/bin/date -jf %B $m '+%m')
	result=$(/bin/echo "$y"-"$m"-"$dn" "$t")
else
	result="Protect binary not found"
fi

echo "<result>$result</result>"
