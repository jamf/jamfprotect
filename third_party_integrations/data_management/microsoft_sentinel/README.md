# Microsoft Sentinel
The files contained in this repository provides example workbooks and queries for Microsoft Sentinel with having Jamf Protect as data source.

**Steps to use example workbooks contained within this repository:**

1. Navigate to _https://portal.azure.com_
2. Navigate to Microsoft Sentinel
3. Navigate to the Sentinel Workspace that is being used for Jamf Protect
4. Navigate to Workbooks and continuing in My Workbooks
5. Click on + Add Workbook
6. Click Edit and in the button bar on the top navigate to the advanced editor `</>`
7. Copy and Paste all data below the # JSON Representation here
8. Once copied into Advanced Editor, hit CMD+F or CNTR+F and replace jamfprotect_CL with your custom Log Type name and _CL. (You can find the Log Type Name in Jamf Protect -> Administrative -> Data -> Microsoft Sentinel -> Log Type)
9. Hit Apply and Done Editing
10. You can now view or link to this dashboard by clicking View My Dashboard

![](https://github.com/jamf/jamfprotect/blob/task/28_09_22_siem_examples/third_party_integrations/data_management/microsoft_sentinel/Images/.Microsoft_Sentinel_Workbook_white.png)


**Steps to use example Analytics contained within this repository:**

1. Open the .json file with your preferred text editor and find and replace jamfprotect_CL with your custom Log Type Name. (You can find the Log Type Name in Jamf Protect -> Administrative -> Data -> Microsoft Sentinel -> Log Type) and save the file. 
2. Navigate to _https://portal.azure.com_
3. Navigate to Microsoft Sentinel
4. Navigate to the Sentinel Workspace that is being used for Jamf Protect
5. Navigate to Analytics
6. Click on the import button in the top menu bar
7. Select the Analytic .JSON file you want to import and click Upload

![](https://github.com/jamf/jamfprotect/blob/task/28_09_22_siem_examples/third_party_integrations/data_management/microsoft_sentinel/Images/.Microsoft_Sentinel_Incidents_white.png)

**Disclaimer:** All resources contained in this repository are provided as-is and are not officially supported by Jamf Support.