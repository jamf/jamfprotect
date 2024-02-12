#!/bin/zsh
# This Extension Attribute will report on the state of Auto Update.
#
# Data Type: String
# Input Type: Script
#
##### Script starts here #####

#Jamf Protect Location
jamfProtectBinaryLocation="/usr/local/bin/protectctl"

if [ -f "$jamfProtectBinaryLocation" ]; then
  plist=$($jamfProtectBinaryLocation info --plist)
  jamfProtectAutoUpdate=$(/usr/libexec/PlistBuddy -c "Print :Plan:autoUpdate" /dev/stdin <<<"$plist")
else
  jamfProtectAutoUpdate="Protect binary not found"
fi

echo "<result>$jamfProtectAutoUpdate</result>"