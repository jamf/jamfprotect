#!/usr/bin/env python3

# This example Python script lists all audit logs and writes them to a csv.

# The script does the following:
#
# - Obtains an access token.
# - Creates a file `audit_log_data/<current_date_and_time>.csv` containing all
#   audit log records from the last time the script was run until now.
#   The first run of the script will retrieve all audit log records available.
# - Write to file `audit_log_data/previous_audit_log_run.txt` containing
#   the date and time of the script's previous run.

# Keep the following in mind when using this script:
#
# - You must define the PROTECT_INSTANCE, CLIENT_ID, and PASSWORD variables to
#   match your Jamf Protect environment. The PROTECT_INSTANCE variable is your
#   tenant name (eg. your-tenant), which is included in your tenant URL (eg.
#   https://your-tenant.protect.jamfcloud.com).
# - Requires the 3rd party Python library 'requests'.
# - Will not retrieve data more often than once per minute.
# - Will not download already downloaded log entries unless
#   `audit_log_data/previous_audit_log_run.txt` is deleted.
# - Jamf Protect only stores Audit Logs for 1 year.
# - Audit Logs are in UTC, so your local time is converted to UTC as well.

import os
import sys
import requests
import datetime as dt
import csv

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
            }
        }
    }
"""

FORMAT = "%Y-%m-%dT%H:%M"


def __main__():

    folder = "audit_log_data/"
    if not os.path.exists(folder):
        os.makedirs(folder)

    tracker_filename = os.path.join(folder, "previous_audit_log_run.txt")

    # Records are stored in UTC timezone
    now_object = dt.datetime.now(dt.timezone.utc)
    now_formatted = now_object.strftime(FORMAT)
    end_date = f"{now_formatted}:00.000Z"

    if os.path.exists(tracker_filename):
        with open(tracker_filename, "r") as tracker_read:
            start_date = tracker_read.readline()

    else:
        # Jamf Protect only stores data for 1 year, disregarding leap years
        one_year_ago = (now_object - dt.timedelta(days=365)).strftime(FORMAT)
        start_date = f"{one_year_ago}:00.000Z"

    if start_date == end_date:
        print("Script was run less than a minute ago. Please try again after a minute.")
        sys.exit(0)

    # Get the access token
    access_token = get_access_token(PROTECT_INSTANCE, CLIENT_ID, PASSWORD)

    items = []
    # Set dateRange for graphql query
    variables = {
        "input": {
            "condition": {
                "dateRange": {
                    "startDate": start_date,
                    "endDate": end_date,
                }
            }
        }
    }
    next_token = ""

    while next_token is not None:

        # Set next token for graphql query
        variables["input"]["next"] = next_token

        # Make API call
        resp = make_api_call(
            PROTECT_INSTANCE, access_token, LIST_AUDIT_LOGS_BY_DATE, variables
        )

        items.extend(resp["data"]["listAuditLogsByDate"]["items"])
        next_token = resp["data"]["listAuditLogsByDate"]["pageInfo"]["next"]

    filename = now_formatted
    filepath = os.path.join(folder, f"{filename}.csv")
    print(
        f"Audit Logs generated between {start_date} and {end_date}\nOutputting results to {filepath}"
    )

    with open(filepath, "w", newline="") as csv_data_file:
        fieldnames = ["date", "args", "error", "ips", "op", "user", "resourceId"]
        writer = csv.DictWriter(csv_data_file, fieldnames=fieldnames)

        writer.writeheader()
        writer.writerows(items)

    # Write current date and time to previous_audit_log_run
    with open(tracker_filename, "w") as tracker_write:
        tracker_write.write(end_date)


if __name__ == "__main__":

    __main__()
