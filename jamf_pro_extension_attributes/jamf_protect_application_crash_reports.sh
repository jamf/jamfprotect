#!/bin/bash
# This Extension Attribute will report on any Jamf Protect crash reports present on the managed endpoint from the Jamf Protect application.
#
# Data Type: String
# Input Type: Script
#
##### Script starts here #####

jamfProtectBinaryLocation="/usr/local/bin/protectctl"

# Check to confirm that the Jamf Protect binary is available and, if not, set the EA varibale as not present and end
if [[ ! -f "$jamfProtectBinaryLocation" ]]; then
    
    # Echo the EA result
    echo "<result>Protect binary not found</result>"
    
    # Exit the script
    exit 0
    
fi

# Capture the verbose information output from the Jamf Protect application in the form of a plist
jamfProtectInfoPlist=$("$jamfProtectBinaryLocation" info -v --plist)

# Check for the present of any crash files detected by the Jamf Protect application
jamfProtectCrashFiles=$(/usr/libexec/PlistBuddy -c "Print Crashes:files" /dev/stdin <<<"$jamfProtectInfoPlist" | sed -e '1d' -e 's/Array//' -e 's/[{}]//g')

if [[ ! -z "$jamfProtectCrashFiles" ]]; then
    
    # Return a list of file paths for the crash files detected
    echo "<result>$jamfProtectCrashFiles</result>"

else
        
    echo "<result>No Crash Files Found</result>"

fi
