## Jamf Pro Extension Attributes
Scripted Extension Attributes in Jamf Pro allow IT teams to extend the native inventory capabilities of the product with customisable data collection to achieve powerful, advanced workflows for the environment.

More information regarding using Extension Attributes in Jamf Pro can be found [here](https://docs.jamf.com/10.32.0/jamf-pro/administrator-guide/Computer_Extension_Attributes.html).

## Using Extension Attributes to report on the Jamf Protect installation
This repository contains many Extension Attribute scripts that can be used to include information about the Jamf Protect installation on an endpoint in the standard inventory submission sent to Jamf Pro.  This information can be used for both reporting but also with Smart Grouping to create dynamic workflows based upon the status of Jamf Protect on that endpoint.

For example, the **[Jamf Protect - Quarantined Files](https://github.com/jamf/jamfprotect/blob/main/custom_analytic_detections/ThreatPreventionFileQuaratine)** Extension Attribute can be used to report on endpoints that have quarantined files present in Jamf Protect's quarantine directory.

To leverage this Extension Attribute simply:
1. Navigate to Jamf Pro > Settings > Computer Management > Extension Attributes and create a new object
2. Input the required settings from the Extension Attribute in this repository and save

The next time endpoints submit inventory to Jamf Pro they will now report 'yes' or 'no' depending on whether there are files present in the `/Library/Application Support/JamfProtect/Quarantine` directory.

#
## Please note that all resources contained within this repository are provided as-is and are not officially supported by Jamf Support.
