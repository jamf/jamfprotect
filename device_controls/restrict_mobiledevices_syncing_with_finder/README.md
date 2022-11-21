# Disable iOS/iPadOS devices from syncing with Finder on macOS

In this repository we provide information and examples on restricting iOS and iPadOS devices from syncing with Finder on macOS Catalina and later.

Since the release of macOS Catalina (10.15) the Finder has replaced iTunes as one of the ways to sync devices with a Mac, this feature provides browsing and accessing data from your device on your Mac and also allows Finder to sync data between the device and the Mac.

In some scenarios you want to prevent data being transmitted from the Mac to the mobile device using the Finder Sync to prevent the loss of organisational data.

If you want to learn more about syncing devices with Finder you can do so [here](https://support.apple.com/en-gb/HT210611) or read more on this [Jamf technical article](https://docs.jamf.com/technical-articles/Disabling_Data_Syncing_between_Computers_and_Apple_Devices.html)

Disabling iOS and iPadOS devices from syncing with Finder will restrict and prevent the following functionalities:

* Mounting devices in Finder menubar either through Wi-Fi and connected with a USB cable.
* Restrict the following syncing features
	* Syncing Albums, songs, playlists, films, TV shows, podcasts, books and audiobooks, Photos and videos, Contacts and calendars.
	* Manually copying over files from the Mac to the mobile device

Although setting the disablement, the following functionalities will remain working:

* Attaching the mobile device to the Mac to use Console to read device logs
* Attaching the mobile device to the Mac to use it with Apple Configurator 2
* Syncing data with 3rd party tools
* Charging the attached mobile device


Steps to restrict Finder sync on a Mac:

- Download the .mobileconfiguration profile contained within this repository
- Upload the .mobileconfiguration profile in to Jamf Pro or a other MDM solution
- Scope out this Configuration Profile to the Macs where you want to disable this feature.

**Disclaimer:** All resources contained in this repository are provided as-is and are not officially supported by Jamf Support.