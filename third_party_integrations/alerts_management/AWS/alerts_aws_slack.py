#!/usr/bin/env python3

# This example Python script ingest data forwarded by the devices via an AWS API Gateway configured in Jamf Protect >> Actions
# and then sends a Slack Webhook to alert admins of new Alerts.
# The API Gateway needs to be configured to trigger a Lambda, which runs this script, upon invocation.

# The script performs the following:
# - Ingest JSON file of an Alert forwarded by AWS API Gateway.
# - Obtain from AWS Secret Manager the following:
#     Jamf Pro API username
#     Jamf Pro API password
#     Slakc WebHook token
#     VirusTotal token
# - Extract from the JSON file the Alert's severity, timestamp, threat name and hostname of the device
# - Obtain a bearer token from Jamf Pro
# - Performs an API call to Jamf Pro to check if the device is enrolled and grab it's device_id
# - If a threat signature is present in the JSON file, invoke VirusTotal API to collect the details of the threat
# - Send a Slack WebHook containing the Alert's details, a link to the Alert in Jamf Protect,
# - a link to the device in Jamf Pro and a link to the threat in VirusTotal, if present.

# Keep the following in mind when using this script:
#
# - You must define the PROTECT_INSTANCE, SLACK_URL, JAMF_URL, and SEVERITY_CHECK variables to
#   match your Jamf Protect and Jamf Pro environment.
#   The PROTECT_INSTANCE variable is your tenant name (eg. your-tenant), which is included in your tenant URL (eg.
#   https://your-tenant.protect.jamfcloud.com).
#   The JAMF_URL variable is your instance name (eg. your-instance), which is included in your tenant URL (eg.
#   https://your-instance.jamfcloud.com).
# - You must also define the SEVERITY_CHECK. To post to Slack any Alert, set to 0, otherwise set accordingly to which level
#   of Alerts you'd like to be sent:
#    1 = Low
#    2 = Medium
#    3 = High
# - Example: setting SEVERITY_CHECK = "3" will only send to Slack Alerts that are categorized as High.
# - You will neeed to define the SecretId for AWS Secret Manager and the associated api_user, api_password, slack_token and virustotal_api.
# - You must define the slack_token and add it into Secret Manager (https://api.slack.com/messaging/webhooks#posting_with_webhooks)
# - You must create an account on VirusTotal to obtain an api key and add it into Secret Manager  https://developers.virustotal.com/reference/getting-started
# - You need to add in Secret Manager the api username and password for Jamf Pro
# - This script requires the 3rd party Python library 'requests'
# - This script requires the AWS Python library 'boto3'
######################################################################################
#############                          HISTORY                            ############
############# Created by Allen Golbig and Matteo Bolognini on 22-11-2022  ############
######################################################################################


import json
import requests
import datetime
import boto3
import http.client

client = boto3.client("secretsmanager")

PROTECT_INSTANCE = ""
SLACK_URL = ""
JAMF_URL = ""
SEVERITY_CHECK = ""


def lambda_handler(event, context):

    response = client.get_secret_value(SecretId="")

    secretDict = json.loads(response["SecretString"])

    api_user = secretDict[""]
    api_password = secretDict[""]
    slack_token = secretDict[""]
    virustotal_api = secretDict[""]

    output = json.loads(event["body"])
    uuid = output["input"]["match"]["uuid"]

    severity = output["input"]["match"]["severity"]

    if severity < int(SEVERITY_CHECK):
        print(
            f"The Alert have a severity of {severity} which is below the threshold set to send a message in Slack, ending run."
        )
        exit()
    else:
        if severity == 3:
            sev = ":red_circle:"
        elif severity == 2:
            sev = ":large_yellow_circle:"
        elif severity == 1:
            sev = ":white_circle:"

    hostname = output["input"]["host"]["hostname"]
    sn = output["input"]["host"]["serial"]
    facts = len(output["input"]["match"]["facts"])
    if facts > 1:
        event = (
            output["input"]["match"]["facts"][0]["name"]
            + " & "
            + output["input"]["match"]["facts"][1]["name"]
        )
    else:
        event = output["input"]["match"]["facts"][0]["name"]

    if event == "ThreatMatchExecEvent":
        hash = output["input"]["related"]["binaries"][0]["sha256hex"]
        url = "https://www.virustotal.com/vtapi/v2/file/report"
        params = {"apikey": f"{virustotal_api}", "resource": f"{hash}"}
        response = requests.get(url, params=params)
        virustotal_link = response.json().get("permalink")

    time = output["input"]["match"]["event"]["timestamp"]
    timestamp = datetime.datetime.fromtimestamp(time).strftime("%Y-%m-%d %H:%M:%S")

    token_url = f"https://{JAMF_URL}.jamfcloud.com/api/v1/auth/token"
    headers = {"Accept": "application/json"}

    resp = requests.post(token_url, auth=(api_user, api_password), headers=headers)
    resp.raise_for_status()

    resp_data = resp.json()
    print(f"Access token granted, valid until {resp_data['expires']}.")

    data = resp.json()
    token = data["token"]
    resp = requests.get(
        f"https://{JAMF_URL}.jamfcloud.com/JSSResource/computers/serialnumber/{sn}",
        headers={"Authorization": f"Bearer {token}", "Accept": "application/json"},
    )

    if resp.status_code != 401:
        resp_json = resp.json()
        device_id = resp_json["computer"]["general"].get("id")
    else:
        print("Check your credentials")

    if event == "ThreatMatchExecEvent":
        payload = {
            "blocks": [
                {
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": f"*An alert has been triggered:*",
                    },
                },
                {"type": "divider"},
                {
                    "type": "section",
                    "fields": [
                        {"type": "mrkdwn", "text": f"*Type:*\n{event}"},
                        {"type": "mrkdwn", "text": f"*Severity:*\n{sev}"},
                        {"type": "mrkdwn", "text": f"*Timestamp (UTC):*\n{timestamp}"},
                        {
                            "type": "mrkdwn",
                            "text": f"*HostName:*\n<https://{JAMF_URL}.jamfcloud.com/computers.html?id={device_id}&o=r|{hostname}>",
                        },
                    ],
                },
                {"type": "divider"},
                {
                    "type": "section",
                    "fields": [
                        {
                            "type": "mrkdwn",
                            "text": f"*<https://{protect_instance}.protect.jamfcloud.com/alerts/{uuid}|Investigate Alert in Jamf Protect>*",
                        },
                        {
                            "type": "mrkdwn",
                            "text": f"*<{virustotal_link}|View Threat in VirusTotal>*",
                        },
                    ],
                },
            ]
        }
        slack_resp = requests.post(SLACK_URL + slack_token, json=payload)
        print(f"Slack Webhook Post HTTP response: {slack_resp.status_code}")

    else:
        payload = {
            "blocks": [
                {
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": f"*An alert has been triggered:*",
                    },
                },
                {"type": "divider"},
                {
                    "type": "section",
                    "fields": [
                        {"type": "mrkdwn", "text": f"*Type:*\n{event}"},
                        {"type": "mrkdwn", "text": f"*Severity:*\n{sev}"},
                        {"type": "mrkdwn", "text": f"*Timestamp (UTC):*\n{timestamp}"},
                        {
                            "type": "mrkdwn",
                            "text": f"*HostName:*\n<https://{JAMF_URL}.jamfcloud.com/computers.html?id={device_id}&o=r|{hostname}>",
                        },
                    ],
                },
                {"type": "divider"},
                {
                    "type": "section",
                    "fields": [
                        {
                            "type": "mrkdwn",
                            "text": f"*<https://{PROTECT_INSTANCE}.protect.jamfcloud.com/alerts/{uuid}|Investigate Alert in Jamf Protect>*",
                        },
                    ],
                },
            ]
        }
        slack_resp = requests.post(SLACK_URL + slack_token, json=payload)
        print(f"Slack Webhook Post HTTP response: {slack_resp.status_code}")

    return {"statusCode": 200, "body": json.dumps("Success")}
