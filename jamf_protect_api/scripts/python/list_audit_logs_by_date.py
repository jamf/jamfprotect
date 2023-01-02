#!/usr/bin/env python3

# This example Python script lists audit logs in a specified date range.

# The script does the following:
#
# - Obtains an access token.
# - Lists audit log records in a specific date range, using the
#   listAuditLogsByDate query.

# Keep the following in mind when using this script:
#
# - You must define the PROTECT_INSTANCE, CLIENT_ID, and PASSWORD variables to
#   match your Jamf Protect environment. The PROTECT_INSTANCE variable is your
#   tenant name (eg. your-tenant), which is included in your tenant URL (eg.
#   https://your-tenant.protect.jamfcloud.com).
# - There are two required arguments that must be passed when running the script,
#   -s/--start and -e/--end.
# - Optional arguments:
#   -d/--direction specifies order direction, 'ASC' or 'DESC'
#   -p/--page specifies page size limits, ex. 100
#   -n/--next provides a next token if one was supplied from a previous query
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


LIST_AUDIT_LOGS_BY_DATE = """
    query listAuditLogsByDate($input: AuditLogsDateQueryInput){
        listAuditLogsByDate(input: $input) {
            items {
                date
                args
                error
                ips
                op
                user
                resourceId
            }
            pageInfo {
                next
                total
            }
        }
    }
"""


def create_args():
    parser = argparse.ArgumentParser(
        description="List Audit Logs in a specified date range."
    )
    parser.add_argument(
        "-s",
        "--start",
        default=None,
        help="Start Date in AWSDateTime format, ex. '2022-11-07T22:53:15.951Z'",
        required=True,
    )
    parser.add_argument(
        "-e",
        "--end",
        default=None,
        help="End Date in AWSDateTime format, ex. '2022-11-07T22:53:15.951Z'",
        required=True,
    )
    parser.add_argument(
        "-d",
        "--direction",
        default="ASC",
        help="Direction of chronological order; 'ASC' or 'DESC'",
        required=False,
    )
    parser.add_argument(
        "-n",
        "--next",
        default=None,
        help="Next Token if implementing pagination",
        required=False,
    )
    parser.add_argument(
        "-p",
        "--page",
        default=None,
        help="Page size limit if implementing pagination",
        required=False,
    )
    return parser.parse_args()


def __main__():

    args = create_args()

    START_DATE = args.start
    END_DATE = args.end
    NEXT = args.next
    PAGE_SIZE = args.page
    DIRECTION = args.direction.upper()
    if DIRECTION not in ["ASC", "DESC"]:
        print("Order direction must be 'ASC' or 'DESC'. Please try again.")
        sys.exit(1)

    # Get the access token
    access_token = get_access_token(PROTECT_INSTANCE, CLIENT_ID, PASSWORD)

    # Set variables for graphql query
    variables = {
        "input": {
            "next": NEXT,
            "order": {
                "direction": DIRECTION,
            },
            "condition": {
                "dateRange": {
                    "startDate": START_DATE,
                    "endDate": END_DATE,
                }
            },
            "pageSize": PAGE_SIZE,
        }
    }

    # Make API call
    resp = make_api_call(
        PROTECT_INSTANCE, access_token, LIST_AUDIT_LOGS_BY_DATE, variables
    )
    print(f"Audit Logs generated between {START_DATE} and {END_DATE}:")
    print(resp)
    next_token = resp["data"]["listAuditLogsByDate"]["pageInfo"]["next"]
    print(f"\nNext token: {next_token}")


if __name__ == "__main__":

    __main__()
