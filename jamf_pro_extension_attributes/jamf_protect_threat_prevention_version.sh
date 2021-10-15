#!/bin/bash
# This Extension Attribute will report on the Threat Prevention version currently in place with Jamf Protect.
#
# Data Type: String
# Input Type: Script
#
##### Script starts here #####

#Jamf Protect Location
jamfProtectBinaryLocation="/usr/local/bin/protectctl"

if [ -f "$jamfProtectBinaryLocation" ]; then
  plist=$($jamfProtectBinaryLocation info --plist)
  jamfProtectThreatPreventionVersion=$(/usr/libexec/PlistBuddy -c "Print ThreatPreventionVersion:version" /dev/stdin <<<"$plist")
else
  jamfProtectThreatPreventionVersion="Protect binary not found"
fi

echo "<result>$jamfProtectThreatPreventionVersion</result>"
