# Jamf Protect API
The Jamf Protect API is the primary resource for programmatically interacting with Jamf Protect. The Jamf Protect API uses GraphQL, an advanced query service and language that allows you to search and access your data from a single endpoint.

To learn more about GraphQL, see the [Introduction to GraphQL](https://graphql.org/learn) page on the GraphQL Foundation website.

Documentation on the Jamf Protect API can be found [here](https://docs.jamf.com/jamf-protect/documentation/Jamf_Protect_API.html).

## Jamf Protect API Script Dependencies
There are a few dependencies that must be met in order to run the Python scripts within this repository, with each only needing to be done once per host machine or script.  They are:
1) Creating an API Client within your Jamf Protect tenant
2) Editing the saved script and filling in the required variables with the API Client details
3) Installing Python3
4) Installing the third-party Python library **requests**

See below for instructions on completing each of the above.

### Jamf Protect API Client
An API Client must be created within Jamf Protect in order to interface with the Jamf Protect GraphQL API.  See the [Jamf Protect Documentation](https://docs.jamf.com/jamf-protect/documentation/Jamf_Protect_API.html) for guidance on creating one within your Jamf Protect tenant.

The API Client created may be used by other scripts and tools and offers administrative access to your tenant so be sure to **securely** record the Client ID and Password details for future use.

### Script Variables
Each script contained within this repository requires three variables to be configured appropriately in order to run successfully.  They can be found at the top of each script and are:  
PROTECT_INSTANCE = ""  
CLIENT_ID = ""  
PASSWORD = ""  

You must define the PROTECT_INSTANCE, CLIENT_ID, and PASSWORD variables in the provided scripts to match your Jamf Protect environment. 
- The PROTECT_INSTANCE variable is your tenant name (e.g., your-tenant), which is included in your tenant URL (e.g., https://your-tenant.protect.jamfcloud.com)
- The CLIENT_ID variable is the identifier of the API Client created within your Jamf Protect tenant
- The PASSWORD variable is the password used to authenticate to the API Client created within your Jamf Protect tenant

### Python3
The scripts within this section are written in Python and require Python 3 to run successfully.  There are two easy installation methods available for Python 3:
1) Using [Homebrew](https://brew.sh), by running `brew install python3`
2) A direct installation package from [python.org](https://www.python.org/downloads/macos/)

### **requests** Library
The Python scripts within this repository utilise the third-party Python library **requests**.  Running this script without the **requests** library installed will result in the following error: `ModuleNotFoundError: No module named 'requests'`

**Installing the requests library**  
The **requests** library can be installed by opening Terminal.app (/Applications/Utilities/Terminal.app) on your Mac, after Python3 has been installed, and running this command:  
`pip3 install requests`
  
A successful installation should end in the following:  
`Installing collected packages: requests
Successfully installed requests-XX.XX.XX`

## How to run these Python scripts
Once the dependencies above have been met you will be able to run these Python scripts with the following steps:
1) Obtain a copy of the desired .py script on your Mac (either by cloning this repository locally or simply copying the script contents into a local .py file)
2) Open Terminal.app from within /Applications/Utilities/
3) Run this command:  
`python3 /path/to/desired_script.py`

### What format is used for files created by these scripts?
The output format for each script can be found as a variable (`XXXX_OUTPUT_FILE`) within the script itself, named similar to `JSON_OUTPUT_FILE` or `CSV_OUTPUT_FILE`.

### Where are the exported reports and files saved?
Files created by these scripts will be saved in the **current working directory** from which you ran them.  To find your current working directory in Terminal.app simply run `pwd` (the default working directory will be /Users/username/).
#
## Please note that all resoruces contained within this repository are provided as-is and are not officially supported by Jamf Support.
