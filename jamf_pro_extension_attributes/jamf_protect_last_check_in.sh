#!/bin/sh
# This Extension Attribute will report on the last check-in date of the Jamf Protect binary.
#
# Data Type: Date (YYYY-MM-DD hh:mm:ss)
# Input Type: Script
#
##### Script starts here #####

#Jamf Protect Location
jamfProtectBinaryLocation="/usr/local/bin/protectctl"

if [[ -f "$jamfProtectBinaryLocation" ]]; then
	plist=$($jamfProtectBinaryLocation info --plist)
	jamfProtectLastCheckin=$(/usr/libexec/PlistBuddy -c "Print LastCheckin" /dev/stdin <<<"$plist")
	read d m dn t tz y <<< ${jamfProtectLastCheckin//[- ]/ }
	m=$(/bin/date -jf %B $m '+%m')
	result=$(/bin/echo "$y"-"$m"-"$dn" "$t")
else
	result="Protect binary not found"
fi

echo "<result>$result</result>"
