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
# Aftermath Collection - Google Cloud 
# v1.0

# Jamf Protect Analytic smartgroup identifier
analyticEA="aftermath"

# Location of the gsutil binary.
gsutilBinary="/usr/local/google-cloud-sdk/bin/gsutil"

# The name of the target Google Cloud bucket resource
gcsBucket=""

# Aftermath Archive Directory
aftermathArchiveDir=""

# Boto Config Location
botoConfig=""

###########################################
############ Do not edit below ############
###########################################

# Checks for the Aftermath archive to confirm if the script should continue
CheckForFiles () {
    if [[ -z $(/bin/ls -A "$aftermathArchiveDir"/Aftermath*) ]]; then
        echo "There is no Aftermath archive in ${aftermathArchiveDir}. Exiting."
        exit 1
    else
        echo "There is an Aftermath archive present in ${aftermathArchiveDir}. Proceeding."
    fi
}

# Upload the Aftermath archive to Google Clound Bucket using gsutil
CollectArchive () {
    if [[ -n "$gcsBucket" ]]; then
    
        # Check for the gsutil binary. If not present, install the Google Cloud SDK.
        if [[ ! -f "$gsutilBinary" ]]; then
            /usr/bin/curl https://sdk.cloud.google.com > /tmp/install.sh
            /bin/bash /tmp/install.sh --disable-prompts --install-dir /usr/local &>/dev/null
        fi
        
        export gsutilInstallStatus=$?

        if [[ "$gsutilInstallStatus" -eq 0 ]]; then
            echo "Google Cloud SDK Installed. Installing Boto configuration file."
            /usr/local/bin/jamf policy -event gcs_creds
            export botoConfigStatus=$?
        else
            echo "gsutil is not installed. Please try again."
            exit 1
        fi

        if [[ "$botoConfigStatus" -eq 0 ]]; then
            export BOTO_CONFIG="$botoConfig"

            # Use the gsutil to copy the archive to the desginated bucket
            echo "Gsutil is present, initiating the upload.."
            "$gsutilBinary" cp "$aftermathArchiveDir"/Aftermath* gs://"$gcsBucket"
            
            export uploadStatus=$?
            
            # Report back the status of the upload
            if [[ "$uploadStatus" -eq 0 ]]; then
                echo "The upload to the Google Cloud bucket was successful and finished with exit code ${uploadStatus}."
            else
                echo "The upload to the Google Cloud bucket failed with error code ${uploadStatus}."
            fi
        else
            echo "The Boto configuration file is not present. Please try again."
            exit 1
        fi
    
    else

        echo "Google Cloud bucket information was not configured."
        export uploadStatus="1"
        
    fi
}

# Check for the required network connectivity to use the Google Cloud Storage service
NetworkCheckAndUpload () {
    if /usr/bin/nc -zdw1 console.cloud.google.com 443; then
        networkUP="yes"
        echo "Can the device connect to the Google Cloud bucket for upload? Result: ${networkUP}"
        echo "Network connectivity is available so the upload will proceed."
    
        # Call CollectArchive function
        CollectArchive
    else
        networkUP="no"
        echo "Can the device connect to the Google Cloud bucket for upload? Result: ${networkUP}"
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

    # Remove Google Cloud SDK and Boto configuration file
    echo "Removing Google Cloud SDK and Boto configuration file."
    /bin/rm -rf /usr/local/google-cloud-sdk
    /bin/rm /tmp/install.sh
    /bin/rm -r /opt/.boto
    
    # Delete the extension attribute file created by Jamf Protect
    if [[ -n "$analyticEA" ]]; then
        echo "Cleaning up the extension attribute file created by Jamf Protect."
        /bin/rm "/Library/Application Support/JamfProtect/groups/$analyticEA"
    else
        echo "Attempted to clean up the extension attribute file created by Jamf Protect, but no file path was provided."
    fi

    # Run one last recon to update Smart Groups status
    /usr/local/bin/jamf recon &
}

CheckForFiles
NetworkCheckAndUpload
CleanUp