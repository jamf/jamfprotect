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

# USAGE
# Execute as a Remediation Script from Jamf Pro.

#####################################################
############# Script Configuration Area #############
#####################################################

########## Packet Filter Firewall Settings ##########
# These are the required ports and IP range for persisting APNs connectivity on macOS devices.  Please refer to Apple's documentation for more information: https://support.apple.com/en-gb/HT210060.  Values in the variable must be separated by a comma and space.
apnsPorts="53, 8443, 443, 80, 5223, 2195, 2196, 2197"
apnsIPRange="17.0.0.0/8"

# The naming convention to use for any preference files created throughout this workflow.  This will be used for preference files so must be in domain naming format, such as 'com.acmesoft.isolate' and will often be followed by .plist, as an exmaple.
fileName="com.acmesoft.isolate"

# Set the home directory for tools and resources for this Incident Response workflow
# IMPORTANT: Several other variables depend on this so please be sure to read the documentation
IRSupportDIR="/path/to/resources/folder"

########## User Notification Settings ##########
# This script will use the 'mac-ibm-notifications' tool to display an information window to the end-user about the event.  A signed and notarised version of this application can be downloaded from https://github.com/IBM/mac-ibm-notifications/releases and should be present on the device in order for it to be used.
# Set whether or not to notify the user of this event
# "yes" = the user will be notified
# "no" = the user will not be notified and all actions will be silent
notifyUser="yes"

# The file path to the application:
notificationApp="${IRSupportDIR}/IBM Notifier.app/Contents/MacOS/IBM Notifier"

# IBM Notifier Variables
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

# Disable Firewall if needed
#/usr/bin/defaults write /Library/Preferences/com.apple.alf globalstate -int 0

# Get instance name from com.jamfsoftware.jamf.plist
JamfProInstance=$(/usr/bin/defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url | sed -e 's/^\s*.*:\/\///g' -e 's/.$//')

# Create the KeepJamf Anchor
/usr/bin/tee /etc/pf.anchors/"$fileName".pf.conf <<EOF
	anchor ${fileName}
	load anchor ${fileName} from "/etc/pf.anchors/${fileName}.pf.rules"
EOF

# Set permissions
/usr/sbin/chown root:wheel /etc/pf.anchors/"$fileName".pf.conf
/bin/chmod 755 /etc/pf.anchors/"$fileName".pf.conf

# Create the isolation PF fireWall policy
/usr/bin/tee /etc/pf.anchors/"$fileName".pf.rules <<EOF
			
			# Safe List
            # Block all incoming connections
            block in all
            # Pass in incoming connections from Apple addresses and Jamf Pro
            pass in from { ${apnsIPRange}, ${JamfProInstance} } to any no state
            
            ## Pass in DHCP
            pass in inet proto udp from port 67 to port 68
            pass in inet6 proto udp from port 547 to port 546
            
            # Block all outgoing connections
            block out from any to any no state
            
            # Pass out outgoing connections to Apple addresses and Jamf Pro
            pass out from any to { ${apnsIPRange}, ${JamfProInstance} } no state
EOF

# Set permissions
/usr/sbin/chown root:wheel /etc/pf.anchors/"$fileName".pf.rules
/bin/chmod 755 /etc/pf.anchors/"$fileName".pf.rules

/usr/bin/tee /Library/LaunchDaemons/"$fileName".pf.plist <<EOF
<!DOCTYPE plist PUBLIC "-//Apple Computer/DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
	<dict>
		<key>Label</key>
			<string>${fileName}.pf.plist</string>
		<key>Program</key>
			<string>/sbin/pfctl</string>
		<key>ProgramArguments</key>
		<array>
			<string>/sbin/pfctl</string>
			<string>-e</string>
			<string>-f</string>
			<string>/etc/pf.anchors/${fileName}.pf.conf</string>
		</array>
		<key>RunAtLoad</key>
			<true/>
		<key>ServiceDescription</key>
			<string>FreeBSD Packet Filter (pf) daemon</string>
		<key>StandardErrorPath</key>
			<string>/var/log/pf.log</string>
		<key>StandardOutPath</key>
			<string>/var/log/pf.log</string>
	</dict>
</plist>
EOF

# Set permissions
/usr/sbin/chown root:wheel /Library/LaunchDaemons/"$fileName".pf.plist
/bin/chmod 755 /Library/LaunchDaemons/"$fileName".pf.plist

# Enable firewall
#/usr/bin/defaults write /Library/Preferences/com.apple.alf globalstate -int 1

# Disable the packet filter temporarily
/sbin/pfctl -d

# Load the LaunchDaemon, which will start the packet filter and enforce the packet filter rules
/bin/launchctl load -w /Library/LaunchDaemons/"$fileName".pf.plist

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
