#!/bin/bash
# This Extension Attribute will report on all files existing in the Jamf Protect 'groups' directory, used by the Analytic action 'Add to Jamf Pro Smart Group' to invoke the Jamf Protect and Jamf Pro response integration.
#
# Data Type: String
# Input Type: Script
#
##### Script starts here #####

SMARTGROUPS_DIR=/Library/Application\ Support/JamfProtect/groups
if [ -d "$SMARTGROUPS_DIR" ]; then
	SMART_GROUPS=`/bin/ls "$SMARTGROUPS_DIR" | /usr/bin/tr '\n' ','`
	echo "<result>${SMART_GROUPS%?}</result>"
else
	echo "<result></result>"
fi
