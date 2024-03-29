#!/bin/bash
####################################################################################################
#
# Copyright (c) 2021, Jamf, LLC.  All rights reserved.
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
#  Quarantined File Acqusition and Removal
#  
#
#  Created by Matt Taylor on 20/09/2021.
#  v2.0
#  
# This script is designed as a response workflow executed by Jamf Pro after Jamf Protect completes a file quarantine event by the Threat Prevention feature.
#
# Script functions
# - Optionally display a notification to the end-user regarding the event using the Mac@IBM Notifications tool
# - Optionally perform an acquisition and upload of quarantined file(s) copied from the Jamf Protect quarantine directory, using AWS's S3 service
# - Optionally perform a local backup of the quarantined malware file(s) if network connectivity to the S3 bucket isn't available or if the upload fails for any reason
# - Optionally perform a deletion of quarantined file(s) from the Jamf Protect quarantine directory
# - Optionally call upon additional Jamf Pro Policies by a custom trigger
# - Clean up the Extension Attribute file created by Jamf Protect and submit a Jamf Pro inventory to reset the workflow

# Script Dependencies
# - A folder named 'IRSupport' at /Library/Application Support/ is used for assets when using the IBM Notifier.app for end-user communication
# - The AWS CLI is used for file uploads to Amazon's S3 service and can be downloaded here: https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-mac.html
#
# Both these dependencies must be pre-staged to your devices in order for this workflow to complete fully.  Please the see github.com/jamf/jamfprotect Wiki for more information.

#####################################################
############# Script Configuration Area #############
#####################################################

# Set the Extended Attribute value that the analytic in Jamf Protect will use to trigger the Jamf Pro integration and response workflow.  This is configured inside the analytic by enabling the 'Add to Jamf Pro Smart Group', is case sensitive and must match for this workflow to work
# Note that this workflow requires a custom analytic detection monitoring for new files created in the /Library/Application Support/JamfProtect/Quarantine directory in order to function
analyticEA="ThreatPreventionFileQuarantine"

# Incident Response directory containing resources for this workflow.  By default the files expected in this directory are:
# - IBM Notifier.app and icon file for end-user notifications (if enabled)
# IMPORTANT: This path and resources must be pre-staged prior to this workflow.  If missing, elements of the workflow that require it will not function.  Please refer to the Github Wiki for more information.
IRSupportDIR="/Library/Application Support/IRSupport"

# Artefact acquisition settings
# Enable or disable artefact acqusition in this script.  Expected options are:
# "yes" = artefacts will be uploaded to S3
# "no" = artefacts will not be uploaded to S3
artefactAcquisition="yes"
# Location of the AWS CLI binary, a default symlink path is used and may be retained.
awsBinary="/usr/local/bin/aws"
# The name of the target S3 bucket resource
s3Bucket=""
# The S3 Access Key ID to use for the upload
s3AccessKeyID=""
# The S3 Secret Key to use for the upload
s3SecretKey=""
# The region of the S3 bucket to use.  Example: us-east-1
s3BucketRegion=""

# Artefact backup settings
# Enable or disable backup of acquired artefacts should no network connectivity for the upload be available or if the upload is attempted but fails.  Expected options are:
# "yes" = artefacts will be backed up
# "no" = artefacts will not be backed up
# IMPORTANT: This is a valuable feature to ensure that quarantined files can be gathered.  Pair with an Extension Attribute in Jamf Pro to add an additional collection workflow for failed uploads after thef act.
artefactBackup="no"
backupDIR="${IRSupportDIR}/ArtefactBackups"

# Quarantined file settings
# Set whether to collect or remove just the most recently added file in the quarantine directory or all files
# "all" = collect or remove all files in the quarantine directory
# "latest" = collect or remove only the latest file in the quarantine directory
files="latest"
# Do you wish to delete the quarantined file?  Expected options are:
# "yes" = file deletion
# "no" = the file will not be deleted and will persist in the quarantine directory
deleteFile="yes"

# Additional artefact collection from a Jamf Pro Policy settings
# Set this to yes and provide a custom trigger to call a second Jamf Pro Policy for additional artefact collection following this event
# "yes" = the Jamf Pro binary will be used to check for additional Policies
# "no" = no action will be taken
moreJamfPro="no"
# IMPORTANT: If "yes" is chosen a custom trigger must be specified
customTrigger=""

# User notification settings
# This script will use the 'mac-ibm-notifications' tool to display an information window to the end-user about the event.  A signed and notarised version of this application can be downloaded from https://github.com/IBM/mac-ibm-notifications/releases and should be present on the device in order for it to be used.
# Set whether or not to notify the user of this event
# "yes" = the user will be notified
# "no" = the user will not be notified and all actions will be silent
notifyUser="no"
notificationApp="${IRSupportDIR}/IBM Notifier.app/Contents/MacOS/IBM Notifier"

# IBM Notifier app settings.  This can be configured as desired per the workflow and end-user communication required.
window="popup"
barTitle="Acmesoft Information Security Notification"
title="This is an important message from the Acmesoft Information Security Team"
subTitle="Substantial information about the event here."
mainButtonLabel="Acknowledge"
tertiaryButtonLabel="Learn More"
tertiaryButtonType="link"
tertiaryButtonPayload="additionalresourceURL"
helpButtonType="infopopup"
helpButtonPayload="This information is provided by the Acmesoft Information Security Team"
iconPath="${IRSupportDIR}/logo.png"

#####################################################
############ DO NOT EDIT BELOW THIS LINE ############
#####################################################

################# Script Functions ##################

# Check for quarantined files to confirm if the script should continue
CheckForFiles () {
    if [[ -z $(/bin/ls -A "$quarantineDIR") ]]; then
        
        echo "There are no files in the Jamf Protect quarantine directory so this incident response workflow will now abort."
        
        exit 1
        
    else
    
        echo "There are files present in the Jamf Protect quarantine directory so this incident response workflow will now start."
        
    fi
}

# End-user notification of the event
UserNotification () {
    if [[ "$notifyUser" == "yes" ]] && [[ -f "$notificationApp" ]]; then

        echo "User notification is enabled and the notification app is available to use.  The end-user will now be notified of the event."
    
        /usr/bin/sudo -u "$loggedInUser" "$notificationApp" -type "$window" -bar_title "$barTitle" -title "$title" -subtitle "$subTitle" -always_on_top -main_button_label "$mainButtonLabel" -tertiary_button_label "$tertiaryButtonLabel" -tertiary_button_cta_type "$tertiaryButtonType" -tertiary_button_cta_payload "$tertiaryButtonPayload" -help_button_cta_type "$helpButtonType" -help_button_cta_payload "$helpButtonPayload" -icon_path "$iconPath" &

    elif [[ "$notifyUser" == "yes" ]] && [[ ! -f "$notificationApp" ]]; then

        echo "User notification is enabled but the notification app is not available for use so the user will not be notified and the operation aborted."
    
    elif [[ "$notifyUser" != "yes" ]]; then

        echo "User notification is disabled or misconfigured so the user will not be notified."
        echo "User notification configuration was: ${notifyUser}"
    
    fi
}

# Check for and create the IRSupport directory if necessary
CheckIRSupportDIR () {
    echo "Checking that the ${IRSupportDIR} directory exists.."
    
    if [[ ! -d "$IRSupportDIR" ]]; then
    
        echo "The ${IRSupportDIR} directory doesn't exist so it will be created."
        /bin/mkdir -p "$IRSupportDIR"
    
    fi
}

# Create the working directory
CreateWorkingDIR () {
    echo "Creating the temporary working directory.."
    
    workingDIR="/private/tmp/JPIR"
    
    /bin/mkdir -p "$workingDIR"
}

# Create the event information log
CreateEventLog () {
    # Event information file
    eventLog="${workingDIR}/Event.log"
    
    # Create the file
    /usr/bin/touch "$eventLog"
    
    # Capture the serial number of the endpoint
    serialNumber=$(/usr/sbin/system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')
    
    # Create a file of basic information regarding the event
    echo "Endpoint and Event Information:
Hostname: $(hostname)
Serial Number: ${serialNumber}
Jamf Protect Event: ${analyticEA}
Date of Collection: $(date)" >> "$eventLog"
}

# Perform collection of the quarantined files
FileCollection () {
    # Perform a collection of the quarantined files based upon the configuration of this script
    if [[ "$files" == "latest" ]]; then
    
        echo "Only the latest quarantined file will be collected.."
        
        # Find the most recently added file that was quarantined by Jamf Protect
        quarantinedFiles=$(/bin/ls -lrtA "$quarantineDIR" | /usr/bin/tail -n 1 | /usr/bin/awk '{ print$NF }')

        # Copy the folder to the working directory
        /bin/cp -R "$quarantineDIR"/"$quarantinedFiles" "$workingDIR"
        
    elif [[ "$files" == "all" ]]; then
        
        echo "All files in the quarantine directory will be collected.."
        
        # Copy the entire contents of the quarantine directory to the working directory
        /bin/cp -R "$quarantineDIR"/* "$workingDIR"
        
    else
    
        echo "An unknown option was chosen for the 'files' variable in this acquisition operation so the default of 'latest' will be used."
        
        echo "Only the latest quarantined file will be collected.."
        
        # Find the most recently added file that was quarantined by Jamf Protect
        quarantinedFiles=$(/bin/ls -lrtA "$quarantineDIR" | /usr/bin/tail -n 1 | /usr/bin/awk '{ print$NF }')

        # Copy the folder to the working directory
        /bin/cp -R "$quarantineDIR"/"$quarantinedFiles" "$workingDIR"

    fi
}

# Compress the artefacts for upload
CompressArtefacts () {
    # Process the upload of the artefacts to the nominated S3 bucket
    file="$(date +%Y%m%d_%H%M)-${serialNumber}-JPIR-Artefacts.tar.gz"
    
    # Move into the working directory and compress the quarantined file(s) for upload
    cd "$workingDIR" && /usr/bin/tar czf "$file" *

    # Move out of the working directory
    cd /Users/Shared
}

# Upload the artefacts to the Amazon S3 service using the AWS CLI
AcquireArtefacts () {
    if [[ ! -z "$s3Bucket" ]] && [[ ! -z "$s3AccessKeyID" ]] && [[ ! -z "$s3SecretKey" ]] && [[ ! -z "$s3BucketRegion" ]]; then
    
        echo "Artefact acquisition is enabled and the required variables are not empty so the upload operation will begin now.."
    
        # Set variables required for the AWS S3 service upload
        export AWS_ACCESS_KEY_ID="$s3AccessKeyID"
        export AWS_SECRET_ACCESS_KEY="$s3SecretKey"
        export AWS_DEFAULT_REGION="$s3BucketRegion"
    
        # Check for the AWS binary being installed and Upload the file to the S3 bucket if so
        if [[ -f "$awsBinary" ]]; then
            
            echo "The AWS binary is present, initiating the upload.."
            "$awsBinary" s3 cp "$workingDIR"/"$file" s3://"$s3Bucket"
            
            export uploadStatus=$?
            
            # Report back the status of the upload.  If 0 then the upload was successful, if any code other than 0 than it was a failure
            if [[ "$uploadStatus" -eq 0 ]]; then
                
                echo "The artefact upload to the S3 service was successful and finished with exit code ${uploadStatus}."
                
            else
            
                echo "The artefact upload to the S3 service failed with error code ${uploadStatus}."
                
            fi
            
        else
        
            echo "Artefact acquisition was enabled and configured but the AWS binary wasn't available to use so the operation was aborted."
            # Record a failure for artefact backup operation
            export uploadStatus="1"
            
        fi
    
    else
        
        # Artefact acquisition was enabled but was misconfigured
        echo "Artefact acquisition was enabled but misconfigured so the operation was aborted."
        echo "Artefact acquisition configuration: ${artefactAcquisition}"
        # Record a failure for artefact backup operation
        export uploadStatus="1"
        
    fi
}

# Check for the required network connectivity to use the AWS S3 service
NetworkCheckAndUpload () {
    if /usr/bin/nc -zdw1 s3.amazonaws.com 443; then
        
        networkUP="yes"
        echo "Can the device connect to the S3 bucket for upload? Result: ${networkUP}"
        echo "Network connectivity is available so the artefect upload will proceed.."
    
        # Call function
        AcquireArtefacts
    
    else
        
        networkUP="no"
        echo "Can the device connect to the S3 bucket for upload? Result: ${networkUP}"
        
    fi
}

# Backup the artefacts if confiugred to do so
ArtefactBackup () {
    echo "Backing up of acquired artefacts is enabled and the operation will now proceed."
    
    # Check for and make the backup directory if it doesn't already exist
    if [[ ! -d "$backupDIR" ]]; then
    
        echo "The artefact backup directory doesn't exist so it will now be created."
        /bin/mkdir -p "$backupDIR"
        
    fi
        
    # Copy the file to the backup directory
    echo "The artefacts file will be coped to the backup directory"
    /bin/cp "$workingDIR"/"$file" "$backupDIR"
        
    # Remove permissions for users to access this file
    if [[ -f "$backupDIR"/"$file" ]]; then
    
        /bin/chmod 000 "$backupDIR"/"$file"
        echo "The artefacts file was successfully copied to the backup directory and permissions set to restrict access."
    
    else
    
        echo "The artefacts file was not successfully copied to the backup directory and may be lost from the temporary working directory at next system restart."
        
    fi
}

# Perform a backup of artefacts if the conditions to do so are met
BackupOperation () {
    if [[ "$uploadStatus" != 0 ]] && [[ "$artefactBackup" == "yes" ]]; then
    
        echo "Network connectivity is available but the artefact upload to the S3 service failed.  Artefact backup is enabled so this operation will now begin."
        # Call function
        ArtefactBackup
        
    elif [[ "$uploadStatus" != 0 ]] && [[ "$artefactBackup" == "no" ]]; then
    
        echo "Network connectivity is available but the artefact upload to the S3 service failed.  Artefact backup is disabled so this operation will be skipped."

    elif [[ "$networkUP" == "no" ]] && [[ "$artefactBackup" == "yes" ]]; then
    
        echo "Network connectivity is unavailable and artefact backup is enabled so the backup operation will now begin.."
        # Call function
        ArtefactBackup
        
    elif [[ "$networkUP" == "no" ]] && [[ "$artefactBackup" == "no" ]]; then
    
        echo "Network connectivity is unavailable and artefact backup is disabled."

    fi
}

# Complete removal of the quarantined files if configured to do so
FileDeletion () {
    # Delete the quarantined file(s) if configured to do so
    if [[ "$deleteFile" == "yes" ]]; then

        echo "Deletion of quarantined files is enabled and will now begin."
    
        if [[ "$files" == "latest" ]]; then
        
            echo "Deleting the most recently quarantined file.."
            /bin/rm -rf "${quarantineDIR:?}"/"${quarantinedFiles:?}"
        
        elif [[ "$files" == "all" ]]; then
    
            echo "Deleting all files in the quarantine directory.."
            # Validate the variables then safely delete all files within the quarantine directory
            /bin/rm -rf "${quarantineDIR:?}"/*
            
        else
        
            echo "File deletion is enabled but no valid option was chosen for the 'files' variable so the operation was aborted."
        
        fi
    
    else

        echo "Deletion of quarantined files is not enabled so this operation was skipped."
    
    fi
}


# Call any additional Jamf Pro Policies desired
AdditionalJamfProPolicy () {
    # Trigger any additional Policies from Jamf Pro as configured
    if [[ "$moreJamfPro" == "yes" ]] && [[ "$customTrigger" != "" ]]; then
    
        echo "Calling additional Jamf Pro Policy workflows as configured to do so."
        /usr/local/bin/jamf policy -event "$customTrigger" &

    elif [[ "$moreJamfPro" == "yes" ]] && [[ "$customTrigger" == "" ]]; then

        echo "Additional Jamf Po Policy workflows were configured to be called but no custom trigger was specified in the configuration section of this script so the operation was aborted."
    
    elif [[ "$moreJamfPro" != "yes" ]]; then
    
        echo "Additional Jamf Pro Policy triggering was not enabled or was misconfigured."
        echo "Configuration for additional Jamf Pro workflows was: ${moreJamfPro}"
    
    fi
}

# Clean up and end this workflow
CleanUp () {
    # Make sure the working directory variable isn't rempty before removing it
    if [[ ! -z "$workingDIR" ]]; then
        
        echo "Removing the temporary working directory.."
        /bin/rm -rf "$workingDIR"
    
    else
    
        echo "Attempted to remove the temporary working directory but the action was aborted as no path was provided."
    
    fi
    
    # Clean up the Jamf Protect and Jamf Pro remediation workflow files and submit a new inventory report to cause the device to fall out of the incident response workflow Smart Group
    if [[ ! -z "$analyticEA" ]]; then

        echo "Cleaning up the extension attribute file created by Jamf Protect to reset this workflow"
    
        # Delete the extension attribute file created by Jamf Protect
        /bin/rm "/Library/Application Support/JamfProtect/groups/${analyticEA}"

    else
        
        echo "Attempted to clean up the extension attribute file created by Jamf Protect to reset this workflow but no file path was provided."
    
    fi

    # Submit a new Jamf Pro inventory submission to cause the device to leave the incident response workflow Smart Group
    /usr/local/bin/jamf recon &
}

#####################################################
############### Workflow Starts Here ################
#####################################################
set -o nounset

# Set the file quarantine directory from Jamf Protect
quarantineDIR="/Library/Application Support/JamfProtect/Quarantine"

# Capture the logged-in User
loggedInUser=$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }')

# Call function
CheckForFiles

#####################################################
###### End-user Notification Section ######

# Call function
UserNotification

#####################################################
###### Acquisition, Upload and Backup Section #######

# Begin acquisition of the malware sample if this function is enabled
if [[ "$artefactAcquisition" == "yes" ]]; then

    echo "Artefact collection is enabled and will now begin.."
    
    # Call function
    CheckIRSupportDIR
    
    # Call function
    CreateWorkingDIR
    
    # Call function
    FileCollection
 
    # Call function
    CreateEventLog
    
    # Call function
    CompressArtefacts
    
    # Call function
    NetworkCheckAndUpload

    # Call function
    BackupOperation

else

    echo "Artefact acquisition was not enabled and therefore the operation was skipped."

fi

#####################################################
############### File Removal Section ################

# Call function
FileDeletion

#####################################################
#### Additional Jamf Pro Policy Workflow Section ####

# Call function
AdditionalJamfProPolicy

#####################################################
########## Cleanup and Resolution Section ###########

# Call function
CleanUp
