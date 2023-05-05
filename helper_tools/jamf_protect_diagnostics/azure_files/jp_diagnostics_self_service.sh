#!/bin/bash

####################################################################################################
#
# Copyright (c) 2023, Jamf Software, LLC.  All rights reserved.
#
#       Redistribution and use in source and binary forms, with or without
#       modification, are permitted provided that the following conditions are met:
#               * Redistributions of source code must retain the above copyright
#                 notice, this list of conditions and the following disclaimer.
#               * Redistributions in binary form must reproduce the above copyright
#                 notice, this list of conditions and the following disclaimer in the
#                 documentation and/or other materials provided with the distribution.
#               * Neither the name of the JAMF Software, LLC nor the
#                 names of its contributors may be used to endorse or promote products
#                 derived from this software without specific prior written permission.
#
#       THIS SOFTWARE IS PROVIDED BY JAMF SOFTWARE, LLC "AS IS" AND ANY
#       EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#       WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#       DISCLAIMED. IN NO EVENT SHALL JAMF SOFTWARE, LLC BE LIABLE FOR ANY
#       DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#       (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#       LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#       ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#       (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#       SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
####################################################################################################
# Jamf Protect Diagnostics Collection
# v1.0

#####################################################
############# Script Configuration Area #############
#####################################################

# Set custom duration for Jamf Protect Diagnostics, default is 5 minutes, use $4 in a Jamf Pro policy or edit value in script on line 38.
customDuration="$4"

# Location of the Azure Copy CLI binary.
azcopyBinary=""

# The name of the Azure Storage Account
azureStorageAccount=""

# The name of the Azure File Name
azureFileShareName=""

# The name of the folder in the Azure Files Container
azureFileShareFolder=""

# The SAS Token, stored in Jamf Pro as Parameter 4 in a policy
azureSasToken=$4


#####################################################
############ DO NOT EDIT BELOW THIS LINE ############
#####################################################


# Getting logged in user
loggedInUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')

# Find files that match the pattern on the users desktop
diagnostics_files=$(find /Users/"$loggedInUser"/Desktop -name 'JamfProtectDiagnostics*.*.zip' -a -mmin +10)

# Expected AWS CLI Binary TeamID
expectedAzcopyTeamID="94KV3E626L"

################# Script Functions ##################

startDiagnostics () {
	
	if [ "$customDuration" == "" ]; then
		echo "Staring Jamf Protect Diagnostics for a duration of 5 minutes"
		/usr/local/bin/protectctl diagnostics
	else
		echo "Staring Jamf Protect Diagnostics for a duration of $customDuration minutes"
		/usr/local/bin/protectctl diagnostics -d "$customDuration"
	fi
}

# Checks for the Jamf Protect Diagnostics archive to confirm if the script should continue
CheckForFiles () {
	if [ -n "$diagnostics_files" ]; then
		echo "Jamf Protect Diagnostic Files found"
		echo "$diagnostics_files"
	else
		echo "Jamf Protect Diagnostic Files were not found"
		exit 1
	fi
}

# Upload the Jamf Protect Diagnostics archive to Azure Files using the azcopy binary
CollectArchive () {
    if [[ -n "$azureStorageAccount" ]]; then
    
        # Check for the Azure Copy binary. If not present, install.
        if [[ ! -f "$azcopyBinary" ]]; then
            echo "Azure Copy CLI not Installed, downloading and installing"
        	/usr/bin/curl -Ls https://aka.ms/downloadazcopy-v10-mac --output /tmp/azcopy.zip
            /usr/bin/unzip -j -qq "/tmp/azcopy.zip" -d "$azcopyBinary"
		
			# Verify the download
			teamID=$(codesign -dv "$azcopyBinary" 2>&1 | grep TeamIdentifier | awk -F '=' '{print $2}')

			# Check and clean up the binary if Team ID does not validate
			if [ "$expectedAzcopyTeamID" = "$teamID" ] || [ "$expectedAzcopyTeamID" = "" ]; then
				echo "azcopy Team ID verification succeeded"
				/bin/rm "/tmp/azcopy.zip"
			else
				echo "azcopy Team ID verification failed."
                /bin/rm -rf "$azcopyBinary"
                /bin/rm -rf /Users/"$loggedInUser"/.azcopy
				/bin/rm "/tmp/azcopy.zip"
				exit 1
			fi
        fi

        export azcopyInstallStatus=$?
        
        if [[ "$azcopyInstallStatus" -eq 0 ]]; then
            echo "Azure Copy CLI Installed."
        else
            echo "Azure Copy CLI is not installed. Please try again."
            exit 1
        fi

        if [[ "$azcopyInstallStatus" -eq 0 ]]; then

            # Use the Azure Copy CLI to copy the archive to the desginated bucket
            echo "The Azure Copy binary is present, initiating the upload.."
            "$azcopyBinary/azcopy" copy "/Users/$loggedInUser/Desktop"/*JamfProtectDiagnostics*.zip "https://${azureStorageAccount}.file.core.windows.net/${azureFileShareName}/${azureFileShareFolder}/${azureSasToken}" --recursive=true
            
            export uploadStatus=$?
            
            # Report back the status of the upload
            if [[ "$uploadStatus" -eq 0 ]]; then
                echo "The upload to Azure Files was successful and finished with exit code ${uploadStatus}."
            else
                echo "The upload to Azure Files failed with error code ${uploadStatus}."
            fi
        fi
    
    else

        echo "Azure Copy information was not configured."
        export uploadStatus="1"
        
    fi
}


# Check for the required network connectivity to use the Azure File Share service
NetworkCheckAndUpload () {
    if /usr/bin/nc -zdw1 "$azureStorageAccount".file.core.windows.net 443; then
        networkUP="yes"
        echo "Can the device connect to the Azure File Share for upload? Result: ${networkUP}"
        echo "Network connectivity is available so the upload will proceed."
    
        # Call CollectArchive function
        CollectArchive
    else
        networkUP="no"
        echo "Can the device connect to the Azure File Share for upload? Result: ${networkUP}"
        echo "Network connectivity is not available, exiting."
        exit 1
    fi
}

# Clean up and end this workflow
CleanUp () {
	
	# Clean up the Jamf Protect Diagnostics archive if upload was sucecessful
	echo "Removing Jamf Protect Diagnostics archive."
	if [[ "$uploadStatus" -eq 0 ]]; then
		/bin/rm "/Users/$loggedInUser"/JamfProtectDiagnostics*
	fi
	
    # Remove Azure Copy CLI and .azcopy directory
    echo "Removing Azure Copy CLI and directories"
    /bin/rm -rf $azcopyBinary
    /bin/rm -rf /Users/$loggedInUser/.azcopy
}

startDiagnostics
CheckForFiles
CollectArchive
NetworkCheckAndUpload 
cleanUp

