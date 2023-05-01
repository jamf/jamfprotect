#!/bin/bash

####################################################################################################
#
# Copyright (c) 2022, Jamf Software, LLC.  All rights reserved.
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
# Aftermath Collection
# v1.0

# Jamf Protect Analytic smartgroup identifier
analyticEA=""

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

# Aftermath Archive Directory
aftermathArchiveDir=""

# The logged in User
loggedInUser=$(stat -f %Su /dev/console)


###########################################
############ Do not edit below ############
###########################################

expectedAzcopyTeamID="94KV3E626L"

# Checks for the Aftermath archive to confirm if the script should continue
CheckForFiles () {
    if [[ -z $(/bin/ls -A "$aftermathArchiveDir"/Aftermath*) ]]; then
        echo "There is no Aftermath archive in ${aftermathArchiveDir}. Exiting."
        exit 1
    else
        echo "There is an Aftermath archive present in ${aftermathArchiveDir}. Proceeding."
    fi
}

# Upload the Aftermath archive to Azure Files using the Azure Copy CLI
CollectArchive () {
    if [[ -n "$azureStorageAccount" ]]; then
    
        # Check for the Azure Copy binary. If not present, install.
        if [[ ! -f "$azcopyBinary" ]]; then
            echo "Azure Copy CLI not Installed, downloading and installing"
        	/usr/bin/curl -Ls https://aka.ms/downloadazcopy-v10-mac --output /tmp/azcopy.zip
            /usr/bin/unzip -j -qq "/tmp/azcopy.zip" -d $azcopyBinary
		
			# Verify the download
			teamID=$(codesign -dv "$azcopyBinary" 2>&1 | grep TeamIdentifier | awk -F '=' '{print $2}')

			# Check and clean up the binary if Team ID does not validate
			if [ "$expectedAzcopyTeamID" = "$teamID" ] || [ "$expectedAzcopyTeamID" = "" ]; then
				echo "azcopy Team ID verification succeeded"
				/bin/rm "/tmp/azcopy.zip"
			else
				echo "azcopy Team ID verification failed."
                /bin/rm -rf $azcopyBinary
                /bin/rm -rf /Users/$loggedInUser/.azcopy
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
            "$azcopyBinary/azcopy" copy ${aftermathArchiveDir}/*Aftermath*.zip "https://${azureStorageAccount}.file.core.windows.net/${azureFileShareName}/${azureFileShareFolder}/${azureSasToken}" --recursive=true
            
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
    if /usr/bin/nc -zdw1 $azureFileShare.file.core.windows.net 443; then
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

    # Clean up the Aftermath archive if upload was sucecessful
    echo "Removing Aftermath archive."
    if [[ "$uploadStatus" -eq 0 ]]; then
        /bin/rm "$aftermathArchiveDir"/Aftermath*
    fi

    # Remove Azure Copy CLI and .azcopy directory
    echo "Removing Azure Copy CLI and directories"
    /bin/rm -rf $azcopyBinary
    /bin/rm -rf /Users/$loggedInUser/.azcopy
    
    # Delete the extension attribute file created by Jamf Protect
    if [[ -n "$analyticEA" ]]; then
        echo "Cleaning up the extension attribute file created by Jamf Protect."
        /bin/rm "/Library/Application Support/JamfProtect/groups/$analyticEA"
    else
        echo "Attempted to clean up the extension attribute file created by Jamf Protect, but no file path was provided."
    fi

    # Run one last recon to update Smart Groups status
    echo "Running Jamf Recon to update Computer inventory"
    /usr/local/bin/jamf recon &
}

CheckForFiles
NetworkCheckAndUpload
CleanUp