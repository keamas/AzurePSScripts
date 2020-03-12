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
# Script: az-ad-user-findownergroups.ps1
That scipt export all Azure Enterprise applications with the following settings:
    * Username
    * Groupname

## Parameters for script: az-ad-user-findownergroups.ps1
I've add the following required parameters to the script:

    * ExporttoJSON > It's possible to export the result into a JSON file. (Stored C:\temp\AppReport.json)
    * ExporttoHTML > It's possible to export the result into a HTML file. (Stored C:\temp\AppReport.html)
    * ExporttoCSV > It's possible to export the result into a CSV file. (Stored C:\temp\AppReport.csv)

Sample: 
    az-ad-user-findownergroups.ps1 -ExporttoJSON true
                                   -ExporttoHTML true
                                   -ExporttoCSV true

### Prerequisites for script: az-ad-user-findownergroups.ps1
The following modules are required:
    
    * AzureAD


---------------------------------------------------------------------------------------------------------------

### Authors
Hannes Lagler-Gruener