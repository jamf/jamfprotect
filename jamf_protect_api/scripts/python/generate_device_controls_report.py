#!/usr/bin/env python3

# This example Python script below does the following:
# - Obtains an access token.
# - Completes a listAlerts query request that returns all alerts reported to Jamf
#   Protect during a defined time range, with filtering by eventType auth-mount.
# - Creates a CSV file

# Keep the following in mind when using this script:
# - You must define the PROTECT_INSTANCE, CLIENT_ID, and PASSWORD variables to
#   match your Jamf Protect environment. The PROTECT_INSTANCE variable is your
#   tenant name (eg. your-tenant), which is included in your tenant URL (eg.
#   https://your-tenant.protect.jamfcloud.com).
# - This script requires the 3rd party Python library 'requests'


import sys, json, requests, csv, os, datetime as dt
from datetime import datetime

PROTECT_INSTANCE = ""
CLIENT_ID = ""
PASSWORD = ""


CSV_OUTPUT_FILE = (
    f"Jamf_Protect_Device_Controls_Alerts_{datetime.utcnow().strftime('%Y-%m-%d')}.csv"
)


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
    print(payload)
    headers = {"Authorization": access_token}
    resp = requests.post(
        api_url,
        json=payload,
        headers=headers,
    )
    print(resp)
    resp.raise_for_status()
    return resp.json()


LIST_ALERTS_QUERY = """
        query listAlerts(
            $created_cutoff: AWSDateTime
            $event_type: String
            $page_size: Int 
            $next: String
        ) {
            listAlerts(
                input: {
                    filter: {
                        eventType: { equals: $event_type },
                        and: {
                        created: { greaterThan: $created_cutoff }
                    }}
                    pageSize: $page_size
                    next: $next
                }
            ) {
                items {
                        json
                        eventType
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

    if not all([PROTECT_INSTANCE, CLIENT_ID, PASSWORD]):
        print("ERROR: Variables PROTECT_INSTANCE, CLIENT_ID, and PASSWORD must be set.")
        sys.exit(1)

    # Get the access token
    access_token = get_access_token(PROTECT_INSTANCE, CLIENT_ID, PASSWORD)

    cutoff_days = 30
    cutoff_date = dt.datetime.now() - dt.timedelta(days=cutoff_days)

    results = []
    next_token = None
    page_count = 1

    print("Retrieving paginated results:")

    while True:
        print(f"  Retrieving page {page_count} of results...")
        vars = {
            "event_type": "auth-mount",
            "created_cutoff": cutoff_date.isoformat() + "Z",
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
    print(f"Writing results to '{CSV_OUTPUT_FILE}'")
    data_file = open(CSV_OUTPUT_FILE, "w", newline="")
    csv_writer = csv.writer(data_file)
    headers = [
        "Timestamp"
        "eventTimestamp",
        "HostName",
        "Serial",
        "Vendor",
        "Vendor ID",
        "Product",
        "Product ID",
        "Device Serial",
        "Encrypted",
        "Action",
    ]
    csv_writer.writerow(headers)
    for o in results:
        raw_json = json.loads(o["json"])
        hostname = raw_json["host"]["hostname"]
        serial = raw_json["host"]["serial"]
        vendorname = raw_json["match"]["event"]["device"]["vendorName"]
        vendorid = raw_json["match"]["event"]["device"]["vendorId"]
        productname = raw_json["match"]["event"]["device"]["productName"]
        productid = raw_json["match"]["event"]["device"]["productId"]
        devicesn = raw_json["match"]["event"]["device"]["serialNumber"]
        isencrypted = raw_json["match"]["event"]["device"]["isEncrypted"]
        action = (
            raw_json["match"]["actions"][0]["name"]
            + ", "
            + raw_json["match"]["actions"][1]["name"]
            + " & "
            + raw_json["match"]["actions"][2]["name"]
        )
        time = raw_json["match"]["event"]["timestamp"]
        eventTimestamp = json.loads(o["eventTimestamp"])
        timestamp = datetime.utcfromtimestamp(time).strftime("%Y-%m-%d %H:%M:%S")

        row = [
            timestamp,
            eventTimestamp,
            hostname,
            serial,
            vendorname,
            vendorid,
            productname,
            productid,
            devicesn,
            isencrypted,
            action,
        ]

        csv_writer.writerow(row)
    data_file.close()
    print("done")


if __name__ == "__main__":
    __main__()
    