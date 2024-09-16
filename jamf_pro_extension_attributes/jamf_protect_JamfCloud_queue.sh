#!/bin/sh
# This Extension Attribute will report on the JamfCloud Queue of Jamf Protect
#
# Data Type: Integer
# Input Type: Script
#
##### Script starts here #####

#Jamf Protect Location
jamfProtectBinaryLocation="/usr/local/bin/protectctl"

if [ -f "$jamfProtectBinaryLocation" ]; then
  plist=$($jamfProtectBinaryLocation info --plist)
  jamfProtectJamfcloudQueue=$(/usr/libexec/PlistBuddy -c "Print UploadQueue:JamfCloud" /dev/stdin <<<"$plist")
else
  jamfProtectJamfcloudQueue="Protect binary not found"
fi

echo "<result>$jamfProtectJamfcloudQueue</result>"

