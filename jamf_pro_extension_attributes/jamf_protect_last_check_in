#!/bin/sh
# This Extension Attribute will report on the last check-in date of the Jamf Protect binary.
#
# Data Type: String
# Input Type: Script
#
##### Script starts here #####

#Jamf Protect Location
jamfProtectBinaryLocation="/usr/local/bin/protectctl"

if [ -f "$jamfProtectBinaryLocation" ]; then
    jamfProtectLastCheckin=$("$jamfProtectBinaryLocation" info | awk -F 'Last Check-in:' '{print $2}' | xargs)
else
	jamfProtectLastCheckin="Protect binary not found"
fi

echo "<result>$jamfProtectLastCheckin</result>"
