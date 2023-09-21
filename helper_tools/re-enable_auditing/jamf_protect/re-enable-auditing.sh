#!/bin/zsh

set -e

if [[ -e /etc/security/audit_control ]];then
    # Enable and bootstrap auditd
    /bin/launchctl enable system/com.apple.auditd
    /bin/launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.auditd.plist

    # Initialize auditd  
    /usr/sbin/audit -i
fi