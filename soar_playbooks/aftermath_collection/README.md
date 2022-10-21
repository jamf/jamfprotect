# SOAR Playbook - Aftermath Collection

This SOAR playbook is provided to collect the output from an Aftermath Scan and upload it to an AWS S3 bucket.

## Workflow

For this playbook the following ***MUST*** be configured:

### Jamf Protect

Each Analytic must have the Add to Smart Group feature enabled. 

- Add to Jamf Pro Smart Group: **Checked**
    - Identifier: **aftermath**

### Jamf Pro

For this workflow, Aftermath ***must*** be already installed on the device.

#### Smart Computer Group

|Display Name|Criteria|Operator|Value|
|------------|--------|--------|-----|
|Jamf Protect: Aftermath|Jamf Protect - Smart Groups|like|aftermath

#### Policies

**Aftermath Scan:**
|Name|Frequency|Trigger|Scope|Payload|
|----|---------|-------|-----|-------|
|Aftermath Scan|Ongoing|protect|Jamf Protect: Aftermath|`/usr/local/bin/aftermath --pretty; /usr/local/bin/jamf policy -event am_collect`

**Aftermath Collect:**
|Name|Frequency|Trigger|Scope|Payload|
|----|---------|-------|-----|-------|
|Aftermath Collect|Ongoing|am_collect|All Managed Clients|aws_aftermath.sh

**AWS Aftermath Credentials:**
|Name|Frequency|Trigger|Scope|Payload|
|----|---------|-------|-----|-------|
|AWS Aftermath Credentials|Ongoing|aws_creds|All Managed Clients|aws_aftermath.pkg

**Dependencies**
- Aftermath (https://github.com/jamf/aftermath/releases)
- AWS S3 Bucket and an IAM user with `s3:PutObject` rights applied
    ```{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "VisualEditor0",
                "Effect": "Allow",
                "Action": [
                    "s3:PutObject"
                ],
                "Resource": "arn:aws:s3:::s3bucketname/*"
            }
        ]
    }
    ```
- AWS-CLI (https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- AWS Configuration and Credential Files (https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)


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