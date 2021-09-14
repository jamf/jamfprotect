#!/usr/bin/env python3

# This example Python script below does the following:
# - Obtains an access token.
# - Completes a listComputers query request that returns computers that have not checked in during a defined time range.
# - For each returned computer, prompts the user to decide if they want to delete the computer from Jamf Protect using a deleteComputer mutation.

# Keep the following in mind when using this script:
# - You must define the PROTECT_INSTANCE, CLIENT_ID, and PASSWORD variables to match your Jamf Protect environment. The PROTECT_INSTANCE variable is your tenant name (e.g., your-tenant), which is included in your tenant URL (e.g., https://your-tenant.protect.jamfcloud.com).
# - Running this example script in your environment may delete computers and data stored in the Jamf Protect Cloud. Make sure to test this script before using it in a production environment.
# - This example script leverages the requests Python library python3.
 
# After the script runs, you should receive an output that prompts you to delete or keep each computer that has not checked in with Jamf Protect since the date defined in the script. For each prompt, you can enter y to delete the computer or n to keep the computer in Jamf Protect.

# > python example_1.py
# Access token granted, valid for 1281 minutes.
# Found 3 computers matching filter.
# 
# Delete computer 'Tamara Newton's Mac' (last checkin 2020-08-17T02:41:00.907839Z)? y/N n
# Skipping deletion of 'Tamara Newton's Mac.
# Delete computer 'Carrie Mcdowell's Mac' (last checkin 2020-08-12T02:56:20.145733Z)? y/N y
# Deleted computer 'Carrie Mcdowell's Mac'.
# Delete computer 'Ryan Gamble's Mac' (last checkin 2020-07-14T02:14:36.420006Z)? y/N n
# Skipping deletion of 'Ryan Gamble's Mac.
# Done.

 
import datetime
import requests
 
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
 
    resp = requests.post(api_url, json=payload, headers=headers,)
    resp.raise_for_status()
    return resp.json()
 
 
LIST_COMPUTERS_QUERY = """
    query listComputers(
      $checkin_cutoff: AWSDateTime
      $page_size: Int
      $next: String
    ) {
      listComputers(
        input: {
          filter: { checkin: { lessThan: $checkin_cutoff } }
          pageSize: $page_size
          next: $next
        }
      ) {
        items {
          uuid
          hostName
          checkin
        }
        pageInfo {
          next
        }
      }
    }
    """
 
DELETE_COMPUTER_QUERY = """
    mutation deleteComputer($uuid: ID!) {
      deleteComputer(uuid: $uuid) {
        hostName
      }
    }
    """
 
 
def __main__():
 
    # Get the access token
    access_token = get_access_token(PROTECT_INSTANCE, CLIENT_ID, PASSWORD)
 
    # Get list of UUIDs of Computers that have not checked in in the past 12 weeks
    cutoff_weeks = 12
    cutoff_date = datetime.datetime.now() - datetime.timedelta(weeks=cutoff_weeks)
 
    next_token = None
    computers = []
    page_count = 1
 
    print("Retrieving paginated results:")
 
    while True:
        print(f"  Retrieving page {page_count} of results...")
 
        vars = {
            "checkin_cutoff": cutoff_date.isoformat() + "Z",
            "page_size": 100,
            "next": next_token,
        }
 
        resp = make_api_call(PROTECT_INSTANCE, access_token, LIST_COMPUTERS_QUERY, vars)
        next_token = resp["data"]["listComputers"]["pageInfo"]["next"]
        computers.extend(resp["data"]["listComputers"]["items"])
 
        if next_token is None:
            break
 
        page_count += 1
 
    print(f"Found {len(computers)} computers matching filter.\n")
 
    # Iterate through returned Computers, prompting user before deletion for each
    for computer in computers:
 
        user_resp = input(
            f"Delete computer '{computer['hostName']}' (last checkin {computer['checkin']})? y/N "
        )
 
        if user_resp.lower() != "y":
            print(f"Skipping deletion of '{computer['hostName']}.")
            continue
 
        variables = {"uuid": computer["uuid"]}
 
        # Delete the individual Computer (including all associated Logs and Alerts)
        resp = make_api_call(
            PROTECT_INSTANCE, access_token, DELETE_COMPUTER_QUERY, variables
        )
 
        print(f"Deleted computer '{resp['data']['deleteComputer']['hostName']}'.")
 
    print("Done.")
 
 
if __name__ == "__main__":
 
    __main__()
