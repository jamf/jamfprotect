#!/bin/bash

set -e

# Copy example file to production name 
cp /etc/security/audit_control.example /etc/security/audit_control 

# Add execution environment variables to log events 
/usr/bin/sed -i.backup 's|policy:cnt,argv$|policy:cnt,argv,arge|' /etc/security/audit_control 

# Enable the auditing background service, it will now auto-start with the system 
/bin/launchctl enable system/com.apple.auditd 
