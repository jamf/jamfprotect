# SOAR Playbook - Aftermath Collection

This SOAR playbook is provided to collect the output from an Aftermath Scan and upload it to an AWS S3 bucket.

## About Aftermath

Aftermath is a Swift-based, open-source incident response framework, available on Jamf's open source GitHub repository (https://github.com/jamf/aftermath).

Aftermath can be leveraged by defenders in order to collect and subsequently analyze the data from the compromised host. When deploying Aftermath via Jamf Pro, this script can be used in tandem with an Aftermath first run, ensuring the data is securely stored in a designated S3 bucket once an Aftermath collection is complete.

## Workflow Steps

Steps to create the workflow:

- [ ] Jamf Pro - Upload [Aftermath.pkg](https://github.com/jamf/aftermath/releases) and deploy to endpoints
- [ ] Create [aws_aftermath.pkg](#aws_pkg) and upload to Jamf Pro 
- [ ] Jamf Protect - Analytics Smart Group Identifier configured
- [ ] Jamf Pro - Create a Smart Group populated by `Jamf Protect - Smart Groups` [Extension Attribute](https://docs.jamf.com/jamf-protect/documentation/Setting_Up_Analytic_Remediation_With_Jamf_Pro.html#task-7832) 
- [ ] Jamf Pro - Upload [aftermath_collection.sh](./aftermath_collection.sh)
- [ ] Jamf Pro - [Create Policies](#policies)
    - Aftermath Scan
    - Aftermath Collect
    - AWS Aftermath Credentials

## Workflow Components
### Jamf Protect

Each Analytic must have the Add to Smart Group feature enabled. 

- Add to Jamf Pro Smart Group: **Checked**
    - Identifier: **aftermath**

### Jamf Pro
#### Smart Computer Group

|Display Name|Criteria|Operator|Value|
|------------|--------|--------|-----|
|Jamf Protect: Aftermath|Jamf Protect - Smart Groups|like|aftermath

####  <a id="policies"></a>Policies

|Name|Frequency|Trigger|Scope|Payload|
|----|---------|-------|-----|-------|
|Aftermath Scan|Ongoing|protect|Jamf Protect: Aftermath|`/usr/local/bin/aftermath --pretty; /usr/local/bin/jamf policy -event am_collect`

|Name|Frequency|Trigger|Scope|Payload|
|----|---------|-------|-----|-------|
|Aftermath Collect|Ongoing|am_collect|All Managed Clients|aws_aftermath.sh

|Name|Frequency|Trigger|Scope|Payload|
|----|---------|-------|-----|-------|
|AWS Aftermath Credentials|Ongoing|aws_creds|All Managed Clients|aws_aftermath.pkg

**AWS Configuration**

- Create an AWS S3 Bucket and an IAM user with `s3:PutObject` rights applied
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
- Create <a id="aws_pkg"></a>AWS CLI Configuration file:
    1. Install the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
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