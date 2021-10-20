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

jpSysExtensionProcess=$(/usr/bin/pgrep -x "com.jamf.protect.security-extension")

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

    echo "<result>System Extension - Installed but Not Active and Not Enabled - $jpSysExtension</result>"

# If the Jamf Protect System Extension is installed, is [activated enabled] and there is an active process then return this as a status
elif [[ ! -z "$jpSysExtensionStatus" ]] && [[ ! -z "$jpSysExtensionProcess" ]]; then

    echo "<result>System Extension - Active and Enabled</result>"
    
# If the Jamf Protect System Extension is installed, is [activated enabled] but there is no active process then return this as a status
elif [[ ! -z "$jpSysExtensionStatus" ]] && [[ -z "$jpSysExtensionProcess" ]]; then

    echo "<result>System Extension - Enabled but Not Active</result>"
    
# If the Jamf Protect System Extension isn't installed at all, check to confirm if Jamf Protect is running as a Launch service, reporting the results
elif [[ ! -z "$jpSysExtension" ]]; then

    jpDaemonProcess=$(/usr/bin/pgrep -x "JamfProtect")
    
    if [[ -z "$jpDaemonProcess" ]]; then
    
        echo "<result>No Active System Extension or Launch Service</result>"
        
    else
    
        echo "<result>Launch Service - Active</result>"
        
    fi
    
fi

