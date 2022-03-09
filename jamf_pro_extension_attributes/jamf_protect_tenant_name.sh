#!/bin/bash
# This Extension Attribute will report on the Jamf Protect Cloud tenant that Jamf Protect is enrolled with.
#
# Data Type: String
# Input Type: Script
#
##### Script starts here #####

#Jamf Protect Location
jamfProtectBinaryLocation="/usr/local/bin/protectctl"

if [ -f "$jamfProtectBinaryLocation" ]; then
    jamfProtectTenant=$("$jamfProtectBinaryLocation" info | /usr/bin/awk -F': ' '/Tenant/{print $2}' | /usr/bin/xargs)
else
	jamfProtectTenant="Protect binary does not exist"
fi

echo "<result>$jamfProtectTenant</result>"
