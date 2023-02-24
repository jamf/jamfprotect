#!/bin/sh

jamfProtectBinaryLocation="/usr/local/bin/protectctl"

if [ -f "$jamfProtectBinaryLocation" ]; then
  plist=$($jamfProtectBinaryLocation info --plist)
  jamfProtectLogLevel=$(/usr/libexec/PlistBuddy -c "Print LogLevel" /dev/stdin <<<"$plist")
else
  jamfProtectLogLevel="Protect binary not found"
fi

echo "<result>$jamfProtectLogLevel</result>"