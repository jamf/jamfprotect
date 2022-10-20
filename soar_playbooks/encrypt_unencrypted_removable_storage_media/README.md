# SOAR Playbook - Physical Removable Media Disk Encryption

Are you looking for a playbook that enforces encryption on unencrypted physical removable media devices? then this playbook might be useful for you!

This playbook provides a workflow between Jamf Protect and Jamf Pro to monitor `USBInserted` events using Analytics and once detected that the encryption state of a removable media device is unencrypted the end user will be prompted with notifications to encrypt it on-demand or have it mounted as read-only and preventing write activities to those removable devices.

The concept of this playbook is as following:

1. The `USBInserted` Analytic has been enabled enabled in the Plan and the Smart Group option has been set with a custom value
2. In Jamf Pro we have a policy that runs one of the contained scripts within this repository once the `USBInserted` Analytic has been detected by Jamf Protect
3. The end user is being presented with notifications to either keep the external media mounted as read-only in case it's not encrypted, or encrypt it with a password and have it mounted as read-write, depending on the storage type volume the workflow encrypts the disk with no loss of data, or in case of Microsoft Visual Data we need to re-format the disk.

**Dependencies**
This reposository contains two scripts, one developed to work with swiftDialog and the other to work with IBMNotifier.

- [ ] SwiftDialog (https://github.com/bartreardon/swiftDialog/releases)
-  swiftDialog includes options to enforce a password and hint complexity requirement based on a REGEX string


- [ ] IBMNotifier (https://github.com/IBM/mac-ibm-notifications/releases)

**Important**
*Currently this workflow can’t be used alongside with having Device Controls set by Jamf Protect*

Please read through and test this script intensively prior adding it to your production environment, as in some cases the end-user agree's to erase the external disk and losing it's contents stored on it. 

# swiftDialog

![First Prompt](https://github.com/jamf/jamfprotect/blob/project/add_removable_media_encryption_workflow/soar_playbooks/encrypt_unencrypted_removable_storage_media/Images/swiftDialog_Encryption_Workflow_1.png)

![Second Prompt](https://github.com/jamf/jamfprotect/blob/project/add_removable_media_encryption_workflow/soar_playbooks/encrypt_unencrypted_removable_storage_media/Images/swiftDialog_Encryption_Workflow_2.png)

![Third Prompt](https://github.com/jamf/jamfprotect/blob/project/add_removable_media_encryption_workflow/soar_playbooks/encrypt_unencrypted_removable_storage_media/Images/swiftDialog_Encryption_Workflow_3.png)


# IBM Notifier
![First Prompt](https://github.com/jamf/jamfprotect/blob/project/add_removable_media_encryption_workflow/soar_playbooks/encrypt_unencrypted_removable_storage_media/Images/IBMNotifier_Encryption_Workflow_1.png)

![Second Prompt](https://github.com/jamf/jamfprotect/blob/project/add_removable_media_encryption_workflow/soar_playbooks/encrypt_unencrypted_removable_storage_media/Images/IBMNotifier_Encryption_Workflow_2.png)

![Third Prompt](https://github.com/jamf/jamfprotect/blob/project/add_removable_media_encryption_workflow/soar_playbooks/encrypt_unencrypted_removable_storage_media/Images/IBMNotifier_Encryption_Workflow_3.png)

#
## Please note that all resources contained within this repository are provided as-is and are not officially supported by Jamf Support.
