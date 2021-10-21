# Unified Log Filtering
The Unified Logging system available in macOS 10.12 or later provides a central location to store log data on the Mac. The Console and Terminal apps allow users to view, stream, and filter this data on computers to manually troubleshoot errors or detect threats.

With Jamf Protect, you can use the same predicate-based filter criteria that are often used with the log command to collect relevant log entries from computers and send them to a security information and event management (SIEM) solution or a third party storage solution (e.g., AWS).

**Important Requirement:** To collect unified log filter data with Jamf Protect, you must do one of the following:
* Integrate Jamf Protect with a security information and events management (SIEM) solution.
* Enable data forwarding to a third party storage solution

More information on this feature can be found [here](https://docs.jamf.com/jamf-protect/documentation/Unified_Logging.html).

## Unified Log Filters
Within this repository are many predicate filters that can be used to stream telemetry on a variety of events across macOS.  Filters are available for macOS user, system and network activity, as well as from third-party applications including Jamf Connect and Jamf Pro.

## Implementing Unified Log Filters in Jamf Protect from this repository
The process for implementing these filters in Jamf Protect is straight forward:
1. Ensure you are able to meet one of the above two requirements for using this feature
2. Copy the predicate from the Unified Log Filter object in this repository
3. Create a new Filter object in Jamf Protect (Unified Logging > Add New Filter) and paste the predicate in the Filter field
4. Add a name and tags as desired

**See the [Jamf Protect Wiki](https://github.com/jamf/jamfprotect/wiki/Unified-Log-Filtering) for more information on testing with Unified Log filters, as well as dealing with private data from the Unified Log**

#
## Please note that all resources contained within this repository are provided as-is and are not officially supported by Jamf Support.
