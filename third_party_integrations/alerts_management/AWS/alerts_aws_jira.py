#!/usr/bin/env python3

####################################################################################################
#
# Copyright (c) 2022, Jamf Software, LLC.  All rights reserved.
#
#       Redistribution and use in source and binary forms, with or without
#       modification, are permitted provided that the following conditions are met:
#               * Redistributions of source code must retain the above copyright
#                 notice, this list of conditions and the following disclaimer.
#               * Redistributions in binary form must reproduce the above copyright
#                 notice, this list of conditions and the following disclaimer in the
#                 documentation and/or other materials provided with the distribution.
#               * Neither the name of the JAMF Software, LLC nor the
#                 names of its contributors may be used to endorse or promote products
#                 derived from this software without specific prior written permission.
#
#       THIS SOFTWARE IS PROVIDED BY JAMF SOFTWARE, LLC "AS IS" AND ANY
#       EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#       WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#       DISCLAIMED. IN NO EVENT SHALL JAMF SOFTWARE, LLC BE LIABLE FOR ANY
#       DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#       (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#       LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#       ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#       (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#       SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
####################################################################################################

# This example Python script ingest data forwarded by the devices via an AWS API Gateway configured in Jamf Protect >> Actions
# and then creates a Jira ticket to alert admins of new Alerts.
# The API Gateway needs to be configured to trigger a Lambda, which runs this script, upon invocation.

# The script performs the following:
# - Ingest JSON file of an Alert forwarded by AWS API Gateway.
# - Obtain from AWS Secret Manager the following:
#     Jamf Pro API username
#     Jamf Pro API password
#     Jira API auth key
#     Jira email address
#     VirusTotal token
# - Extract from the JSON file the Alert's severity, timestamp, threat name and hostname of the device
# - Obtain a bearer token from Jamf Pro
# - Performs an API call to Jamf Pro to check if the device is enrolled and grab it's device_id
# - If a threat signature is present in the JSON file, invoke VirusTotal API to collect the details of the threat
# - Create a Jira ticket containing the Alert's details, a link to the Alert in Jamf Protect,
# - a link to the device in Jamf Pro and a link to the threat in VirusTotal, if present.

# Keep the following in mind when using this script:
#
# - You must define the protect_instance, jira_url, jamf_url, and severity_check variables to
#   match your Jamf Protect and Jamf Pro environment.
#   The protect_instance variable is your tenant name (eg. your-tenant), which is included in your tenant URL (eg.
#   https://your-tenant.protect.jamfcloud.com).
#   The jamf_url variable is your instance name (eg. your-instance), which is included in your tenant URL (eg.
#   https://your-instance.jamfcloud.com).
# - You must also define the severity_check. To create a Jira ticket for any Alert, set to 0, otherwise set accordingly to which level
#   of Alerts you'd like to be sent:
#    1 = Low
#    2 = Medium
#    3 = High
# - Example: setting severity_check = "3" will only create a Jira ticket for an alert that are categorized as High.
# - You must define the project_key which is your Jira board identifier (https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-projects/#api-group-projects)
# - You will neeed to define the SecretId for AWS Secret Manager and the associated api_user, api_password, jira_token, jira_user and virustotal_api.
# - You must define the jira_token and jira_user and add it into Secret Manager (https://developer.atlassian.com/cloud/jira/platform/rest/v3/intro/#authentication)
# - You must create an account on VirusTotal to obtain an api key and add it into Secret Manager  https://developers.virustotal.com/reference/getting-started
# - You need to add in Secret Manager the api username and password for Jamf Pro
# - This script requires the 3rd party Python library 'requests'
# - This script requires the AWS Python library 'boto3'
######################################################################################
#############                          HISTORY                            ############
############# Created by Allen Golbig and Matteo Bolognini on 05-12-2022  ############
######################################################################################


import json
import requests
import datetime
import boto3
from requests.auth import HTTPBasicAuth

client = boto3.client("secretsmanager")

protect_instance = " "
jamf_url = " "
project_key = " "
jira_url = " "
headers = {
    "Content-Type": "application/json",
    "Accept": "application/json",
}
severity_check = " "


def lambda_handler(event, context):

    response = client.get_secret_value(SecretId="")

    secretDict = json.loads(response["SecretString"])

    api_user = secretDict[" "]
    api_password = secretDict[" "]
    api_token = secretDict[""]
    email = secretDict[" "]
    virustotal_api = secretDict[" "]

    output = json.loads(event["body"])
    uuid = output["input"]["match"]["uuid"]

    jira_sev = output["input"]["match"]["severity"]

    if jira_sev < int(severity_check):
        print(
            f"The Alert have a severity of {severity} which is below the threshold set to send a message in Teams, ending run."
        )
        exit()
    else:
        if jira_sev == 3:
            sev = "High"
            priority = "Critical"
        elif jira_sev == 2:
            sev = "Medium"
            priority = "Major"
        elif jira_sev == 1:
            sev = "Low"
            priority = "Minor"

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

    token_url = f"{jamf_url}/api/v1/auth/token"
    headers = {"Accept": "application/json"}

    resp = requests.post(token_url, auth=(api_user, api_password), headers=headers)
    resp.raise_for_status()

    resp_data = resp.json()
    print(f"Access token granted, valid until {resp_data['expires']}.")

    data = resp.json()
    token = data["token"]
    resp = requests.get(
        f"{jamf_url}/JSSResource/computers/serialnumber/{sn}",
        headers={"Authorization": f"Bearer {token}", "Accept": "application/json"},
    )

    if resp.status_code != 401:
        resp_json = resp.json()
        device_id = resp_json["computer"]["general"].get("id")
    else:
        print("Check your credentials")

    from requests.auth import HTTPBasicAuth

    auth = HTTPBasicAuth(email, api_token)

    filepath = f"/tmp/{uuid}.json"
    mode = "w"
    serialized = json.dumps(output, indent=4)
    with open(filepath, mode) as f:
        f.write(serialized)

    response = requests.get(
        f"{jira_url}/rest/api/3/project/{project_key}",
        headers=headers,
        auth=auth,
    )
    project_id = response.json()["id"]

    if event == "ThreatMatchExecEvent":
        issue_data = {
            "update": {},
            "fields": {
                "summary": f"Jamf Protect: A {sev} alert has been triggered",
                "priority": {"name": f"{priority}"},
                "issuetype": {"id": 10001},
                "project": {"id": project_id},
                "description": {
                    "version": 1,
                    "type": "doc",
                    "content": [
                        {
                            "type": "paragraph",
                            "content": [
                                {
                                    "text": f"A {sev} severity alert has been triggered. View attached JSON for more details.\n\n",
                                    "type": "text",
                                },
                                {
                                    "text": f"Hostname: \n",
                                    "type": "text",
                                    "marks": [{"type": "strong"}],
                                },
                                {
                                    "text": f"{hostname}\n",
                                    "type": "text",
                                },
                                {
                                    "text": f"Type: \n",
                                    "type": "text",
                                    "marks": [{"type": "strong"}],
                                },
                                {
                                    "text": f"{event}\n",
                                    "type": "text",
                                },
                                {
                                    "text": f"Timestamp(UTC): \n",
                                    "type": "text",
                                    "marks": [{"type": "strong"}],
                                },
                                {
                                    "text": f"{timestamp}\n",
                                    "type": "text",
                                },
                                {
                                    "text": "\nInvestigate Alert in Jamf Protect: ",
                                    "type": "text",
                                },
                                {
                                    "type": "inlineCard",
                                    "attrs": {
                                        "url": f"https://{protect_instance}.protect.jamfcloud.com/alerts/{uuid}",
                                    },
                                },
                                {
                                    "text": "\nView computer in Jamf Pro: ",
                                    "type": "text",
                                },
                                {
                                    "type": "inlineCard",
                                    "attrs": {
                                        "url": f"{jamf_url}/computers.html?id={device_id}&o=r",
                                    },
                                },
                                {
                                    "text": "\nView Threat in VirusTotal: ",
                                    "type": "text",
                                },
                                {
                                    "type": "inlineCard",
                                    "attrs": {
                                        "url": f"{virustotal_link}",
                                    },
                                },
                            ],
                        }
                    ],
                },
            },
        }
        jira_response = requests.post(
            f"{jira_url}/rest/api/3/issue",
            headers=headers,
            auth=auth,
            data=json.dumps(issue_data),
        )
        print(f"Jira API Post HTTP response: {jira_response.status_code}")

    else:
        issue_data = {
            "update": {},
            "fields": {
                "summary": f"Jamf Protect: A {sev} alert has been triggered",
                "priority": {"name": f"{priority}"},
                "issuetype": {"id": 10001},
                "project": {"id": project_id},
                "description": {
                    "version": 1,
                    "type": "doc",
                    "content": [
                        {
                            "type": "paragraph",
                            "content": [
                                {
                                    "text": f"A {sev} severity alert has been triggered. View attached JSON for more details.\n\n",
                                    "type": "text",
                                },
                                {
                                    "text": f"Hostname: \n",
                                    "type": "text",
                                    "marks": [{"type": "strong"}],
                                },
                                {
                                    "text": f"{hostname}\n",
                                    "type": "text",
                                },
                                {
                                    "text": f"Type: \n",
                                    "type": "text",
                                    "marks": [{"type": "strong"}],
                                },
                                {
                                    "text": f"{event}\n",
                                    "type": "text",
                                },
                                {
                                    "text": f"Timestamp(UTC): \n",
                                    "type": "text",
                                    "marks": [{"type": "strong"}],
                                },
                                {
                                    "text": f"{timestamp}\n",
                                    "type": "text",
                                },
                                {
                                    "text": "\nInvestigate Alert in Jamf Protect: ",
                                    "type": "text",
                                },
                                {
                                    "type": "inlineCard",
                                    "attrs": {
                                        "url": f"https://{protect_instance}.protect.jamfcloud.com/alerts/{uuid}",
                                    },
                                },
                                {
                                    "text": "\nView computer in Jamf Pro: ",
                                    "type": "text",
                                },
                                {
                                    "type": "inlineCard",
                                    "attrs": {
                                        "url": f"{jamf_url}/computers.html?id={device_id}&o=r",
                                    },
                                },
                            ],
                        }
                    ],
                },
            },
        }
        jira_response = requests.post(
            f"{jira_url}/rest/api/3/issue",
            headers=headers,
            auth=auth,
            data=json.dumps(issue_data),
        )
        print(f"Jira API Post HTTP response: {jira_response.status_code}")

    j_data = jira_response.json()
    key = jira_response.json()["key"]

    url = f"https://jamfsoftware.atlassian.net/rest/api/3/issue/{key}/attachments"

    headers = {"Accept": "application/json", "X-Atlassian-Token": "no-check"}
    attachments_response = requests.request(
        "POST",
        url,
        headers=headers,
        auth=auth,
        files=[
            (
                "file",
                (f"{uuid}.json", open(f"/tmp/{uuid}.json", "rb"), "application/json"),
            )
        ],
    )
    print(
        json.dumps(
            json.loads(attachments_response.text),
            sort_keys=True,
            indent=4,
            separators=(",", ": "),
        )
    )
    print(f"Jira API Attachment HTTP response: {attachments_response.status_code}")

    return {"statusCode": 200, "body": json.dumps("Success")}
