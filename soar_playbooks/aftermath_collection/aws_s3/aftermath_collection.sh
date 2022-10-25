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
analyticEA="aftermath"

# Location of the AWS CLI binary.
awsBinary="/usr/local/bin/aws"

# The name of the target S3 bucket resource
s3Bucket=""

# The region of the S3 bucket to use. Example: us-east-1
s3BucketRegion=""

# Aftermath Archive Directory
aftermathArchiveDir=""

# AWS Profile Name
awsProfile=""

# AWS Folder
awsFolder=""

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

# Upload the Aftermath archive to Amazon S3 using the AWS CLI
CollectArchive () {
    if [[ -n "$s3Bucket" ]] && [[ -n "$s3BucketRegion" ]]; then
    
        # Check for the AWS binary. If not present, install.
        if [[ ! -f "$awsBinary" ]]; then    
            /usr/bin/curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o /tmp/AWSCLIV2.pkg
            /usr/sbin/installer -pkg /tmp/AWSCLIV2.pkg -target /
            /bin/rm /tmp/AWSCLIV2.pkg
        fi
        
        export awsInstallStatus=$?

        if [[ "$awsInstallStatus" -eq 0 ]]; then
            echo "Installing AWS shared credentials."
            /usr/local/bin/jamf policy -event aws_creds
            export awsCredsStatus=$?
        else
            echo "AWS CLI is not installed. Please try again."
            exit 1
        fi

        if [[ "$awsCredsStatus" -eq 0 ]]; then
            export AWS_PROFILE="$awsProfile"
            export AWS_CONFIG_FILE="$awsFolder"/config
            export AWS_SHARED_CREDENTIALS_FILE="$awsFolder"/credentials

            # Use the AWS CLI to copy the archive to the desginated bucket
            echo "The AWS binary is present, initiating the upload.."
            "$awsBinary" s3 cp "$aftermathArchiveDir" s3://"$s3Bucket" --recursive --exclude "*" --include "Aftermath*"
            
            export uploadStatus=$?
            
            # Report back the status of the upload
            if [[ "$uploadStatus" -eq 0 ]]; then
                echo "The upload to S3 was successful and finished with exit code ${uploadStatus}."
            else
                echo "The upload to S3 failed with error code ${uploadStatus}."
            fi
        else
            echo "AWS shared credentials are not present. Please try again."
            exit 1
        fi
    
    else

        echo "S3 information was not configured."
        export uploadStatus="1"
        
    fi
}

# Check for the required network connectivity to use the AWS S3 service
NetworkCheckAndUpload () {
    if /usr/bin/nc -zdw1 s3.amazonaws.com 443; then
        networkUP="yes"
        echo "Can the device connect to the S3 bucket for upload? Result: ${networkUP}"
        echo "Network connectivity is available so the upload will proceed."
    
        # Call CollectArchive function
        CollectArchive
    else
        networkUP="no"
        echo "Can the device connect to the S3 bucket for upload? Result: ${networkUP}"
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

    # Remove AWS CLI and .aws directory
    echo "Removing aws cli and .aws folder"
    /bin/rm /usr/local/bin/aws
    /bin/rm /usr/local/bin/aws_completer
    /bin/rm -rf /usr/local/aws-cli
    /bin/rm -rf /opt/.aws
    
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