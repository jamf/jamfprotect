#!/bin/zsh

set -e

/usr/bin/chflags nouchg /etc/security/audit_*

if [[ ! -e /etc/security/audit_control ]] && [[ -e /etc/security/audit_control.example ]];then
    /bin/cp /etc/security/audit_control.example /etc/security/audit_control
fi

# Add execution environment variables to log events 
/usr/bin/sed -i.backup 's|policy:cnt,argv$|policy:cnt,argv,arge|' /etc/security/audit_control 

# Enable and bootstrap auditd
/bin/launchctl enable system/com.apple.auditd
/bin/launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.auditd.plist

# Initialize auditd  
/usr/sbin/audit -i