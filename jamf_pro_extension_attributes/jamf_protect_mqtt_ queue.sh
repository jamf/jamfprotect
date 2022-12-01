#!/bin/sh
# This Extension Attribute will report on the MQTT Queue of Jamf Protect
#
# Data Type: Integer
# Input Type: Script
#
##### Script starts here #####

#Jamf Protect Location
jamfProtectBinaryLocation="/usr/local/bin/protectctl"

if [ -f "$jamfProtectBinaryLocation" ]; then
  plist=$($jamfProtectBinaryLocation info --plist)
  jamfProtectMQTTQueue=$(/usr/libexec/PlistBuddy -c "Print UploadQueue:mqtt" /dev/stdin <<<"$plist")
else
  jamfProtectMQTTQueue="Protect binary not found"
fi

echo "<result>$jamfProtectMQTTQueue</result>"

