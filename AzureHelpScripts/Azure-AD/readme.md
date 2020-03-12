# Script az-ad-exportenterpriseapps.ps1
That scipt export all Azure Enterprise applications with the following settings:
    * ServicePrincipalName
    * Enabled
    * UserAssigmentRequired
    * Members
    * App Permission
    * Delegate Permissions

## Parameters for script: az-ad-exportenterpriseapps.ps1
I've add the following required parameters to the script:

    * TenantID > Please insert the Azure AD TenantID (Sample: c1021507-78e3-2044-b3d-476ae7b152f8)
    * ExporttoJSON > It's possible to export the result into a JSON file. (Stored C:\temp\AppReport.json)
    * ExporttoHTML > It's possible to export the result into a HTML file. (Stored C:\temp\AppReport.html)
    * ExporttoCSV > It's possible to export the result into a CSV file. (Stored C:\temp\AppReport.csv)

Sample: 
    az-ad-exportenterpriseapps.ps1 -ExporttoJSON true
                                   -ExporttoHTML true
                                   -ExporttoCSV true

### Prerequisites for script: az-ad-exportenterpriseapps.ps1
The following modules are required:
    
    * AzureAD


---------------------------------------------------------------------------------------------------------------
# Script: az-ad-exportcloudonlyusers.ps1
That scipt export all Azure Cloud only users with the following settings:
    * Name
    * UPN
    * UserType
    * Enabled
    * MemberOf
    * DirectoryRoles
    * AppRoles

## Parameters for script: az-ad-exportcloudonlyusers.ps1
I've add the following required parameters to the script:

    * ExporttoJSON > It's possible to export the result into a JSON file. (Stored C:\temp\AppReport.json)
    * ExporttoHTML > It's possible to export the result into a HTML file. (Stored C:\temp\AppReport.html)
    * ExporttoCSV > It's possible to export the result into a CSV file. (Stored C:\temp\AppReport.csv)

Sample: 
    az-ad-exportcloudonlyusers.ps1 -ExporttoJSON true
                                   -ExporttoHTML true
                                   -ExporttoCSV true

### Prerequisites for script: az-ad-exportcloudonlyusers.ps1
The following modules are required:
    
    * AzureAD

---------------------------------------------------------------------------------------------------------------
# Script: xxx.ps1

## Parameters for script: xxx.ps1

### Prerequisites for script: xxx.ps1


---------------------------------------------------------------------------------------------------------------

# Script: xxx.ps1

## Parameters for script: xxx.ps1

### Prerequisites for script: xxx.ps1


---------------------------------------------------------------------------------------------------------------

### Authors
Hannes Lagler-Gruener