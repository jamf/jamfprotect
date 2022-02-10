#!/usr/bin/env python3

# This example Python script below does the following:
# - Obtains an access token.
# - Completes a GetPlan query request that returns a list of Custom Analytics
#   added to the desired plan.
# - Completes a listAnalytics query request that returns a list of all Jamf Analytics.
# - Combines the Jamf and Custom Analytics and adds them to the desired plan with the
#   setPlanAnalytics mutation.

# Keep the following in mind when using this script:
# - You must define the PROTECT_INSTANCE, CLIENT_ID, PASSWORD, and PLAN_ID variables to
#   match your Jamf Protect environment. The PROTECT_INSTANCE variable is your
#   tenant name (eg. your-tenant), which is included in your tenant URL (eg.
#   https://your-tenant.protect.jamfcloud.com).
# - This script requires the 3rd party Python library 'requests'

import requests
import datetime

PROTECT_INSTANCE = ""
CLIENT_ID = ""
PASSWORD = ""
PLAN_ID = ""

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

GET_PLAN = """query getPlan($id: ID!) {
        getPlan(id: $id) {
        analytics {
            name
            jamf
            uuid
        }
    }
    }
    """
 
LIST_ANALYTICS_QUERY = """query {
        listAnalytics{
            items {
                name
                created
                jamf
                uuid
            }
        }
    }
    """

SET_PLAN_ANAlYTICS = """
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

    # Get list of UUIDs of Analytics created by Jamf
    resp = make_api_call(PROTECT_INSTANCE, access_token, LIST_ANALYTICS_QUERY)

    uuid = []
    for item in resp['data']['listAnalytics']['items']:
        if item['jamf']:
            uuid.append(item['uuid'])

    # Get list of UUIDs of Custom Analytics
    variables = {
        "id": PLAN_ID,
    }

    resp = make_api_call(PROTECT_INSTANCE, access_token, GET_PLAN, variables)

    custom_uuid = []
    for item in resp['data']['getPlan']['analytics']:
            if not item['jamf']: 
                custom_uuid.append(item['uuid'])
                
    # Combine Jamf Analytics with Custom Analytics
    uuid.extend(custom_uuid)

    # Add Analytics to Jamf Protect Plan
    variables = {
        "id": PLAN_ID,
        "input": {"analytics":uuid}
    }

    resp = make_api_call(
        PROTECT_INSTANCE, access_token, SET_PLAN_ANAlYTICS, variables
    )
    for r in resp['data']['setPlanAnalytics']['analytics']:
        print(f"Added analytics '{r['name']}' to {PLAN_ID}.")

    print("Done.")

if __name__ == "__main__":
 
    __main__()