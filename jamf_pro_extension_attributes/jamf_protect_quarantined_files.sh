#!/bin/bash
# This Extension Attribute will report on the presence of files in the Jamf Protect file quarantine directory, placed there when known malware is prevented from executing due to a signature detection match with the Threat Prevention feature.
#
# Data Type: String
# Input Type: Script
#
##### Script starts here #####

QUARANTINE_FILES=$(/bin/ls /Library/Application\ Support/JamfProtect/Quarantine)
if [[ -z "$QUARANTINE_FILES" ]]; then

    echo "<result>No</result>"
    
else
        
    echo "<result>Yes</result>"
fi
