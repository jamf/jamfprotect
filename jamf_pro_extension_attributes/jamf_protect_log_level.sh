#!/bin/sh
# This Extension Attribute will report on the Log Level currently in-use by Jamf Protect
#
# Data Type: String
# Input Type: Script
#
##### Script starts here #####

jamfProtectBinaryLocation="/usr/local/bin/protectctl"

if [ -f "$jamfProtectBinaryLocation" ]; then
  plist=$($jamfProtectBinaryLocation info --plist)
  jamfProtectLogLevel=$(/usr/libexec/PlistBuddy -c "Print LogLevel" /dev/stdin <<<"$plist")
else
  jamfProtectLogLevel="Protect binary not found"
fi

echo "<result>$jamfProtectLogLevel</result>"