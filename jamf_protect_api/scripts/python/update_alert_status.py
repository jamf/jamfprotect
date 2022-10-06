#!/usr/bin/env python3

# This example Python script updates the status of alert(s) (New, InProgress, or Resolved).

# The script does the following:
#
# - Obtains an access token.
# - Updates the status of the provided alert(s), using the
#   updateAlerts mutation.

# Keep the following in mind when using this script:
#
# - You must define the PROTECT_INSTANCE, CLIENT_ID, and PASSWORD variables to
#   match your Jamf Protect environment. The PROTECT_INSTANCE variable is your
#   tenant name (eg. your-tenant), which is included in your tenant URL (eg.
#   https://your-tenant.protect.jamfcloud.com).
# - There are two required arguments that must be passed when running the script,
#   -u/--uuids and -s/--status.
# - Maximum number of uuids that can be passed is 100.
# - This script requires the 3rd party Python library 'requests'

import requests
import argparse
import sys

PROTECT_INSTANCE = ""
CLIENT_ID = ""
PASSWORD = ""


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


UPDATE_ALERT_STATUS_QUERY = """
    mutation updateAlerts($input: AlertUpdateInput!){
        updateAlerts(input: $input) {
            items {
                status
            }
        }
    }
"""


def create_args():
    parser = argparse.ArgumentParser(
        description="Given an Alert(s) UUID(s), set the current status."
    )
    parser.add_argument(
        "-u",
        "--uuids",
        default=None,
        help="UUIDs of alerts, comma separated.",
        required=True,
    )
    parser.add_argument(
        "-s", "--status", default=None, help="Status of alerts.", required=True
    )
    return parser.parse_args()


def __main__():

    args = create_args()

    ALERT_UUIDS = args.uuids.split(",")
    ALERT_STATUS = args.status
    if len(ALERT_UUIDS) > 100:
        print("Maximum number of UUIDs is 100. Please try again.")
        sys.exit(1)
        
    if (
        ALERT_STATUS == "New"
        or ALERT_STATUS == "InProgress"
        or ALERT_STATUS == "Resolved"
    ):

        # Get the access token
        access_token = get_access_token(PROTECT_INSTANCE, CLIENT_ID, PASSWORD)

        # Set variables for graphql mutation
        variables = {
            "input": {"uuids": ALERT_UUIDS, "status": ALERT_STATUS},
        }

        # Make API call
        resp = make_api_call(
            PROTECT_INSTANCE, access_token, UPDATE_ALERT_STATUS_QUERY, variables
        )
        print(resp)
        print(f"The status of alert(s) {ALERT_UUIDS} are set to {ALERT_STATUS}.")
    else:
        print("Status must be set to New, InProgress, or Resolved.")
        return

if __name__ == "__main__":

    __main__()
