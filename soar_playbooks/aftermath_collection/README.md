SOAR Playbook - Aftermath Collection

This SOAR playbook is built to collect the output from an Aftermath Scan. 

The workflow of this playbook is as following:

1. Add the Smart Group Identifier to any analytic where you'd want Aftermath to run.
2. Create a Jamf Pro policy which runs whenever an assigned analytic is triggered.
    - Kicks off a aftermath scan
    - When finished calls a second policy to send the files to the bucket of your choice
        - Installs the .aws folder
        - Installs aws-cli tools
    -    

**Dependencies**
- [x] Aftermath (https://github.com/jamf/aftermath/releases)
- [x] AWS-CLI`*` (https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [x] AWS Configuration and Credential Files`*` (https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)

`*` These will be installed during the collection process. 

#
## Please note that all resources contained within this repository are provided as-is and are not officially supported by Jamf Support.