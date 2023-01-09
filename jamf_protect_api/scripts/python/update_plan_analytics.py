#!/usr/bin/env python3

# This example Python script syncs new Jamf Analytics with an existing Plan,
# while preserving any custom Analytics already on the Plan.

# The script does the following:
#
# - Obtains an access token.
# - Performs a GetPlan query that returns all Analytics currently associated
#   with the target Plan.
# - Performs a listAnalytics query that returns a list of all available
#   Analytics.
# - Updates the target Plan with all current Jamf Analytics, as well as any
#   custom Analytics previously associated with the Plan, using the
#   setPlanAnalytics mutation.

# Keep the following in mind when using this script:
#
# - You must define the PROTECT_INSTANCE, CLIENT_ID, PASSWORD, and PLAN_ID variables to
#   match your Jamf Protect environment. The PROTECT_INSTANCE variable is your
#   tenant name (eg. your-tenant), which is included in your tenant URL (eg.
#   https://your-tenant.protect.jamfcloud.com).
# - This script requires the 3rd party Python library 'requests'

import requests

PROTECT_INSTANCE = ""
CLIENT_ID = ""
PASSWORD = ""
PLAN_ID = 


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


GET_PLAN_QUERY = """
    query getPlan($id: ID!) {
        getPlan(id: $id) {
            name
            analytics {
                name
                jamf
                uuid
            }
        }
    }
"""

LIST_ANALYTICS_QUERY = """
    query listAnalytics{
        listAnalytics{
            items {
                name
                description
                severity
                jamf
                uuid
            }
        }
    }
"""

SET_PLAN_ANALYTICS_QUERY = """
    mutation setPlanAnalytics($id: ID!, $input: PlanAnalytics!) {
        setPlanAnalytics(id: $id, input: $input) {
            analytics {
                name
            }
        }
    }
"""


def __main__():

    # Get the access token
    access_token = get_access_token(PROTECT_INSTANCE, CLIENT_ID, PASSWORD)

    # Get all available Analytics
    resp = make_api_call(PROTECT_INSTANCE, access_token, LIST_ANALYTICS_QUERY)

    jamf_analytics_dict = {
        a["uuid"]: a for a in resp["data"]["listAnalytics"]["items"] if a["jamf"]
    }

    # Get Analytics associated with the Plan
    variables = {"id": PLAN_ID}
    resp = make_api_call(PROTECT_INSTANCE, access_token, GET_PLAN_QUERY, variables)

    plan_name = resp["data"]["getPlan"]["name"]
    current_plan_jamf_analytics = [
        a["uuid"] for a in resp["data"]["getPlan"]["analytics"] if a["jamf"]
    ]
    current_plan_custom_analytics = [
        a["uuid"] for a in resp["data"]["getPlan"]["analytics"] if not a["jamf"]
    ]

    # Check for new Jamf Analytics to add
    new_jamf_analytics = set(jamf_analytics_dict).difference(
        current_plan_jamf_analytics
    )

    if not new_jamf_analytics:

        print(f"No new Jamf Analytics to add to Plan '{plan_name}'.")
        return

    print(f"Adding the following Jamf analytics to Plan '{plan_name}':")
    for count, a_uuid in enumerate(new_jamf_analytics):
        new_analytic = jamf_analytics_dict[a_uuid]
        print(
            f"  {count}. {new_analytic['name']} ({new_analytic['severity']}): {new_analytic['description']}"
        )

    # Associate the new set of Analytics with the Jamf Protect Plan
    variables = {
        "id": PLAN_ID,
        "input": {
            "analytics": list(jamf_analytics_dict.keys())
            + current_plan_custom_analytics
        },
    }

    resp = make_api_call(PROTECT_INSTANCE, access_token, SET_PLAN_ANALYTICS_QUERY, variables)

    print("Done.")


if __name__ == "__main__":

    __main__()
