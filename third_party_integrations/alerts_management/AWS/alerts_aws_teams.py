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
# and then sends a Teams Webhook to alert admins of new Alerts.
# The API Gateway needs to be configured to trigger a Lambda, which runs this script, upon invocation.

# The script performs the following:
# - Ingest JSON file of an Alert forwarded by AWS API Gateway.
# - Obtain from AWS Secret Manager the following:
#     Jamf Pro API username
#     Jamf Pro API password
#     Teams WebHook token
#     VirusTotal token
# - Extract from the JSON file the Alert's severity, timestamp, threat name and hostname of the device
# - Obtain a bearer token from Jamf Pro
# - Performs an API call to Jamf Pro to check if the device is enrolled and grab it's device_id
# - If a threat signature is present in the JSON file, invoke VirusTotal API to collect the details of the threat
# - Send a Teams WebHook containing the Alert's details, a link to the Alert in Jamf Protect,
# - a link to the device in Jamf Pro and a link to the threat in VirusTotal, if present.

# Keep the following in mind when using this script:
#
# - You must define the PROTECT_INSTANCE, JAMF_URL, and SEVERITY_CHECK variables to
#   match your Jamf Protect and Jamf Pro environment.
#   The PROTECT_INSTANCE variable is your tenant name (eg. your-tenant), which is included in your tenant URL (eg.
#   https://your-tenant.protect.jamfcloud.com).
#   The JAMF_URL variable is your instance name (eg. your-instance), which is included in your tenant URL (eg.
#   https://your-instance.jamfcloud.com).
# - You must also define the SEVERITY_CHECK. To post to Teams any Alert, set to 0, otherwise set accordingly to which level
#   of Alerts you'd like to be sent:
#    1 = Low
#    2 = Medium
#    3 = High
# - Example: setting SEVERITY_CHECK = "3" will only send to Teams Alerts that are categorized as High.
# - You will neeed to define the SecretId for AWS Secret Manager and the associated api_user, api_password, teams_url and virustotal_api.
# - You must define the teams_url and add it into Secret Manager (https://learn.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/what-are-webhooks-and-connectors)
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
JAMF_URL = ""
severity_check = ""


def lambda_handler(event, context):

    response = client.get_secret_value(SecretId="")

    secretDict = json.loads(response["SecretString"])

    api_user = secretDict[""]
    api_password = secretDict[""]
    virustotal_api = secretDict[""]
    teams_url = secretDict[""]

    output = json.loads(event["body"])
    uuid = output["input"]["match"]["uuid"]

    severity = output["input"]["match"]["severity"]

    if severity < int(severity_check):
        print(
            f"The Alert have a severity of {severity} which is below the threshold set to send a message in Teams, ending run."
        )
        exit()
    else:
        if severity == 3:
            sev = "High"
        elif severity == 2:
            sev = "Medium"
        elif severity == 1:
            sev = "Low"

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
            "@type": "MessageCard",
            "@context": "http://schema.org/extensions",
            "themeColor": "0076D7",
            "summary": "A Jamf Protect Alert has been triggered:",
            "sections": [
                {
                    "activityTitle": f"A Jamf Protect Alert level {sev} has been triggered:",
                    "activitySubtitle": f"Jamf Protect Threat Prevention detection: {event}",
                    "facts": [
                        {"name": "Hostname", "value": f"{hostname}"},
                        {"name": "Severity", "value": f"{severity}"},
                        {"name": "Timestamp", "value": f"{timestamp}"},
                    ],
                    "markdown": "true",
                }
            ],
            "potentialAction": [
                {
                    "@type": "OpenUri",
                    "name": "Investigate Alert in Jamf Protect",
                    "targets": [
                        {
                            "os": "default",
                            "uri": f"https://{PROTECT_INSTANCE}.protect.jamfcloud.com/alerts/{uuid}",
                        }
                    ],
                },
                {
                    "@type": "OpenUri",
                    "name": "View Threat in VirusTotal",
                    "targets": [{"os": "default", "uri": f"{virustotal_link}"}],
                },
                {
                    "@type": "OpenUri",
                    "name": "View computer in Jamf Pro",
                    "targets": [
                        {
                            "os": "default",
                            "uri": f"https://{JAMF_URL}.jamfcloud.com/computers.html?id={device_id}&o=r",
                        }
                    ],
                },
            ],
        }
        teams_resp = requests.post(teams_url, json=payload)
        print(f"Teams Webhook Post HTTP response: {teams_resp.status_code}")

    else:
        payload = {
            "@type": "MessageCard",
            "@context": "http://schema.org/extensions",
            "themeColor": "0076D7",
            "summary": "A Jamf Protect Alert has been triggered:",
            "sections": [
                {
                    "activityTitle": f"A Jamf Protect Alert level {sev} has been triggered:",
                    "activitySubtitle": f"Jamf Protect Analytic matched: {event}",
                    "facts": [
                        {"name": "Hostname", "value": f"{hostname}"},
                        {"name": "Severity", "value": f"{severity}"},
                        {"name": "Timestamp", "value": f"{timestamp}"},
                    ],
                    "markdown": "true",
                }
            ],
            "potentialAction": [
                {
                    "@type": "OpenUri",
                    "name": "Investigate Alert in Jamf Protect",
                    "targets": [
                        {
                            "os": "default",
                            "uri": f"https://{PROTECT_INSTANCE}.protect.jamfcloud.com/alerts/{uuid}",
                        }
                    ],
                },
                {
                    "@type": "OpenUri",
                    "name": "View computer in Jamf Pro",
                    "targets": [
                        {
                            "os": "default",
                            "uri": f"https://{JAMF_URL}.jamfcloud.com/computers.html?id={device_id}&o=r",
                        }
                    ],
                },
            ],
        }
        teams_resp = requests.post(teams_url, json=payload)
        print(payload)
        print(f"Teams Webhook Post HTTP response: {teams_resp.status_code}")

    return {"statusCode": 200, "body": json.dumps("Success")}
