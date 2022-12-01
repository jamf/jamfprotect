#!/bin/sh
# This Extension Attribute will report on the HTTP Queue of Jamf Protect
#
# Data Type: Integer
# Input Type: Script
#
##### Script starts here #####

jamfProtectBinaryLocation="/usr/local/bin/protectctl"

if [ -f "$jamfProtectBinaryLocation" ]; then
  plist=$($jamfProtectBinaryLocation info --plist)
  jamfProtectHTTPQueue=$(/usr/libexec/PlistBuddy -c "Print UploadQueue:https" /dev/stdin <<<"$plist")
else
  jamfProtectHTTPQueue="Protect binary not found"
fi

echo "<result>$jamfProtectHTTPQueue</result>"
