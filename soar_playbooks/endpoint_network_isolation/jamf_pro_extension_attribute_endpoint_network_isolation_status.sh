#!/bin/bash
# This Extension Attribute will report on the presence of the Packet Filter rules file created on devices as a part of the endpoint_network_isolation_enforce.sh workflow, for isolating an endpoint from other devices.  This scripted workflow can be found here: https://github.com/jamf/jamfprotect/blob/main/soar_playbooks/endpoint_network_isolation/endpoint_network_isolation_enforce.sh
# If deploying this scripted workflow simply add an inventory update to the Jamf Pro Policy (Maintenance payload) and enable this Extension Attribute for reporting capability on the isolation workflow being in place.
#
# Data Type: String
# Input Type: Script
#
##### Script starts here #####

jamfProtectBinaryLocation="/usr/local/bin/protectctl"

# This is the file name that we're going to look for.  The value of this variable MUST match the same value used in the actual endpoint_network_isolation_enforce.sh script deployed for this workflow that we're reporting on with this Extension Attribute
fileName="com.acmesoft.isolate"

# This is the hardcoded path used in the scripted workflow mentioned above for the pf conf anchors file
pfRulesFile="/etc/pf.anchors/${fileName}.pf.conf"

pfRulesEnforced=$(/sbin/pfctl -s rules | /usr/bin/grep "$fileName")

# Check to confirm that the Jamf Protect binary is available and, if not, set the EA varibale as not present and end
if [[ ! -f "$jamfProtectBinaryLocation" ]]; then
    
    # Echo the EA result
    echo "<result>Protect binary not found</result>"
    
    # Exit the script
    exit 0
    
fi

# Check for the rules file being present and currently enforced

if [[ -f "$pfRulesFile" ]] && [[ ! -z "$pfRulesEnforced" ]]; then

	echo "<result>Enforced</result>"

elif [[ -f "$pfRulesFile" ]] && [[ -z "$pfRulesEnforced" ]]; then

	echo "<result>Not Enforced - Network Isolation Rules File Found</result>"

elif [[ ! -f "$pfRulesFile" ]] && [[ ! -z "$pfRulesEnforced" ]]; then

	echo "<result>Enforced - Network Isolation Rules File Missing</result>" 

elif [[ ! -f "$pfRulesFile" ]] && [[ -z "$pfRulesEnforced" ]]; then

	echo "<result>Not Enforced</result>"

fi
