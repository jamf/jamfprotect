#!/bin/sh
# This Extension Attribute will report on the ID of the Plan currently in-use by Jamf Protect.
#
# Data Type: String
# Input Type: Script
#
##### Script starts here #####

#Jamf Protect Location
jamfProtectBinaryLocation="/usr/local/bin/protectctl"

if [ -f "$jamfProtectBinaryLocation" ]; then
    jamfProtectPlanID=$("$jamfProtectBinaryLocation" info | awk -F 'Plan ID: ' '{print $2}' | xargs)
else
	jamfProtectPlanID="Protect binary not found"
fi

echo "<result>$jamfProtectPlanID</result>"
