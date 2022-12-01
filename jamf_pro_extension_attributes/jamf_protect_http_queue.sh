#!/bin/sh
# This Extension Attribute will report on the HTTP Queue of Jamf Protect
#
# Data Type: Integer
# Input Type: Script
#
##### Script starts here #####

#Jamf Protect Location
jamfProtectBinaryLocation="/usr/local/bin/protectctl"

if [ -f "$jamfProtectBinaryLocation" ]; then
  jamfProtectQueue=$("$jamfProtectBinaryLocation" info -v | awk -F '[|]' '/HTTP Queue/ {print $0}' | grep -o '[0-9]\+')		
else
  jamfProtectQueue="Protect binary not found"
fi

echo "<result>${jamfProtectQueue}</result>"

