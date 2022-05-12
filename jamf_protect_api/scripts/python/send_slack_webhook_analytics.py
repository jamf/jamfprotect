#!/usr/bin/env python3

# This example Python script checks any updates to analytics in Jamf Protect
# and then sends a Slack Webhook to alert admins of new or updated analytics.

# The script does the following:
#
# - Obtains an access token.
# - Performs a listAnalytics query that returns a list of all available
#   Analytics.
# - Writes the list to a json file (created on first run of the script)
# - Compares the data pulled with the data in local json file
# - If the hash value of an analytic is different, then a slack webhook will
# be sent and the admin will be alerted with a link to the analytic.

# Keep the following in mind when using this script:
#
# - You must define the PROTECT_INSTANCE, CLIENT_ID, PASSWORD, and PLAN_ID variables to
#   match your Jamf Protect environment. The PROTECT_INSTANCE variable is your
#   tenant name (eg. your-tenant), which is included in your tenant URL (eg.
#   https://your-tenant.protect.jamfcloud.com).
# - You must also define the SLACK_TOKEN (https://api.slack.com/messaging/webhooks#posting_with_webhooks)
# - This script requires the 3rd party Python library 'requests'

import requests, json, os
from datetime import datetime

PROTECT_INSTANCE = ""
CLIENT_ID = ""
PASSWORD = ""

SLACK_URL = "https://hooks.slack.com/services"
SLACK_TOKEN = ""


def get_access_token(protect_instance, client_id, password):
    """Gets a reusable access token to authenticate requests to the Jamf
    Protect API"""
    token_url = f"https://{protect_instance}.protect.jamfcloud.com/token"
    payload = {
        "client_id": client_id,
        "password": password,
    }
    resp = requests.post(token_url, json=payload)
    resp.raise_for_status()
    resp_data = resp.json()
    print(
        f"Access token granted, valid for {int(resp_data['expires_in'] // 60)} minutes."
    )
    return resp_data["access_token"]


def make_api_call(protect_instance, access_token, query, variables=None):
    """Sends a GraphQL query to the Jamf Protect API, and returns the
    response."""
    if variables is None:
        variables = {}
    api_url = f"https://{protect_instance}.protect.jamfcloud.com/graphql"
    payload = {"query": query, "variables": variables}
    headers = {"Authorization": access_token}
    resp = requests.post(
        api_url,
        json=payload,
        headers=headers,
    )
    resp.raise_for_status()
    return resp.json()


LIST_ANALYTICS_QUERY = """
    query listAnalytics{
        listAnalytics{
            items {
                hash
                name
                created
                updated
                description
                jamf
                severity
                uuid
            }
        }
    }
"""


def slack_webhook(uuid, name, sev, desc, jamf, created, updated, analyticType):

    createdDate = datetime.strptime(created, "%Y-%m-%dT%H:%M:%S.%fZ")
    updatedDate = datetime.strptime(updated, "%Y-%m-%dT%H:%M:%S.%fZ")

    analytic_source = "Jamf" if jamf else "Custom Analytic"

    payload = {
        "blocks": [
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*{analyticType} Jamf Protect Analytic* {PROTECT_INSTANCE.upper()}",
                },
            },
            {"type": "divider"},
            {
                "type": "section",
                "fields": [
                    {"type": "mrkdwn", "text": f"*Name:*\n{name}"},
                    {"type": "mrkdwn", "text": f"*Severity:*\n{sev}"},
                    {"type": "mrkdwn", "text": f"*Owner:*\n{analytic_source}"},
                    {
                        "type": "mrkdwn",
                        "text": f"*Created:*\n{createdDate.strftime('%Y-%m-%d %H:%M')}",
                    },
                    {"type": "mrkdwn", "text": f"*Description:*\n{desc}"},
                    {
                        "type": "mrkdwn",
                        "text": f"*Modified:*\n{updatedDate.strftime('%Y-%m-%d %H:%M')}",
                    },
                ],
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*<https://{PROTECT_INSTANCE}.protect.jamfcloud.com/analytics/{uuid}|View Analytic in Jamf Protect>*",
                },
            },
        ]
    }
    slack_resp = requests.post(SLACK_URL + SLACK_TOKEN, json=payload)
    print(slack_resp.status_code)


def __main__():

    # Get the access token
    access_token = get_access_token(PROTECT_INSTANCE, CLIENT_ID, PASSWORD)

    # Get all available Analytics
    resp = make_api_call(PROTECT_INSTANCE, access_token, LIST_ANALYTICS_QUERY)

    jamf_analytics_dict = {a["hash"]: a for a in resp["data"]["listAnalytics"]["items"]}

    # Check if json file exists, if not, create and dump json
    if not os.path.exists("/var/tmp/jamf-protect-analytics-update-slack-webhook.json"):
        print("Creating JSON file")
        with open(
            "/var/tmp/jamf-protect-analytics-update-slack-webhook", "w"
        ) as output:
            json.dump(jamf_analytics_dict, output)
            return

    output = json.load(
        open("/var/tmp/jamf-protect-analytics-update-slack-webhook.json", "r")
    )

    # Check diff between json file and new pull
    new_or_updated_analytics = set(jamf_analytics_dict).difference(output)

    if not new_or_updated_analytics:
        print(f"Nothing to see here.")
        return

    print(f"New or updated analytics available.")
    for a_hash in new_or_updated_analytics:
        new_analytic = jamf_analytics_dict[a_hash]
        if any(
            new_analytic["uuid"] == old_analytic["uuid"]
            for old_analytic in output.values()
        ):
            new_analytic["analyticType"] = "Updated"
        else:
            new_analytic["analyticType"] = "New"
        slack_webhook(
            new_analytic["uuid"],
            new_analytic["name"],
            new_analytic["severity"],
            new_analytic["description"],
            new_analytic["jamf"],
            new_analytic["created"],
            new_analytic["updated"],
            new_analytic["analyticType"],
        )

    print(f"Updating JSON file for next run.")
    with open("/var/tmp/analytics.json", "w") as output:
        json.dump(jamf_analytics_dict, output)
        return


if __name__ == "__main__":

    __main__()
