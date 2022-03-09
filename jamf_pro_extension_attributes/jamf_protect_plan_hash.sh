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
    jamfProtectPlanHash=$("$jamfProtectBinaryLocation" info | /usr/bin/awk -F': ' '/Plan Hash/{print $2}' | /usr/bin/xargs)
else
	jamfProtectPlanHash="Protect binary not found"
fi

echo "<result>$jamfProtectPlanHash</result>"
