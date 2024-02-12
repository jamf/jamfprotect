#!/bin/zsh
# This Extension Attribute will report on the state of Tamper Prevention.
#
# Data Type: String
# Input Type: Script
#
##### Script starts here #####

#Jamf Protect Location
jamfProtectBinaryLocation="/usr/local/bin/protectctl"

if [ -f "$jamfProtectBinaryLocation" ]; then
  plist=$($jamfProtectBinaryLocation info --plist)
  jamfProtectTamperPrevention=$(/usr/libexec/PlistBuddy -c "Print :Plan:Configuration:0:Enabled" /dev/stdin <<<"$plist")
else
  jamfProtectTamperPrevention="Protect binary not found"
fi

echo "<result>$jamfProtectTamperPrevention</result>"

