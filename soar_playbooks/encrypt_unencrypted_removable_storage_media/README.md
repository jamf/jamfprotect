# SOAR Playbook - Physical Removable Media Disk Encryption

This SOAR playbook is built to provide workflows on an endpoint to a user to encrypt unencrypted physical removable devices based on USBInserted Analytics provided by Jamf Protect.

The concept of this playbook is as following:

1. The USBInserted Analytic has been enabled enabled in the Plan and the Smart Group option has been set with a custom value
2. In Jamf Pro we have a policy that runs the script contained in this repository once the USBInserted Analytic has been triggered
3. The end user is being presented with a workflow to either keep the external media mounted as read-only in case it's not encrypted, or encrypt it with a password and have it mounted as read-write, depending on the storage type volume the workflow encrypts the disk with no loss of data, or in case of Microsoft Visual Data we need to re-format the disk.

**Dependencies**
- [ ] IBMNotifier (https://github.com/IBM/mac-ibm-notifications/releases)

**Important**
Please read through and test this script intensively prior adding it to your production environment, as in some cases the end-user agree's to erase the external disk.

![First Prompt](https://github.com/jamf/jamfprotect/blob/project/add_removable_media_encryption_workflow/soar_playbooks/encrypt_unencrypted_removable_storage_media/Images/Encryption_Workflow_1.png)

![Second Prompt](https://github.com/jamf/jamfprotect/blob/project/add_removable_media_encryption_workflow/soar_playbooks/encrypt_unencrypted_removable_storage_media/Images/Encryption_Workflow_2.png)

![Third Prompt](https://github.com/jamf/jamfprotect/blob/project/add_removable_media_encryption_workflow/soar_playbooks/encrypt_unencrypted_removable_storage_media/Images/Encryption_Workflow_3.png)

#
## Please note that all resources contained within this repository are provided as-is and are not officially supported by Jamf Support.
