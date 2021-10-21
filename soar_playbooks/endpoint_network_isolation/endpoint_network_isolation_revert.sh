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

# written by Matthieu Castel, Jamf May 2021
# edited by Matt Taylor, Jamf September 2021
# v1.5

# Restore network connectivity by disabling the packet filter restrictions

#####################################################
############# Script Configuration Area #############
#####################################################

# INCIDENT RESPONSE RESOURCES FOLDER
# Set the home directory for tools and resources for this Incident Response workflow
# IMPORTANT: Several other variables depend on this so please be sure to read the documentation
IRSupportDIR="/Library/Application Support/IRSupport"

# FILE NAMING CONVENTION
# The naming convention to use for any preference files created throughout this workflow.  This will be used for preference files so must be in domain naming format, such as 'com.acmesoft.isolate' and will often be followed by .plist, as an exmaple.
# IMPORTANT: This value must match the value used for the same variable in the enforce stage of this incident response workflow.
fileName="com.acmesoft.isolate"

# USER NOTIFICATION SETTINGS
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
subTitle="Place message here about the event"
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

# Unload the LaunchDaemon
/bin/launchctl unload -w /Library/LaunchDaemons/"$fileName".pf.plist

# Remove the LaunchDaemon
/bin/rm -f /Library/LaunchDaemons/"$fileName".pf.plist

# Remove the packet filter anchor configuration file
/bin/rm -f /etc/pf.anchors/"$fileName".pf.conf

# Remove the packet filter anchor rules file
/bin/rm -f /etc/pf.anchors/"$fileName".pf.rules

# Flush the packet filter rules, disable then re-enable the packet filter with default rules
/sbin/pfctl -F all
/sbin/pfctl -d
/sbin/pfctl -e -f /etc/pf.conf

echo "The packet filter rules have been flushed, restored to default values and the endpoint's connectivity returned to normal."

#####################################################
###### Notification Section ######
# Begin the process of notifying the user
if [[ "$notifyUser" == "yes" ]] && [[ -f "$notificationApp" ]]; then

    echo "User notification is enabled and the notification app is available to use.  The end-user will be notified of the event."
    
    # Capture the logged-in User
    loggedInUser=$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }')
    
    /usr/bin/sudo -u ${loggedInUser} "$notificationApp" -type "$window" -bar_title "$barTitle" -title "$title" -subtitle "$subTitle" -always_on_top -main_button_label "$mainButtonLabel" -tertiary_button_label "$tertiaryButtonLabel" -tertiary_button_cta_type "$tertiaryButtonType" -tertiary_button_cta_payload "$tertiaryButtonPayload" -help_button_cta_type "$helpButtonType" -help_button_cta_payload "$helpButtonPayload" -icon_path "$iconPath" &

elif [[ "$notifyUser" == "yes" ]] && [[ ! -f "$notificationApp" ]]; then

    echo "User notification is enabled but the notification app is not available for use so the user will not be notified."
    
elif [[ "$notifyUser" == "no" ]]; then

    echo "User notification is disabled so the user will not be notified."
    
fi
