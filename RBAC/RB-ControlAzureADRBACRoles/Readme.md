# Project Control Azure AD role
i've got many customer requests, to control Azure Active Directory Roles with On-Prem Active Directory groups.
This script is working with AzureAD Groups synced from On-Prem and Cloud native too.

## Getting Started
These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites
To implement that project in your live system, the following prerequisits are required:

* [Azure Automation Account](https://azure.microsoft.com/de-de/services/automation/) - 500 Runbook minutes per month are for free
* [Automation RunAs Account](https://docs.microsoft.com/en-us/azure/automation/manage-runas-account) - Create a RunAs account durring the creation
* [Configured AD-Connect](https://docs.microsoft.com/en-us/azure/active-directory/hybrid/how-to-connect-install-roadmap) - Sync your On-Prem Active Directory groups and users to AzureAD

### Installation
All prerequisits are in place, so we can start with the implementation.

#### Update and import the required Azure Automation modules
It's important, that you use the newest PowerShell module versions.
Implement the [Update Script](https://github.com/laglergruener/AzurePSScripts/tree/master/RBAC/RB-ControlAzureADRBACRoles/UpdateModule) 

Then import the AzureAD module into your Azure Automation account

#### Assign global admin permissions to the RunAs account
Durring the Azure Automation deployment you've created an Azure Automation RunAs account.
The required permissions for that account, the global admin role.

To achive that requironments, use the following powershell code:

````
Connect-AzureAD
$group = Get-AzureADDirectoryRole | Where-Object DisplayName -EQ "Company Administrator"
$sp = Get-AzureADServicePrincipal | Where-Object AppId -EQ "YourAppID"
Add-AzureADDirectoryRoleMember -ObjectId $group.ObjectId -RefObjectId $sp.ObjectId

````

In real production scenarios, please define a seperate RunAs account!

#### Create a Runbook
Next create a runbook in Azure Automation (From type: Powershell Script)
Add the published source code to the runbook

#### AD Group to AzureAD Role mapping
Create an AzureAd group (On-Prem or cloud native) for your role mapping.
Add the AzureAD group to the AzureAD role mapping. 
***Important*** The Active Diretory groups and their users should be synced to AzureAD if you use the On-Prem scenario!

The source code have a region "Define global variables". This region contains the following source code:
````
#Define Hashtable for Group to Role Mapping
    $grouprolemapping = @{
                            "" = "Company Administrator"
                            "" = "Helpdesk Administrator"
                            "" = "User Account Administrator"
                            "" = "Billing Administrator"
                            "" = "Intune service administrator"
                            "" = "SharePoint Service Administrator"
                            "" = "Service Support Administrator"
                            "" = "Lync Service Administrator"
                            "" = "License Administrator"
                         }

````
which represent the AzureAD Group to AzureAD role mapping. 
***Important*** there are AzureAD roles and AzureAD role templates in AzureAD available. This script only supports AzureAD roles.
If you want to map an AzureAD group to an AzureAD role template, you have to convert the template to a role!

***Important*** Before you execute the script, please enable the debug modus (Script region: "Define global variables")

````
 $debugscript = $true
````

Here is a sample output:

````
Start Script at 11/17/2019 09:36:51

Connect to Azure AD


Account      : 12345-4321-64te-asf4-fsdfsdfdsfdsfsf
Environment  : AzureCloud
Tenant       : 12212221-1212-1121-1212-121313131313
TenantId     : 12212221-1212-1121-1212-121313131313
TenantDomain : sample.onmicrosoft.com

Get Directory Role members for Role Helpdesk Administrator

No Role member


Get Azure AD Group members for group GRP-HelpDeskAdmin

demouser1@sample.at

demouser2@sample.at


Execute Function Add User to Group

Add User demouser1@sample.at to Directory Role Helpdesk Administrator

Debug Mode Active!

Add User demouser2@sample.at to Directory Role Helpdesk Administrator

Debug Mode Active!

------------------------------------------------------------------------
````

### Authors
Hannes Lagler-Gruener

### Future Versions
* Outsource the mapping into a azure storage table
* Outsource the "Global Variables" into Azure Automation varibles
* Write logging intormation into Azure Log Analytics too (better for monitoring)

