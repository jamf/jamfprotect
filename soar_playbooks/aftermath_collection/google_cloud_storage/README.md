# SOAR Playbook - Aftermath Collection (Google Cloud)

This SOAR playbook is provided to collect the output from an Aftermath Scan and upload it to an Google Cloud bucket.

## About Aftermath

Aftermath is a Swift-based, open-source incident response framework, available on Jamf's open source GitHub repository (https://github.com/jamf/aftermath).

Aftermath can be leveraged by defenders in order to collect and subsequently analyze the data from the compromised host. When deploying Aftermath via Jamf Pro, this script can be used in tandem with an Aftermath first run, ensuring the data is securely stored in a designated Google Cloud bucket once an Aftermath collection is complete.

## Workflow Steps

Steps to create the workflow:

- [ ] Jamf Pro - Upload [Aftermath.pkg](https://github.com/jamf/aftermath/releases) and deploy to endpoints
- [ ] Create [gcs_aftermath.pkg](#gcs_pkg) and upload to Jamf Pro 
- [ ] Jamf Protect - Analytics Smart Group Identifier configured
- [ ] Jamf Pro - Create a Smart Group populated by `Jamf Protect - Smart Groups` [Extension Attribute](https://docs.jamf.com/jamf-protect/documentation/Setting_Up_Analytic_Remediation_With_Jamf_Pro.html#task-7832) 
- [ ] Jamf Pro - Upload [aftermath_collection_gc.sh](./aftermath_collection_gc.sh)
- [ ] Jamf Pro - [Create Policies](#policies)
    - Aftermath Scan
    - Aftermath Collect
    - Google Cloud Aftermath Credentials

## Workflow Components
### Jamf Protect

Each Analytic must have the Add to Smart Group feature enabled. 

- Add to Jamf Pro Smart Group: **Checked**
    - Identifier: **aftermath**

### Jamf Pro
#### Smart Computer Group

|Display Name|Criteria|Operator|Value|
|------------|--------|--------|-----|
|Jamf Protect: Aftermath|Jamf Protect - Smart Groups|like|aftermath

####  <a id="policies"></a>Policies

|Name|Frequency|Trigger|Scope|Payload|
|----|---------|-------|-----|-------|
|**Aftermath Scan**|Ongoing|protect|Jamf Protect: Aftermath|`/usr/local/bin/aftermath --pretty; /usr/local/bin/jamf policy -event am_collect`
|**Aftermath Collect**|Ongoing|am_collect|All Managed Clients|aftermath_collection_gc.sh
|**Google Cloud Aftermath Credentials**|Ongoing|gcs_creds|All Managed Clients|gcs_aftermath.pkg

**Google Cloud Configuration**

- Create a Google Cloud Bucket and a service account with `Storage Object Creator` and `Storage Object Viewer` roles applied.
- Create <a id="gcs_pkg"></a>Google Cloud Configuration file:
    1. Install [Google Cloud CLI](https://cloud.google.com/storage/docs/gsutil_install)
    2. Configure Boto Configuration. Run the following in Terminal.app:
        - `/usr/local/google-cloud-sdk/bin/gsutil config -a`
    3. Use included makefile to create pkg. Run the following from within the project folder in Terminal.app:
        - `sudo make pkg`
    4. Copy gcs_aftermath.pkg to Jamf Pro.
    5. Clean up after upload complete. Run the following from within the project folder in Terminal.app:
        - `sudo make clean`
#
## Please note that all resources contained within this repository are provided as-is and are not officially supported by Jamf Support.