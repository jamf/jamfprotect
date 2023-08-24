# Unified Log Filtering
The Unified Logging system available in macOS 10.12 or later provides a central location to store log data on the Mac. The Console and Terminal apps allow users to view, stream, and filter this data on computers to manually troubleshoot errors or detect threats.

With Jamf Protect, you can use the same predicate-based filter criteria that are often used with the log command to collect relevant log entries from computers and send them to a security information and event management (SIEM) solution or a third party storage solution (e.g., AWS).

> [!NOTE]  
> Please refer to [Jamf Protect Telemetry](https://learn.jamf.com/bundle/jamf-protect-documentation/page/Telemetry.html) if you are collecting specific data from endpoints, it might be that event data you need is already collected by Telemetry.


> [!IMPORTANT]  
> To collect unified log filter data with Jamf Protect, you must do one of the following:
> * Integrate Jamf Protect with a security information and events management (SIEM) solution.
> * Enable data forwarding to a third party storage solution


More information on this feature can be found [here](https://docs.jamf.com/jamf-protect/documentation/Unified_Logging.html).

## Unified Log Filters
Within this repository are many predicate filters that can be used to stream telemetry on a variety of events across macOS.  Filters are available for macOS user, system and network activity, as well as from third-party applications including Jamf Connect and Jamf Pro.

## Implementing Unified Log Filters in Jamf Protect from this repository
There are two methods for implementing these filters in to Jamf Protect after you ensured you meet the requirements for using this feature:

1. Use the Open Source [Jamf Protect Unified Logging Filter Uploader](https://github.com/red5coder/jamf-protect-ulf-uploader) to import them into Jamf Protect

Or alternatively 

1. Copy the predicate from the Unified Log Filter object in this repository
2. Create a new Filter object in Jamf Protect (Unified Logging > Add New Filter) and paste the predicate in the Filter field
3. Add a name and tags as desired

## Enabling Private Data from the Unified Log
By default the Unified Log will redact information deemed to be sensitive, generally that which will identify a computer or user.  In some cases, such as that in which the computer is a corporately owned and managed device, there may be a need to ascertain such information and as such, private data logging can be enabled through a configuration profile.  See [this Jamf blog](https://www.jamf.com/blog/unified-logs-how-to-enable-private-data/) for instructions on doing so.

Data from the Unified Log that has been redacted can be identified by the presence of `<private>` in the returned log entry.  An example entry in the Unified Log for a password change where the data has been redacted would be:

`Password changed for <private>`

The same string returned on a device with private data logging enabled would be:

`Password changed for your-username`

**See the [Jamf Protect Wiki](https://github.com/jamf/jamfprotect/wiki/Unified-Log-Filtering) for more information on testing with Unified Log filters.**

#
## Please note that all resources contained within this repository are provided as-is and are not officially supported by Jamf Support.
