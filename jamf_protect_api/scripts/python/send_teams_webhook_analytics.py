#!/usr/bin/env python3

# This example Python script checks any updates to analytics in Jamf Protect
# and then sends a Microsoft Teams Webhook to alert admins of new or updated analytics.

# The script does the following:
#
# - Obtains an access token.
# - Performs a listAnalytics query that returns a list of all available
#   Analytics.
# - Writes the list to a json file (created on first run of the script)
# - Compares the data pulled with the data in local json file
# - If the hash value of an analytic is different, then a Microsoft Teams webhook will
# be sent and the admin will be alerted with a link to the analytic.

# Keep the following in mind when using this script:
#
# - You must define the PROTECT_INSTANCE, CLIENT_ID, PASSWORD, and PLAN_ID variables to
#   match your Jamf Protect environment. The PROTECT_INSTANCE variable is your
#   tenant name (eg. your-tenant), which is included in your tenant URL (eg.
#   https://your-tenant.protect.jamfcloud.com).
# - You must also define the TEAMS_URL (https://docs.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/add-incoming-webhook)
# - This script requires the 3rd party Python library 'requests'

import requests, json, os
from datetime import datetime

PROTECT_INSTANCE = ""
CLIENT_ID = ""
PASSWORD = ""

TEAMS_URL = ""

JSON_OUTPUT_FILE = "/var/tmp/jamf-protect-analytics-update-teams-webhook.json"


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


def teams_webhook(uuid, name, sev, desc, jamf, created, updated, analyticType):

    createdDate = datetime.strptime(created, "%Y-%m-%dT%H:%M:%S.%fZ")
    updatedDate = datetime.strptime(updated, "%Y-%m-%dT%H:%M:%S.%fZ")

    analytic_source = "Jamf" if jamf else "Custom Analytic"

    payload = {
        "@type": "MessageCard",
        "summary": "Jamf Protect Analytic",
        "sections": [
            {
                "activityTitle": f"{analyticType} Jamf Protect Analytic",
                "activitySubtitle": f"{PROTECT_INSTANCE.upper()}",
                "facts": [
                    {"name": "Name", "value": f"{name}"},
                    {"name": "Severity", "value": f"{sev}"},
                    {"name": "Owner", "value": f"{analytic_source}"},
                    {"name": "Description", "value": f"{desc}"},
                    {
                        "name": "Created",
                        "value": f"{createdDate.strftime('%Y-%m-%d %H:%M')}",
                    },
                    {
                        "name": "Modified",
                        "value": f"{updatedDate.strftime('%Y-%m-%d %H:%M')}",
                    },
                ],
                "markdown": "true",
            }
        ],
        "potentialAction": [
            {
                "@type": "OpenUri",
                "name": "View Analytic in Jamf Protect",
                "targets": [
                    {
                        "os": "default",
                        "uri": f"https://{PROTECT_INSTANCE}.protect.jamfcloud.com/analytics/{uuid}",
                    }
                ],
            }
        ],
    }
    teams_resp = requests.post(TEAMS_URL, json=payload)
    print(teams_resp.status_code)


def __main__():

    # Get the access token
    access_token = get_access_token(PROTECT_INSTANCE, CLIENT_ID, PASSWORD)

    # Get all available Analytics
    resp = make_api_call(PROTECT_INSTANCE, access_token, LIST_ANALYTICS_QUERY)

    jamf_analytics_dict = {a["hash"]: a for a in resp["data"]["listAnalytics"]["items"]}

    # Check if json file exists
    if os.path.exists(JSON_OUTPUT_FILE):

        output = json.load(open(JSON_OUTPUT_FILE, "r"))

        # Check diff between json file and new pull
        new_or_updated_analytics = set(jamf_analytics_dict).difference(output)

        if not new_or_updated_analytics:
            print(f"No new or updated analytics.")
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
            teams_webhook(
                new_analytic["uuid"],
                new_analytic["name"],
                new_analytic["severity"],
                new_analytic["description"],
                new_analytic["jamf"],
                new_analytic["created"],
                new_analytic["updated"],
                new_analytic["analyticType"],
            )

    print("Generating JSON file for next run.")
    with open(JSON_OUTPUT_FILE, "w") as output:
        json.dump(jamf_analytics_dict, output)


if __name__ == "__main__":

    __main__()
