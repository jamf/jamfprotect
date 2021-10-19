#!/bin/bash
# This Extension Attribute will report on the running status of the Jamf Protect application on the managed endpoint, by checking for first the System Extension and, if needed, the Jamf Protect launch service.
#
# Data Type: String
# Input Type: Script
#
##### Script starts here #####

jamfProtectBinaryLocation="/usr/local/bin/protectctl"

sysExtensions=$(/usr/bin/systemextensionsctl list)

jpSysExtension=$(echo "$sysExtensions" | /usr/bin/grep -i -w 'com.jamf.protect.security-extension')

jpSysExtensionStatus=$(echo "$sysExtensions" | /usr/bin/grep -i -w 'com.jamf.protect.security-extension.*activated enabled')

# Check to confirm that the Jamf Protect binary is available and, if not, set the EA varibale as not present and end
if [[ ! -f "$jamfProtectBinaryLocation" ]]; then
    
    # Echo the EA result
    echo "<result>Protect binary not found</result>"
    
    # Exit the script
    exit 0
    
fi

# Check for the presence and status of the Jamf Protect System Extension
# If the Jamf Protect System Extension is installed but it's not marked as [activated enabled] then return the whole output of the list command
if [[ ! -z "$jpSysExtension" ]] && [[ -z "$jpSysExtensionStatus" ]]; then

    echo "<result>No Active and Enabled System Extension - ${jpSysExtension}</result>"

# If the Jamf Protect System Extension is installed and is [activated enabled] then return this as a status
elif [[ ! -z "$jpSysExtensionStatus" ]]; then

    echo "<result>System Extension - Active and Enabled</result>"
    
# If the Jamf Protect System Extension isn't installed at all, check to confirm if Jamf Protect is running as a Launch service, reporting the results
elif [[ -z "$jpSysExtension" ]]; then

    # Check for Jamf Protect running as a Launch Service
    jpDaemonProcess=$(/usr/bin/pgrep -x "JamfProtect")
    
    if [[ -z "$jpDaemonProcess" ]]; then
    
        echo "<result>No Active System Extension or Launch Service</result>"
        
    else
    
        echo "<result>Launch Service - Active</result>"
        
    fi
    
fi
