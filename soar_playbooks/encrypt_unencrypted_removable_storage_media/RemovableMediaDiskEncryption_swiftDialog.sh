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

# Created by Thijs Xhaflaire, Jamf on 01/10/2022

## Jamf Protect Analytic smartgroup identifier
jamfProtectGroups="USBInserted"

## USER NOTIFICATION SETTINGS
## This script will use the 'swiftDialog' tool to display an information window to the end-user about the event.  A signed and notarised version of this application can be downloaded from https://github.com/bartreardon/swiftDialog/releases and should be present on the device in order for it to be used.
## Set whether which notifications you want to generate to the end user.
## "yes" = the user will be notified
## "no" = the user will not be notified and actions will be skipped
notifyUser="yes"
notifyUserHint="yes"

## General swiftDialog Settings
notificationApp="/usr/local/bin/dialog"
iconPath="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FileVaultIcon.icns"

## swiftDialog customisations -  APFS Password popup
titlePassword="Unencrypted Removable Media Device detected"
subTitlePassword="Within Acmesoft we do allow read-only activities to unencrypted devices, to write to external media please encrypt the disk, Securely store the password and in case of loss the data will be unaccesible!"
mainButtonLabelPassword="Continue"
secondaryButtonLabelPassword="Mount as read-only"
secondTitlePassword="Enter the password you want to use to encrypt the removable media"
placeholderPassword="Enter password here"
passwordRegex="^[a-zA-Z.0-9]{8,}\d{2}$" #specify a regex that the passwords needs to match to
passwordRegexErrorMessage="Password must contain at least 8 characters, including 2 alphanumeric"

## swiftDialog customisations -  HFS Conversion popup
titleConversion="Unencrypted Removable Media Device detected"
subTitleConversion="Within Acmesoft we do allow read-only activities to unencrypted devices, to write to external media please encrypt the disk, we need to convert this volume to APFS before encryption. Securely store the password and in case of loss the data will be unaccesible!"
mainButtonLabelConversion="Convert"
secondaryButtonLabelConversion="Mount as read-only"
secondTitleConversion="Enter the password you want to use to encrypt the removable media"
placeholderConversion="Enter password here"
passwordRegex="^[a-zA-Z.0-9]{8,}\d{2}$" #specify a regex that the passwords needs to match to
passwordRegexErrorMessage="Password must contain at least 8 characters, including 2 alphanumeric"

## swiftDialog customisations -  EXFAT/FAT erase and popup
titleEXFAT="Unencrypted Removable Media Device detected"
subTitleEXFAT="Within Acmesoft we do allow read-only activities to unencrypted devices, to write to external media please encrypt the disk. As this volume type does not support conversion or encryption we need to erase the volume. all existing content will be erased!!!. / Securely store the password and in case of loss the data will be unaccesible!"
mainButtonLabelEXFAT="Erase existing data and encrypt"
secondaryButtonLabelEXFAT="Mount as read-only"
secondTitleEXFAT="Enter the password you want to use to encrypt the removable media"
placeholderEXFAT="Enter password here"
passwordRegex="^[a-zA-Z.0-9]{8,}\d{2}$" #specify a regex that the passwords needs to match to
passwordRegexErrorMessage="Password must contain at least 8 characters, including 2 alphanumeric"

## swiftDialog customisations - Hint popup
titleHint="Unencrypted Removable Media Device detected"
subTitleHint="Optionally you can specify a hint, a password hint is a sort of reminder that helps the user remember their password."
mainButtonLabelHint="Encrypt"
secondaryButtonLabelHint="Encrypt w/o hint"
secondTitleHint="Enter the hint you want to set"
placeholderHint="Enter hint here"
hintRegex="^[a-zA-Z0-9]{6,}$" #specify a regex that the hint needs to match to
hintRegexErrorMessage="Hint must contain a minimum of 6 characters"

## swiftDialog customisations - Progressbar
titleProgress="Disk Encryption Progress"
subTitleProgress="Please wait while the external disk is being encrypted."
mainButtonLabelProgress="Exit"


###########################################
############ Do not edit below ############
###########################################

## Script variables
loggedInUser=$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
ExternalDisks=$(diskutil list external physical | grep "/dev/disk" | awk '{print $1}')

	## Check if the mounted External Disk is external, physical and continue
	if [[ -z $ExternalDisks ]]; then
		echo "no external disks mounted"
		exit 0
	else
		## Echo external disk mounted
		echo "external disk mounted"

		## Loop through Storage Volume Types
		StorageType=$(diskutil list $ExternalDisks)

		if [[ $StorageType =~ "Apple_APFS" ]]; then
			echo "The external media volume type is APFS"
			StorageType='APFS'
			
			## Check the DiskID of the APFS container and report the encryption state
			DiskID=$(diskutil list $ExternalDisks | grep -o '\(Container disk[0-9s]*\)' | awk '{print $2}')
			echo "Disk ID is $DiskID"
			FileVaultStatus=$(diskutil apfs list $DiskID | grep "FileVault:" | awk '{print $2}')
			
			## If the APFS Container is not encrypted, run workflow
			if [ $StorageType == "APFS" ] && [ $FileVaultStatus == "Yes" ]; then
				echo "FileVault is enabled on $DiskID, exiting.."
				exit 0
			else
				echo "FileVault is disabled on $DiskID, running encryption workflow"
					
				# Mounting disk as read-only
				diskutil unmountDisk "$DiskID"s1
				diskutil mount readonly "$DiskID"s1
				
				## Generate notification and ask for password for encryption or mount volume as read-only
				if [[ "$notifyUser" == "yes" ]] && [[ -f "$notificationApp" ]] && [[ "$FileVaultStatus" == "No" ]]; then
					Password=$(/usr/bin/sudo -u "$loggedInUser" "$notificationApp" --title "$titlePassword" --message "$subTitlePassword" --button1text "$mainButtonLabelPassword" --button2text "$secondaryButtonLabelPassword" --icon "$iconPath" --textfield "$secondTitlePassword",prompt="$placeholderPassword",regex="$passwordRegex",regexerror="$passwordRegexErrorMessage",secure=true,required=yes | grep "$secondTitlePassword" | awk -F " : " '{print $NF}' &)
				fi
				
				if [ "$Password" == ""  ]; then
					echo "$loggedInUser cancelled encryption of the disk, mounting $DiskID as read-only"
					diskutil unmountDisk "$DiskID"s1
					diskutil mount readonly "$DiskID"s1
					                
					echo "Cleaning up Jamf Protect Groups folder"
					rm -f /Library/Application\ Support/JamfProtect/groups/"$jamfProtectGroups"
					exit 0
				fi

				## Generate notification and ask if we want to specify a hint
				if [[ "$notifyUserHint" == "yes" ]] && [[ -f "$notificationApp" ]] && [[ "$FileVaultStatus" == "No" ]]; then				
					Passphrase=$(/usr/bin/sudo -u "$loggedInUser" "$notificationApp" --title "$titleHint" --message "$subTitleHint" --button1text "$mainButtonLabelHint" --button2text "$secondaryButtonLabelHint" --icon "$iconPath" --textfield "$secondTitleHint",prompt="$placeholderHint",regex="$hintRegex",regexerror="$hintRegexErrorMessage" | grep "$secondTitleHint" | awk -F " : " '{print $NF}' &)
				fi
				
				## Start the encryption of the disk with the provided password, optionally we are configuring a hint as well.
					if [[ "$notifyUser" == "yes" ]] && [[ -f "$notificationApp" ]] && [[ "$Password" != "" ]]; then
							
							/usr/bin/sudo -u "$loggedInUser" "$notificationApp" --title "$titleProgress" --message "$subTitleProgress" --icon "$iconPath"  --button1text "$mainButtonLabelProgress" --timer 12 &

							diskutil unmountDisk "$DiskID"s1
							diskutil mount "$DiskID"s1						
							diskutil apfs encryptVolume "$DiskID"s1 -user "disk" -passphrase "$Password"
							
                            ## If the optional hint has been configured we are going to configure it here after encrypting the disk
							if [ "$Passphrase" != "" ]; then
								sleep 5
								diskutil unmountDisk $DiskID
								diskutil apfs unlockVolume "$DiskID"s1 -passphrase "$Password"
								diskutil apfs setPassphraseHint "$DiskID"s1 -user "disk" -hint "$Passphrase"
							fi
							
                            ## Clean up the Jamf Protect folder to clear the Extension Attribute
							echo "Cleaning up Jamf Protect Groups folder"
							rm -f /Library/Application\ Support/JamfProtect/groups/"$jamfProtectGroups"
							exit 0
							
						fi
			fi
		elif [[ $StorageType =~ "Apple_HFS" ]]; then
			echo "The external media type is $StorageType"
			StorageType="HFS"
			
			# Check Encryption State
			#DiskID=$(diskutil list $ExternalDisks| grep "Apple_HFS" | awk '{print $6}')
            DiskID="$ExternalDisks"
			echo "Disk ID is $DiskID"
			FileVaultStatus=$(diskutil list $DiskID | grep "FileVault:" | awk '{print $2}')

            ## In case of HFS container, we need to convert it to APFS and have it encrypted
			if [ $StorageType == "HFS" ]; then

				# Mounting disk as read-only
				diskutil unmountDisk "$DiskID"
				diskutil mount readonly "$DiskID"s2

				## Generate notification and ask for password for encryption or mount volume as read-only
				if [[ "$notifyUser" == "yes" ]] && [[ -f "$notificationApp" ]]; then
					Password=$(/usr/bin/sudo -u "$loggedInUser" "$notificationApp" --title "$titleConversion" --message "$subTitleConversion" --button1text "$mainButtonLabelConversion" --button2text "$secondaryButtonLabelConversion" --icon "$iconPath" --textfield "$secondTitleConversion",prompt="$placeholderConversion",regex="$passwordRegex",regexerror="$passwordRegexErrorMessage",secure=true,required=yes | grep "$secondTitleConversion" | awk -F " : " '{print $NF}' &)
				fi
				
				if [ "$Password" == ""  ]; then
					echo "$loggedInUser cancelled conversion and encryption of the disk, mounting $DiskID as read-only"
					diskutil unmountDisk "$DiskID"
					diskutil mount readonly "$DiskID"s2
					
					echo "Cleaning up Jamf Protect Groups folder"
					rm -f /Library/Application\ Support/JamfProtect/groups/$jamfProtectGroups
					exit 0
				fi

				## Generate notification and ask if we want to specify a hint
				if [[ "$notifyUserHint" == "yes" ]] && [[ -f "$notificationApp" ]]; then				
					Passphrase=$(/usr/bin/sudo -u "$loggedInUser" "$notificationApp" --title "$titleHint" --message "$subTitleHint" --button1text "$mainButtonLabelHint" --button2text "$secondaryButtonLabelHint" --icon "$iconPath" --textfield "$secondTitleHint",prompt="$placeholderHint",regex="$hintRegex",regexerror="$hintRegexErrorMessage" | grep "$secondTitleHint" | awk -F " : " '{print $NF}' &)
				fi
				
				## Start the encryption of the disk with the provided password, optionally we are configuring a hint as well.
					if [[ "$notifyUser" == "yes" ]] && [[ -f "$notificationApp" ]] && [[ "$Password" != "" ]]; then
                                                      
							/usr/bin/sudo -u "$loggedInUser" "$notificationApp" --title "$titleProgress" --message "$subTitleProgress" --icon "$iconPath"  --button1text $mainButtonLabelProgress --timer 12 &

							diskutil unmountDisk "$DiskID"s2
							diskutil mount "$DiskID"s2
                            diskutil apfs convert "$DiskID"s2

                            DiskID=$(diskutil list $ExternalDisks | grep -o '\(Container disk[0-9s]*\)' | awk '{print $2}')							
                            diskutil apfs encryptVolume "$DiskID"s1 -user "disk" -passphrase "$Password"
							
                            ## If the optional hint has been configured we are going to configure it here after encrypting the disk
							if [ "$Passphrase" != "" ]; then
								sleep 5
								diskutil unmountDisk $DiskID
								diskutil apfs unlockVolume "$DiskID"s1 -passphrase "$Password"
								diskutil apfs setPassphraseHint "$DiskID"s1 -user "disk" -hint "$Passphrase"
							fi
							
                            ## Clean up the Jamf Protect folder to clear the Extension Attribute
							echo "Cleaning up Jamf Protect Groups folder"
							rm -f /Library/Application\ Support/JamfProtect/groups/"$jamfProtectGroups"
							exit 0
			    fi
            fi
		elif [[ $StorageType =~ "Microsoft Basic Data" ]]; then
			echo "The external media type is Microsoft Basic Data"
			StorageType="Microsoft Basic Data"
			
			# Check Encryption State
            DiskID="$ExternalDisks"
			echo "Disk ID is $DiskID"
			volumeName=$(diskutil info "$DiskID"s2 | grep "Volume Name" | awk '{print $3}')

            ## In case of EXFAT volume, we need to erase it, reformat to APFS and encrypt it
			if [[ $StorageType == "Microsoft Basic Data" ]]; then

				# Mounting disk as read-only
				diskutil unmountDisk "$DiskID"
				diskutil mount readonly "$DiskID"s2

				## Generate notification and ask for password for encryption or mount volume as read-only
				if [[ "$notifyUser" == "yes" ]] && [[ -f "$notificationApp" ]]; then
					Password=$(/usr/bin/sudo -u "$loggedInUser" "$notificationApp" --title "$titleEXFAT" --message "$subTitleEXFAT" --button1text "$mainButtonLabelEXFAT" --button2text "$secondaryButtonLabelEXFAT" --icon "$iconPath" --textfield "$secondTitleEXFAT",prompt="$placeholderEXFAT",regex="$passwordRegex",regexerror="$passwordRegexErrorMessage",secure=true,required=yes | grep "$secondTitleEXFAT" | awk -F " : " '{print $NF}' &)
				fi
				
				if [ "$Password" == ""  ]; then
					echo "$loggedInUser cancelled conversion and encryption of the disk, mounting $DiskID as read-only"
					diskutil unmountDisk "$DiskID"
					diskutil mount readonly "$DiskID"s2
					
					echo "Cleaning up Jamf Protect Groups folder"
					rm -f /Library/Application\ Support/JamfProtect/groups/$jamfProtectGroups
					exit 0
				fi

				## Generate notification and ask if we want to specify a hint
				if [[ "$notifyUserHint" == "yes" ]] && [[ -f "$notificationApp" ]]; then				
					Passphrase=$(/usr/bin/sudo -u "$loggedInUser" "$notificationApp" --title "$titleHint" --message "$subTitleHint" --button1text "$mainButtonLabelHint" --button2text "$secondaryButtonLabelHint" --icon "$iconPath" --textfield "$secondTitleHint",prompt="$placeholderHint",regex="$hintRegex",regexerror="$hintRegexErrorMessage" | grep "$secondTitleHint" | awk -F " : " '{print $NF}' &)
				fi
				
            
				## Start the erase and encryption of the disk with the provided password, optionally we are configuring a hint as well.
					if [[ "$notifyUser" == "yes" ]] && [[ -f "$notificationApp" ]] && [[ "$Password" != "" ]]; then
                                                      
							/usr/bin/sudo -u "$loggedInUser" "$notificationApp" --title "$titleProgress" --message "$subTitleProgress" --icon "$iconPath"  --button1text $mainButtonLabelProgress --timer 12 &							
                            diskutil eraseDisk APFS $volumeName "$DiskID" 

                            DiskID=$(diskutil list $ExternalDisks | grep -o '\(Container disk[0-9s]*\)' | awk '{print $2}')							
                        	diskutil apfs encryptVolume "$DiskID"s1 -user "disk" -passphrase "$Password"
							
                            ## If the optional hint has been configured we are going to configure it here after encrypting the disk
							if [ "$Passphrase" != "" ]; then
								sleep 5
								diskutil unmountDisk $DiskID
								diskutil apfs unlockVolume "$DiskID"s1 -passphrase "$Password"
								diskutil apfs setPassphraseHint "$DiskID"s1 -user "disk" -hint "$Passphrase"
							fi
							
                            ## Clean up the Jamf Protect folder to clear the Extension Attribute
							echo "Cleaning up Jamf Protect Groups folder"
							rm -f /Library/Application\ Support/JamfProtect/groups/"$jamfProtectGroups"
							exit 0
			    fi
            fi
		fi
	fi