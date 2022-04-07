#!/bin/sh
# This Extension Attribute will report on the hash of the Plan currently in-use by Jamf Protect.
#
# Data Type: String
# Input Type: Script
#
##### Script starts here #####

#Jamf Protect Location
jamfProtectBinaryLocation="/usr/local/bin/protectctl"

if [ -f "$jamfProtectBinaryLocation" ]; then
  plist=$($jamfProtectBinaryLocation info --plist)
  jamfProtectPlanHash=$(/usr/libexec/PlistBuddy -c "Print PlanHash" /dev/stdin <<<"$plist")
else
  jamfProtectPlanHash="Protect binary not found"
fi

echo "<result>$jamfProtectPlanHash</result>"
