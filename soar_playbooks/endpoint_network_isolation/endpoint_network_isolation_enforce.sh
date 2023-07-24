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
#  Endpoint Network Isolation - Enforce
#
# written by Matthieu Castel, Jamf May 2021
# edited by Matt Taylor, Jamf October 2021
# edited by Allen Golbig, Jamf July 2023
# v2.1
#
# This script is designed as a response workflow to isolate an endpoint based upon it's network connectivity, executed by Jamf Pro.  This might be automatically triggered by the Jamf Protect and Jamf Pro remediation integration or instead manually.
#
# Script functions
# - Obtain the Jamf Pro URL
# - Configure and enforce a set of rules with the Packet Filter (pf) binary to only permit inbound and outbound traffic (on any port) to the list of Apple addresses and the Jamf Pro URL
# - Create a LaunchDaemon to load the service at startup
# - Optionally notify the user with IBM Notifier
# - Optionally call upon additional Jamf Pro Policies by a custom trigger

# Known issues
# - Using the Jamf Pro fully qualified domain name as a rule causes the pfctl rules to fail to load at system startup, seemingly because the IP addresses can't be obtained at that time.  As such, the PF rules fail to enforce after a reboot unless another '/sbin/pfctl -e -f /etc/pf.anchors/"$filename".pf.conf' command is run to enforce them again

# Script Dependencies
# - A folder named 'IRSupport' at /Library/Application Support/ is used for assets when using the IBM Notifier.app for end-user communication
#
# The dependencies must be pre-staged to your devices in order for this workflow to complete fully.  Please the see github.com/jamf/jamfprotect Wiki for more information.

#####################################################
############# Script Configuration Area #############
#####################################################

# LOGGED IN USER
# Getting the current logged in user
loggedInUser=$(stat -f %Su /dev/console)

# PACKET FILTER FIREWALL SETTINGS
# This is the required IP range for persisting APNs connectivity on macOS devices.  Please refer to Apple's documentation for more information: https://support.apple.com/en-gb/HT210060.  Values in the variable must be separated by a comma and space.
apnsIPRange="17.0.0.0/8"

# FILE NAMING CONVENTION
# The naming convention to use for any preference files created throughout this workflow.  This will be used for preference files so must be in domain naming format, such as 'com.acmesoft.isolate' and will often be followed by .plist, as an exmaple.
fileName="com.acmesoft.isolate"

# INCIDENT RESPONSE RESOURCES FOLDER
# Incident Response directory containing resources for this workflow.  By default the files expected in this directory are:
# - IBM Notifier.app and icon file for end-user notifications (if enabled)
# IMPORTANT: This path and resources must be pre-staged prior to this workflow.  If missing, elements of the workflow that require it will not function.  Please refer to the Github Wiki for more information.
IRSupportDIR="/Library/Application Support/IRSupport"

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
subTitle="Substantial information about the event here."
mainButtonLabel="Acknowledge"
tertiaryButtonLabel="Learn More"
tertiaryButtonType="link"
tertiaryButtonPayload="additionalresourceURL"
helpButtonType="infopopup"
helpButtonPayload="This information is provided by the Acmesoft Information Security Team"
iconPath="${IRSupportDIR}/logo.png"

# ADDITIONAL JAMF PRO POLICY SETTINGS
# Additional artefact collection from a Jamf Pro Policy settings
# Set this to yes and provide a custom trigger to call a second Jamf Pro Policy for additional artefact collection following this event
# "yes" = the Jamf Pro binary will be used to check for additional Policies
# "no" = no action will be taken
moreJamfPro="no"
# IMPORTANT: If "yes" is chosen a custom trigger must be specified
customTrigger=""

#####################################################
############ DO NOT EDIT BELOW THIS LINE ############
#####################################################

################# Script Functions ##################

# Obtain the URL for the Jamf Pro tenant that the endpoint is managed by
GetJamfProURL () {
    
    # Get the Jamf Pro instance name from com.jamfsoftware.jamf.plist
    JamfProInstance=$(/usr/bin/defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url | sed -e 's/^\s*.*:\/\///g' -e 's/.$//')
    
}

# Create the Packet Filter anchor file and set permissions
CreatePFAnchor () {

    # Create the Anchor
/usr/bin/tee /etc/pf.anchors/"$fileName".pf.conf <<EOF
    anchor ${fileName}
    load anchor ${fileName} from "/etc/pf.anchors/${fileName}.pf.rules"
EOF

    # Set permissions
    /usr/sbin/chown root:wheel /etc/pf.anchors/"$fileName".pf.conf
    /bin/chmod 644 /etc/pf.anchors/"$fileName".pf.conf

}

# Create the Packet Filter rules file and set permissions
CreatePFRules () {

# Create the isolation PF fireWall policy
/usr/bin/tee /etc/pf.anchors/"$fileName".pf.rules <<EOF
            
            # Block all incoming connections
            block in all
            # Pass in incoming connections from Apple addresses and Jamf Pro
            pass in from { ${apnsIPRange}, ${JamfProInstance} } to any no state
            
            # Pass in DHCP
            pass in inet proto udp from port 67 to port 68
            pass in inet6 proto udp from port 547 to port 546
            
            # Block all outgoing connections
            block out from any to any no state
            
            # Pass out outgoing connections to Apple addresses and Jamf Pro
            pass out from any to { ${apnsIPRange}, ${JamfProInstance} } no state
EOF

    # Set permissions
    /usr/sbin/chown root:wheel /etc/pf.anchors/"$fileName".pf.rules
    /bin/chmod 644 /etc/pf.anchors/"$fileName".pf.rules

}

# Create the script which calls pfctl
CreateIsolateScript () {

/usr/bin/tee /usr/local/bin/isolate.sh <<EOF
#!/bin/sh

/bin/sleep 5
/usr/sbin/ipconfig waitall
/sbin/pfctl -E -f /etc/pf.anchors/${fileName}.pf.conf
EOF

    # Set permissions
    /usr/sbin/chown root:wheel /usr/local/bin/isolate.sh
    /bin/chmod 700 /usr/local/bin/isolate.sh

}

# Create the LaunchDaemon to execute the Packet Filter configuration at startup
CreatePFLaunchDaemon () {

/usr/bin/tee /Library/LaunchDaemons/"$fileName".pf.plist <<EOF
<!DOCTYPE plist PUBLIC "-//Apple Computer/DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>Label</key>
        <string>${fileName}.pf.plist</string>
        <key>Program</key>
        <string>/usr/local/bin/isolate.sh</string>
        <key>RunAtLoad</key>
        <true/>
        <key>LaunchOnlyOnce</key>
        <true/>
        <key>StandardErrorPath</key>
        <string>/var/log/pf.log</string>
        <key>StandardOutPath</key>
        <string>/var/log/pf.log</string>
    </dict>
</plist>
EOF

    # Set permissions
    /usr/sbin/chown root:wheel /Library/LaunchDaemons/"$fileName".pf.plist
    /bin/chmod 644 /Library/LaunchDaemons/"$fileName".pf.plist

}

StartPF () {

    # Disable the packet filter temporarily
    /sbin/pfctl -d

    # Load the LaunchDaemon, which will start the packet filter and enforce the packet filter rules
    /bin/launchctl load -w /Library/LaunchDaemons/"$fileName".pf.plist

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

#####################################################
############### Workflow Starts Here ################
#####################################################
set -o nounset

# Call function
GetJamfProURL

# Call function
CreatePFAnchor

# Call function
CreatePFRules

# Call function
CreateIsolateScript

# Call function
CreatePFLaunchDaemon

# Call function
StartPF

# Call function
UserNotification

# Call function
AdditionalJamfProPolicy

# Sleep 5 seconds and then run recon to update EA
/bin/sleep 5 

/usr/local/bin/jamf recon