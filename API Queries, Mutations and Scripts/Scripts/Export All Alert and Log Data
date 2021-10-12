#!/usr/bin/env python3

# This example Python script below does the following:
# - Obtains an access token.
# - Completes a listAlerts query request that returns all logs reported to Jamf Protect, with filtering by severity.
# - Exports all alert data in JSON format /tmp/ProtectAlerts.json

# Keep the following in mind when using this script:
# - You must define the PROTECT_INSTANCE, CLIENT_ID, and PASSWORD variables to match your Jamf Protect environment. The PROTECT_INSTANCE variable is your tenant name (e.g., your-tenant), which is included in your tenant URL (e.g., https://your-tenant.protect.jamfcloud.com).
# - This example script leverages the requests Python library python3.


import sys
import requests
import json

PROTECT_INSTANCE = ""
CLIENT_ID = ""
PASSWORD = ""

MIN_SEVERITY = "Low"  # Valid values: "Informational", "Low", "Medium", "High"
MAX_SEVERITY = "High"  # Valid values: "Informational", "Low", "Medium", "High"
JSON_OUTPUT_FILE = "/tmp/ProtectAlerts.json"


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


LIST_ALERTS_QUERY = """
        query listAlerts(
            $min_severity: SEVERITY
            $max_severity: SEVERITY
            $page_size: Int
            $next: String
        ) {
            listAlerts(
                input: {
                    filter: {
                        severity: { greaterThanOrEqual: $min_severity }
                        and: { severity: { lessThanOrEqual: $max_severity } }
                    }
                    pageSize: $page_size
                    next: $next
                }
            ) {
                items {
                        json
                        severity
                        computer {
                            hostName
                        }
                        created
                    }
                        pageInfo {
                                next
                    }
                }
            }
        """


def __main__():

    if not set({MIN_SEVERITY, MAX_SEVERITY}).issubset(
        {"Informational", "Low", "Medium", "High"}
    ):
        print(
            "ERROR: Unexpected value(s) for min/max severity. Expected 'Informational', 'Low', 'Medium', or 'High'."
        )
        sys.exit(1)

    if not all([PROTECT_INSTANCE, CLIENT_ID, PASSWORD]):
        print("ERROR: Variables PROTECT_INSTANCE, CLIENT_ID, and PASSWORD must be set.")
        sys.exit(1)

    # Get the access token
    access_token = get_access_token(PROTECT_INSTANCE, CLIENT_ID, PASSWORD)

    results = []
    next_token = None
    page_count = 1
    print("Retrieving paginated results:")
    while True:
        print(f"  Retrieving page {page_count} of results...")
        vars = {
            "min_severity": MIN_SEVERITY,
            "max_severity": MAX_SEVERITY,
            "page_size": 100,
            "next": next_token,
        }
        resp = make_api_call(PROTECT_INSTANCE, access_token, LIST_ALERTS_QUERY, vars)
        next_token = resp["data"]["listAlerts"]["pageInfo"]["next"]
        results.extend(resp["data"]["listAlerts"]["items"])
        if next_token is None:
            break
        page_count += 1
    print(f"Found {len(results)} alerts matching filter.\n")
    print(f"Writing results to '{JSON_OUTPUT_FILE}'")
    with open(JSON_OUTPUT_FILE, "w") as output:
        json.dump(results, output, sort_keys=True, indent=4)


if __name__ == "__main__":
    __main__()
