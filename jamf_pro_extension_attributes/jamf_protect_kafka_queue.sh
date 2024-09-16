#!/bin/sh
# This Extension Attribute will report on the SysLog Queue of Jamf Protect
#
# Data Type: Integer
# Input Type: Script
#
##### Script starts here #####

#Jamf Protect Location
jamfProtectBinaryLocation="/usr/local/bin/protectctl"

if [ -f "$jamfProtectBinaryLocation" ]; then
  plist=$($jamfProtectBinaryLocation info --plist)
  jamfProtectKafkaQueue=$(/usr/libexec/PlistBuddy -c "Print UploadQueue:SysLog" /dev/stdin <<<"$plist")
else
  jamfProtectKafkaQueue="Protect binary not found"
fi

echo "<result>$jamfProtectKafkaQueue</result>"
