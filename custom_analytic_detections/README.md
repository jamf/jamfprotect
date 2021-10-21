# Custom Analytic Detections
Jamf Protect's Analytics feature provide the ability to generically detect sensitive, suspicious or malicious behaviour on Mac endpoints through logical analysis of events occurring across the system.

In addition to the Analytics provided and managed by Jamf's Detections Team, customers are able to create and deploy Custom Analytics with the same feature functionality to meet the audit trail and threat hunting needs specific to the evironment.

Contained within this repository are predicates that can be used to create Custom Analytics that offer extended visibility and detection of events across macOS.  Within each Custom Analytic object is:
* A predicate expression
* The required Sensor Event Type
* The recommended Analytic Level setting
* The recommended Severity

More information on each of these settings can be found [here](https://docs.jamf.com/jamf-protect/documentation/Analytics.html).

## Creating a Custom Analytic in Jamf Protect from this repository
Instructions for creating a Custom Analytic using the resources in this repository can be found [here](https://docs.jamf.com/jamf-protect/documentation/Creating_Analytics.html).

When creating a Custom Analytic from this repository it is helpful to use the **Filter Text View** option inside the Analytic Filter builder to simply paste in the predicate expression rather than build it using the Filter Query Builder View.

#
## Please note that all resources contained within this repository are provided as-is and are not officially supported by Jamf Support.
