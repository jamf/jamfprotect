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
  plist=$($jamfProtectBinaryLocation info --plist)
  jamfProtectTenant=$(/usr/libexec/PlistBuddy -c "Print Tenant" /dev/stdin <<<"$plist")
else
  jamfProtectTenant="Protect binary not found"
fi

echo "<result>$jamfProtectTenant</result>"
