#!/bin/sh
# This Extension Attribute will report on the Local Log File queue of Jamf Protect
#
# Data Type: Integer
# Input Type: Script
#
##### Script starts here #####

#Jamf Protect Location
jamfProtectBinaryLocation="/usr/local/bin/protectctl"

if [ -f "$jamfProtectBinaryLocation" ]; then
  plist=$($jamfProtectBinaryLocation info --plist)
  jamfProtectLogfileQueue=$(/usr/libexec/PlistBuddy -c "Print UploadQueue:LogFile" /dev/stdin <<<"$plist")
else
  jamfProtectLogfileQueue="Protect binary not found"
fi

echo "<result>$jamfProtectLogfileQueue</result>"

