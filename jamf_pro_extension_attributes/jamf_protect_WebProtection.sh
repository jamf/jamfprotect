#!/bin/zsh
# This Extension Attribute will report on the state of Web Protection.
#
# Data Type: String
# Input Type: Script
#
##### Script starts here #####

#Jamf Protect Location
jamfProtectBinaryLocation="/usr/local/bin/protectctl"

if [ -f "$jamfProtectBinaryLocation" ]; then
  plist=$($jamfProtectBinaryLocation info --plist)
  jamfProtectWebProtection=$(/usr/libexec/PlistBuddy -c "Print :Plan:WebProtection" /dev/stdin <<<"$plist")
else
  jamfProtectWebProtection="Protect binary not found"
fi

echo "<result>$jamfProtectWebProtection</result>"