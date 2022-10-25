# SOAR Playbook - Aftermath Collection

This SOAR playbook is provided to collect the output from an Aftermath Scan and upload it to an cloud storage solution of choice.

## About Aftermath

Aftermath is a Swift-based, open-source incident response framework, available on Jamf's open source GitHub repository (https://github.com/jamf/aftermath).

Aftermath can be leveraged by defenders in order to collect and subsequently analyze the data from the compromised host. When deploying Aftermath via Jamf Pro, this script can be used in tandem with an Aftermath first run, ensuring the data is securely stored in a designated storage solution once an Aftermath collection is complete.

## Storage Solutions

The workflows in this repository support but are not limited to:

- [ ] [Amazon S3 Bucket](./aws_s3/)
- [ ] [Google Cloud Storage Bucket](./google_cloud_storage/)
- [ ] [Azure File](./azure_files/)

#
## Please note that all resources contained within this repository are provided as-is and are not officially supported by Jamf Support.