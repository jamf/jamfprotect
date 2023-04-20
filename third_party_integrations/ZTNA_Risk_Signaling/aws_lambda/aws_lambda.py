#!/usr/bin/env python3

import json
import base64
import requests

######################
# 	  VARIABLES    #
######################

# Jamf Private Access
private_access_url = 'https://api.wandera.com'

# # for when a device falls into the smart group on Jamf Pro, choices are HIGH, MEDIUM, LOW, SECURE
# set_risk_level = 'HIGH'
# # for when a device falls out of the smart group setting device back to SECURE, other choices are HIGH, MEDIUM, LOW
# clear_risk_level = 'SECURE'

# Application type
content_type = 'application/json'

########################################################
# Do Not Modify below this Line ########################
########################################################
persistent = requests.Session()


def create_jamf_token(jamf_pro_url, jamf_pro_username, jamf_pro_password):
    print('Attempting to auth to Jamf Pro for API Token')
    jamf_pro_auth = jamf_pro_username + ':' + jamf_pro_password
    jamf_pro_base64 = base64.b64encode(jamf_pro_auth.encode()).decode()
    jamf_pro_token_url = f'{jamf_pro_url}/uapi/auth/tokens'
    auth_headers = {
        "Authorization": 'Basic ' + jamf_pro_base64,
        "Content-Type": content_type,
        "Accept": content_type
    }
    jamf_pro_token_request = persistent.post(jamf_pro_token_url, headers=auth_headers)
    jamf_pro_token_request_status_code = jamf_pro_token_request.status_code
    if jamf_pro_token_request_status_code != 200:
        print(f'Unable to contact Jamf Pro for Auth token {jamf_pro_token_request_status_code}')
        return False

    jamf_pro_token = jamf_pro_token_request.json()
    jamf_pro_token = jamf_pro_token['token']
    return jamf_pro_token


def create_radar_token(application_id, application_secret):
    print('Attempting to Auth for Private Access Token')
    private_access_auth = f'{application_id}:{application_secret}'
    private_access_token_url = f'{private_access_url}/v1/login'
    private_access_auth_base64 = base64.b64encode(private_access_auth.encode()).decode()
    auth_headers = {
        "Authorization": f'Basic {private_access_auth_base64}',
        "Content-Type": content_type,
        "Accept": content_type
    }
    private_access_token_request = persistent.post(private_access_token_url, headers=auth_headers)
    private_access_token_request_status_code = private_access_token_request.status_code
    if private_access_token_request_status_code != 200:
        print(f'Unable to contact Radar for Auth token {private_access_token_request_status_code}')
        return False
    private_access_token = private_access_token_request.json()['token']
    return private_access_token


def get_jamf_device_info(jamf_pro_url, jamf_api_token, jamf_device_id):
    print('Getting Device UDID from Jamf Pro')
    jamf_pro_device_url = f'{jamf_pro_url}/JSSResource/computers/id/{jamf_device_id}'
    device_headers = {
        "Authorization": f'Bearer {jamf_api_token}',
        "Content-Type": content_type,
        "Accept": content_type
    }
    jamf_pro_device_request = persistent.get(jamf_pro_device_url, headers=device_headers)
    jamf_pro_device_response = jamf_pro_device_request.json()
    jamf_pro_device_udid = jamf_pro_device_response['computer']['general']['udid']

    jamf_pro_device_json = {
        "device_udid": jamf_pro_device_udid,
    }
    # print(jamf_pro_device_udid)
    return jamf_pro_device_json


def get_private_access_device(private_api_token, jamf_udid):
    print('Using Device UDID from Jamf Pro to retrieve Private Access device ID')
    # we need to set the Jamf udid to lowercase
    jamf_udid = jamf_udid.lower()
    private_access_device_url = f'{private_access_url}/risk/v1/devices'
    device_headers = {
        "Authorization": f'Bearer {private_api_token}',
        "Content-Type": content_type,
        "Accept": content_type
    }
    private_access_device_request = persistent.get(private_access_device_url, headers=device_headers)
    private_access_devices = private_access_device_request.json()['records']
    for device in private_access_devices:
        private_access_external_id = device['externalId']
        if private_access_external_id == jamf_udid:
            private_access_device_id = device['deviceId']
            return private_access_device_id
        else:
            return False

def update_private_access_risk(private_api_token, private_access_id, risk_level):
    print(f'Attempting to set device {private_access_id} to risk level {risk_level}')
    if risk_level == 'SECURE':
        source = 'WANDERA'
    else:
        source = 'MANUAL'
    private_access_device_url = f'{private_access_url}/risk/v1/override'
    device_headers = {
        "Authorization": f'Bearer {private_api_token}',
        "Content-Type": content_type,
        "Accept": content_type
    }
    json_body = {
        "risk": risk_level,
        "source": source,
        "deviceIds": [
            private_access_id
        ]
    }
    device_override_request = persistent.put(private_access_device_url, headers=device_headers, json=json_body)
    device_override_request_status_code = device_override_request.status_code
    if device_override_request_status_code != 204:
        print(f'Error Setting device risk of {risk_level} for {private_access_id} with response code {device_override_request_status_code}')
        return False
    return device_override_request


# default response from AWS Lambda
def lambda_handler(event, context):
    # read out the content from the Webhook including headers as variables
    webhook_header = event['headers']
    print('Attempting to reach header contents from Jamf Pro Webhook')
    try:
        jamf_pro_url = webhook_header['jamf_pro_url']
        jamf_pro_username = webhook_header['jamf_pro_username']
        jamf_pro_password = webhook_header['jamf_pro_password']
        private_access_application_id = webhook_header['private_access_application_id']
        private_access_application_secret = webhook_header['private_access_application_secret']
        set_risk_level = webhook_header['set_risk_level']
        clear_risk_level = webhook_header['clear_risk_level']
    except KeyError:
        print('One or more keys are missing from the webhook headers')
        return {
            'statusCode': 400,
            'body': json.dumps('Missing webhook headers')
        }
    # Parse out the webhook body
    webhook_body = event['body']
    # as it is nested JSON we need to load it before we can parse it
    webhook_json = json.loads(webhook_body)
    try:
        device_added_id_array = webhook_json['event']['groupAddedDevicesIds']
        device_removed_id_array = webhook_json['event']['groupRemovedDevicesIds']
    except KeyError:
        print('Unexpected Webhook Body, please check the webhook trigger')
        return {
            'statusCode': 400,
            'body': json.dumps('Missing webhook body')
        }

    jamf_token = create_jamf_token(jamf_pro_url, jamf_pro_username, jamf_pro_password)
    if jamf_token is False:
        print('Unable to authenticate to Jamf Pro, please check the api username and password set in the webhook header')
        return {
            'statusCode': 400,
            'body': json.dumps('Error Authenticating to Jamf Pro')
        }
    private_access_token = create_radar_token(private_access_application_id,
                                              private_access_application_secret)
    if private_access_token is False:
        print('Unable to authenticate to Private Access, please check the api username and password set in the webhook header')
        return {
            'statusCode': 400,
            'body': json.dumps('Error Authenticating to Private Access')
        }

    for device_id in device_added_id_array:
        print(f'Taking action {set_risk_level} on device {device_id}')
        jamf_pro_device_data = get_jamf_device_info(jamf_pro_url, jamf_token, device_id)
        try:
            jamf_device_udid = jamf_pro_device_data['device_udid']
        except KeyError:
            print(f'No Valid device UDID found for JSS ID {device_id}')
            return {
                'statusCode': 400,
                'body': json.dumps(f'No Valid device UDID found for JSS ID {device_id}')
            }

        private_access_device_id = get_private_access_device(private_access_token, jamf_device_udid)
        if private_access_device_id is False:
            print(f'No Valid device found for JSS ID {device_id} on Private Access')
            return {
                'statusCode': 400,
                'body': json.dumps(f'No Valid device found for JSS ID {device_id} on Private Access')
            }

        override_device = update_private_access_risk(private_access_token, private_access_device_id,
                                                     set_risk_level)
        if override_device is False:
            print(f'Unable to set Risk level for JSS ID {device_id}')
            return {
                'statusCode': 400,
                'body': json.dumps(f'Unable to set Risk level for JSS ID {device_id}')
            }

    for device_id in device_removed_id_array:
        print(f'Taking action {clear_risk_level} on device JSS ID {device_id}')
        jamf_pro_device_data = get_jamf_device_info(jamf_pro_url, jamf_token, device_id)
        try:
            jamf_device_udid = jamf_pro_device_data['device_udid']
        except KeyError:
            print(f'No Valid device UDID found for {device_id}')
            return {
                'statusCode': 400,
                'body': json.dumps(f'No Valid device UDID found for JSS ID {device_id}')
            }

        private_access_device_id = get_private_access_device(private_access_token, jamf_device_udid)
        if private_access_device_id is False:
            print(f'No Valid device found for JSS ID {device_id} on Private Access')
            return {
                'statusCode': 400,
                'body': json.dumps(f'No Valid device found for {device_id} on Private Access')
            }

        override_device = update_private_access_risk(private_access_token, private_access_device_id,
                                                     clear_risk_level)
        if override_device is False:
            print(f'Unable to set Risk level for JSS ID {device_id}')
            return {
                'statusCode': 400,
                'body': json.dumps(f'Unable to set Risk level for JSS ID {device_id}')
            }

    return {
        'statusCode': 200,
        'body': json.dumps('Webhook successfully executed')
    }