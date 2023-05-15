#!/bin/sh
# This Extension Attribute will report on the diagnostics state currently set by Jamf Protect
#
# Data Type: String
# Input Type: Script
#
##### Script starts here #####

jamfProtectBinaryLocation="/usr/local/bin/protectctl"

if [ -f "$jamfProtectBinaryLocation" ]; then
  plist=$($jamfProtectBinaryLocation info --plist)
  jamfProtectDiagnostics=$(/usr/libexec/PlistBuddy -c "Print Diagnostics" /dev/stdin <<<"$plist")
else
  jamfProtectDiagnostics="Protect binary not found"
fi

echo "<result>$jamfProtectDiagnostics</result>"