# Microsoft Azure Sentinel
The files contained in this repository provides example workbooks and queries for Microsoft Azure Sentinel with having Jamf Protect as data source.

**Steps to use example workbooks contained within this repository:**

1. Navigate to _https://portal.azure.com_
2. Navigate to Azure Sentinel
3. Navigate to the Sentinel Workspace that is being used for Jamf Protect
4. Navigate to Workbooks and continuing in My Workbooks
5. Click on + Add Workbook
6. Click Edit and in the button bar on the top navigate to the advanced editor `</>`
7. Copy and Paste all data below the # JSON Representation here
8. Once copied into Advanced Editor, hit CMD+F or CNTR+F and replace jamfprotect_CL with your custom Log Type name and _CL. (You can find the Log Type Name in Jamf Protect -> Administrative -> Data -> Microsoft Sentinel -> Log Type)
9. Hit Apply and Done Editing
10. You can now view or link to this dashboard by clicking View My Dashboard

![](siem_examples/Microsoft Azure Sentinel/.Microsoft_Azure_Sentinel_Workbook.png)


**Steps to use example Analytics contained within this repository:**

1. Open the .json file with your preferred text editor and find and replace jamfprotect_CL with your custom Log Type Name. (You can find the Log Type Name in Jamf Protect -> Administrative -> Data -> Microsoft Sentinel -> Log Type) and save the file. 
2. Navigate to _https://portal.azure.com_
3. Navigate to Azure Sentinel
4. Navigate to the Sentinel Workspace that is being used for Jamf Protect
5. Navigate to Analytics
6. Click on the import button in the top menu bar
7. Select the Analytic .JSON file you want to import and click Upload

![](siem_examples/Microsoft Azure Sentinel/.Microsoft_Azure_Sentinel_Incidents.png)

## Please note that all resources contained within this repository are provided as-is and are not officially supported by Jamf Support.