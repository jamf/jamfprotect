# SOAR Playbook - Endpoint Network Isolation

This SOAR playbook is built to isolate an endpoint and prevent it from communicating to other endpoints and systems.  

The isolation mechanism is achieved using the Packet Filter (pfctl) binary on macOS and will block all inbound and outbound traffic from the endpoint except that which is needed for network connectivity to approved Apple and Jamf services.  

#### This ensures that the endpoint can continue to communicate with Jamf Pro for both non-MDM (e.g. a policy and script) and MDM-driven management (e.g. a configuration profile) for use in responding to a security event.

There are three components to the playbook:

1. A script that will enforce the packet filter rules to block connectivity
2. A script that will revert the packet filter rules to the default on macOS, permitting connectivity once again
3. An extension attribute script for Jamf Pro that can be used to report on the status of the playbook once deployed, for reporting

**Important**
There is a shared variable used in all three scripts that must contain the same value in order for all three to function correctly.  This is the `$fileName` variable, used to determine the names of the packet filter files.  The default is `com.acmesoft.isolate` but this may be set as desired, ideally matching the format above and containing an identifier for your organisation or team.

As of v2.0 of the enforce script, the packet filter rules will not re-apply after a system reboot.  Encrypting endpoints with FileVault will cause a password to be required to unlock the system after reboot.
#
## Please note that all resources contained within this repository are provided as-is and are not officially supported by Jamf Support.
