# Helper Tools - Jamf Protect Diagnostics Collection (AWS S3)

This script is provided to trigger and collect the output from an `protectctl diagnostics` and upload it to an AWS S3 bucket.

## Workflow Steps

Steps to create the workflow:

- [ ] Create [aws_jpdiagnostics.pkg](#aws_pkg) and upload to Jamf Pro 
- [ ] Jamf Pro - Upload [jp_diagnostics_self_service.sh](./jp_diagnostics_self_service.sh)
- [ ] Jamf Pro - [Create Policies](#policies)
    - Jamf Protect Diagnostics Collect
    - AWS Credentials

## Workflow Components

####  <a id="policies"></a>Policies

|Name|Frequency|Trigger|Scope|Payload|
|----|---------|-------|-----|-------|
|**Jamf Protect Diagnostics Collect**|Ongoing|Self Service|All Managed Clients|jp_diagnostics_self_service.sh
|**AWS Credentials**|Ongoing|aws_creds|All Managed Clients|aws_jpdiagnostics.pkg

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
        - `aws configure --profile jpdiagnostics`
    3. Verify AWS CLI configuration. Run the following in Terminal.app:
        - `aws configure list --profile jpdiagnostics`
    3. Use included makefile to create pkg. Run the following from within the project folder in Terminal.app:
        - `sudo make pkg`
    4. Copy aws_jpdiagnostics.pkg to Jamf Pro.
    5. Clean up after upload complete. Run the following from within the project folder in Terminal.app:
        - `sudo make clean`
#
## Please note that all resources contained within this repository are provided as-is and are not officially supported by Jamf Support.