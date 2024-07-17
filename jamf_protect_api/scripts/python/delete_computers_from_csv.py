#!/usr/bin/env python3

import requests
import csv
import json

PROTECT_INSTANCE = "" # x.protect.jamfcloud.com - The variable should be x and not the whole URL.
CLIENT_ID = ""
PASSWORD = ""

# Fill in path to .csv on line 71

def get_access_token(protect_instance, client_id, password):
    """Gets a reusable access token to authenticate requests to the Jamf Protect API"""
    token_url = f"https://{protect_instance}.protect.jamfcloud.com/token"
    payload = {"client_id": client_id, "password": password}
    resp = requests.post(token_url, json=payload)
    resp.raise_for_status()
    resp_data = resp.json()
    print(f"Access token granted, valid for {int(resp_data['expires_in'] // 60)} minutes.")
    return resp_data["access_token"]

def make_api_call(protect_instance, access_token, query, variables=None):
    """Sends a GraphQL query to the Jamf Protect API, and returns the response."""
    if variables is None:
        variables = {}
    api_url = f"https://{protect_instance}.protect.jamfcloud.com/graphql"
    payload = {"query": query, "variables": variables}
    headers = {
        "Authorization": access_token,
        "Content-Type": "application/json"
    }
    response = requests.post(api_url, json=payload, headers=headers)
    response.raise_for_status()
    return response.json()

LIST_COMPUTERS_QUERY = """
    query listComputers($page_size: Int, $next: String) {
      listComputers(input: { pageSize: $page_size, next: $next }) {
        items {
          uuid
          hostName
          serial
          checkin
        }
        pageInfo {
          next
        }
      }
    }
    """

DELETE_COMPUTER_MUTATION = """
    mutation deleteComputer($uuid: ID!) {
      deleteComputer(uuid: $uuid) {
        hostName
      }
    }
    """

def load_serial_numbers(file_path):
    with open(file_path, mode='r') as file:
        csv_reader = csv.reader(file)
        return [row[0].strip().upper() for row in csv_reader if row]

def __main__():
    # Get the access token
    access_token = get_access_token(PROTECT_INSTANCE, CLIENT_ID, PASSWORD)

    # Load serial numbers from the CSV file
    serial_numbers_file = ""  # Update with the path to your file
    serial_numbers = load_serial_numbers(serial_numbers_file)

    next_token = None
    computers = []
    page_count = 1

    print("Retrieving paginated results:")

    while True:
        print(f"  Retrieving page {page_count} of results...")

        vars = {"page_size": 100, "next": next_token}

        resp = make_api_call(PROTECT_INSTANCE, access_token, LIST_COMPUTERS_QUERY, vars)
        next_token = resp["data"]["listComputers"]["pageInfo"]["next"]
        computers.extend(resp["data"]["listComputers"]["items"])

        if next_token is None:
            break

        page_count += 1

    print(f"Found {len(computers)} computers in total.\n")

    # Filter computers by the list of serial numbers
    computers_to_delete = [comp for comp in computers if comp['serial'] in serial_numbers]

    print(f"Found {len(computers_to_delete)} computers matching the provided serial numbers.\n")

    # Iterate through filtered Computers, deleting each by UUID
    for computer in computers_to_delete:
        variables = {"uuid": computer["uuid"]}
        resp = make_api_call(PROTECT_INSTANCE, access_token, DELETE_COMPUTER_MUTATION, variables)
        print(f"Deleted computer '{resp['data']['deleteComputer']['hostName']}'.")

    print("Done.")

if __name__ == "__main__":
    __main__()