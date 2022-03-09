#!/bin/sh
# This Extension Attribute will report on the installed version of the Jamf Protect binary.
#
# Data Type: String
# Input Type: Script
#
##### Script starts here #####

#Jamf Protect Location
jamfProtectBinaryLocation="/usr/local/bin/protectctl"

if [ -f "$jamfProtectBinaryLocation" ]; then
    jamfProtectVersion=$("$jamfProtectBinaryLocation" version | /usr/bin/awk -F': ' '/Version/{print $2}')
else
	jamfProtectVersion="Protect binary not found"
fi

echo "<result>$jamfProtectVersion</result>"
