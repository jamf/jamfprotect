#!/usr/bin/bash
# Extension Attribute to display the status of Jamf Protect

# Created by macstuff.dev - Melwin Moeskops 
#   Display Name: Jamf Protect Status
#   Data type: String
#   Expected results: Protected, Enrolling, Missing Plan, Disconnected, Missing CA, Protect binary does not exist.

# Jamf Protect Location
jamfProtectBinaryLocation="/usr/local/bin/protectctl"

if [[ -f "$jamfProtectBinaryLocation" ]]; then
	jamfProtectStatus=$("$jamfProtectBinaryLocation" info | /usr/bin/awk -F 'Status: ' '{print $2}' | /usr/bin/xargs)
else
	jamfProtectStatus="Protect binary does not exist"
fi

# Display the current status
echo "<result>${jamfProtectStatus}</result>"
