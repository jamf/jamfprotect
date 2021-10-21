# SOAR Playbooks
The SOAR playbooks contained within this repository are workflows designed to be executed on an endpoint by Jamf Pro, in response to an analytic detection Jamf Protect.  This is achieved through the remediation integration between the two products, detailed [here](https://docs.jamf.com/jamf-protect/documentation/Setting_Up_Analytic_Remediation_With_Jamf_Pro.html).

**Leveraging this integration requires the endpoint to be enrolled in both Jamf Protect as well as a Jamf Pro environment.**

The general flow of the operations that occur through this operation is as follows:
1. A security event occurs on an endpoint
1. The event is detected by Jamf Protect's analytic feature
1. The Jamf Protect agent executes an action as a result of the positive detection that results in the endpoint being placed into a Smart Computer Group in Jamf Pro, whereby now it is eligible for scoping inclusion or exclusion of management objects such as Policies or Configuration Profiles
1. The Jamf Pro management framework will proactively check for and execute pending management actions from these features

#
## Please note that all resources contained within this repository are provided as-is and are not officially supported by Jamf Support.
