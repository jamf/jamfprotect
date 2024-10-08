#!/bin/sh
# This Extension Attribute will report on the Kafka Queue of Jamf Protect
#
# Data Type: Integer
# Input Type: Script
#
##### Script starts here #####

#Jamf Protect Location
jamfProtectBinaryLocation="/usr/local/bin/protectctl"

if [ -f "$jamfProtectBinaryLocation" ]; then
  plist=$($jamfProtectBinaryLocation info --plist)
  jamfProtectSyslogQueue=$(/usr/libexec/PlistBuddy -c "Print UploadQueue:Kafka" /dev/stdin <<<"$plist")
else
  jamfProtectSyslogQueue="Protect binary not found"
fi

echo "<result>$jamfProtectSyslogQueue</result>"
