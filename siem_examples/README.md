# SIEM Examples

Jamf Protect supports forwarding data to 3rd party security information and events management solutions (SIEM), this provides value to IT and Security teams that are using a SIEM to collect all kinds of data points into a single solution.

The SIEM Examples contained within this repository are examples of queries, workbooks, or dashboards that can be used in a SIEM helping visualising data transmitted by Jamf Protect, the examples provided are helping getting started with mapping data points from Jamf Protect in to the SIEM solution.

**Important Requirement:** In order to forward data from Jamf Protect to a security information and events management system (SIEM):
* Integrate Jamf Protect with a SIEM.
* Enable data forwarding to a third party storage solution

The general flow of the operations that occur through this operation is as follows:
1. A Alert, Unified Log Filter or Telemetry stream is captured by Jamf Protect
2. The event data is either being forwarded from Protect Cloud to the SIEM or from direct the macOS endpoint to the SIEM, depending on the chosen integration.

In this repository you will find examples for:
- [ ] Microsoft Azure Sentinel
- [ ] Soon to be added - Splunk

**Disclaimer:** All resources contained in this repository are provided as-is and are not officially supported by Jamf Support.