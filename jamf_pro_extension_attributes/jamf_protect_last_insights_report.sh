#!/bin/sh
# This Extension Attribute will report on the time of the last Inights report submitted by the Jamf Protect binary.
#
# Data Type: String
# Input Type: Script
#
##### Script starts here #####

#Jamf Protect Location
jamfProtectBinaryLocation="/usr/local/bin/protectctl"

if [ -f "$jamfProtectBinaryLocation" ]; then
    plist=$($jamfProtectBinaryLocation info --plist)
    jamfProtectInfoInsightsSync=$(/usr/libexec/PlistBuddy -c "Print LastInsightsSync" /dev/stdin <<<"$plist")
else
	jamfProtectInfoInsightsSync="Protect binary not found"
fi

echo "<result>$jamfProtectInfoInsightsSync</result>"
