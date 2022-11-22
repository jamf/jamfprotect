# Alerts Management - AWS

This workflow is provided to forward Alerts data from the client to an AWS API Gateway which will then pass the Alert's JSON to a Lambda function to be parsed.
The Lambda function will then post a message to Slack, Teams, Jira etc as a webhook.

## Workflow execution

- [ ] Device will send a JSON file containing the details of the Alert to AWS API Gateway
- [ ] API Gateway will invoke the Lambda funtion
- [ ] Lambda funtion will parse the JSON file sent by the device, extract the useful informations and post to the 3rd party tool as chosen (Slack, Teams, Jira etc.)


## Workflow Components

- [ ] AWS API Gateway (REST or HTTP)
- [ ] Lambda funtion
- [ ] AWS Secret Manager where the appropiate secrets have been stored in.



**AWS Configuration**

- Create an AWS Lambda funtion to execute the script. 
No additional permissions are needed, we encourage to setup priviles to allow Lambda to log to CloudWatch by setting `logs:CreateLogGroup` and `logs:CreateLogStream` and`logs:PutLogEvents` rights applied
    ```{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:ARN_of_your_log_group_here:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:ARN_of_your_log_group_here:*"
            ]
        }
    ]
}
    ```

- From the Lambda Configuration editor, create an AWS API Gateway.
 
- The scripts are designed to use AWS Secret Manager to securely retrieve the credentials for Jamf Pro, Jamf Protect, Slack, Teams, VirusTotal etc are stored there 
Edit the IAM Lambda user to privide access to `secretsmanager:GetSecretValue`
    ```{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue"
            ],
            "Resource": [
                "arn:ARN_of_Secret_Manager_Secret_here"
            ]
        }
    ]
}
    ```

#
## Please note that all resources contained within this repository are provided as-is and are not officially supported by Jamf Support.