# SOAR Playbook - Aftermath Collection

This SOAR playbook is provided to collect the output from an Aftermath Scan and upload it to an AWS S3 bucket.

The workflow of this playbook is as follows:

1. Add the Smart Group Identifier to any analytic where you'd want Aftermath to run.
2. Create a Jamf Pro policy which runs whenever an assigned analytic is triggered.
    - Kicks off an aftermath scan
    - When completed, triggers a second policy to send the files to the bucket of your choice
        - Installs the .aws folder
        - Runs script

**Dependencies**
- Aftermath (https://github.com/jamf/aftermath/releases)
- AWS S3 Bucket with `s3:PutObject` only policy
- AWS-CLI (https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- AWS Configuration and Credential Files (https://docs.aws.amazon.com/cli/latest/userguide/ cli-configure-files.html)


**Steps to Create AWS Configuration**

After you've created and securely configured your AWS infrastructure do the following:
1. Install the AWS CLI 
2. Configure AWS CLI profile. Run the following in Terminal.app:
    - `aws configure --profile aftermath`
3. Verify AWS CLI configuration. Run the following in Terminal.app:
    - `aws configure list --profile aftermath`
3. Use included makefile to create pkg. Run the following from within the project folder in Terminal.app:
    - `sudo make pkg`
4. Copy aws_aftermath.pkg to Jamf Pro.
5. Clean up after upload complete. Run the following from within the project folder in Terminal.app:
    - `sudo make clean`
#
## Please note that all resources contained within this repository are provided as-is and are not officially supported by Jamf Support.