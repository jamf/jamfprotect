# SIEM Examples

Jamf Protect supports the following methods of providing a 3rd party security information and events management solutions (SIEM) with data attributes, this provides value to IT and Security teams that are using a SIEM to collect all kinds of data points into a single solution.

* Transmit Alert and Unified Log data forwarded by the Jamf Protect cloud to the organizations Amazon S3 bucket or Microsoft Sentinel workspace
* Transmit Alert and Unified Log data direct from the endpoint to the organizations SIEM via HTTPS

The SIEM Examples contained within this repository are examples of queries, workbooks, or dashboards that can be used in a SIEM helping visualising data transmitted by Jamf Protect, the examples provided are helping getting started with mapping data points from Jamf Protect in to the SIEM solution.

**Important Requirement:** In order to forward data from Jamf Protect to a security information and events management system (SIEM):
* Integrate Jamf Protect with a SIEM.
* Enable data forwarding to a third party storage solution

The general flow of the operations that occur through this operation is as follows:
1. A Alert, Unified Log Filter or Telemetry stream is captured by Jamf Protect
2. The event data is either being forwarded from Protect Cloud to the SIEM or from direct the macOS endpoint to the SIEM, depending on the chosen integration.

In this repository you will find examples for:
- [ ] Microsoft Sentinel
- [ ] Soon to be added - Splunk

**Disclaimer:** All resources contained in this repository are provided as-is and are not officially supported by Jamf Support.