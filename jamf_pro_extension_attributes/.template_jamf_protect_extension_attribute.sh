#!/bin/bash
# This Extension Attribute will report on <insert general description of the purpose of this Extension Attribute>
#
# Data Type: <insert Data Type here for the Jamf Pro field.  Commonly this will be 'String'>
# Input Type: Script
#
# Expected Results: <insert expected results to be returned from this Extension Attribute script>
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

# Script continues here
