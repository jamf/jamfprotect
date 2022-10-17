# SOAR Playbook - Aftermath Collection

This SOAR playbook is built to collect the output from an Aftermath Scan. 

The workflow of this playbook is as following:

1. Add the Smart Group Identifier to any analytic where you'd want Aftermath to run.
2. Create a Jamf Pro policy which runs whenever an assigned analytic is triggered.
    - Kicks off an aftermath scan
    - When complete triggers a second policy to send the files to the bucket of your choice
        - Installs the .aws folder
        - Runs script

**Dependencies**
- Aftermath (https://github.com/jamf/aftermath/releases)
- AWS-CLI (https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- AWS Configuration and Credential Files (https://docs.aws.amazon.com/cli/latest/userguide/ cli-configure-files.html)


**Steps to Create AWS Configuration**

After you've created and securely configured your AWS infrastructure do the following:
1. Install the aws cli tool
2. From terminal run the following:
   - `aws configure --profile aftermath`
3. Once configuration is complete adjust the permissions:
   - `sudo chown -R root:wheel ~/.aws`
   - `sudo chmod -R 400 ~/.aws`
4. Move to appropriate folder, ex: 
   - `sudo mv ~/.aws /opt/.aws`
5. Use included makefile to create pkg (Coming Soon)
#
## Please note that all resources contained within this repository are provided as-is and are not officially supported by Jamf Support.