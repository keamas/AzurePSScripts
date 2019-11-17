# Project Control Azure AD Role
Cosumter request to control Azure AD Roles with On-Prem Active Directory Groups.

## Getting Started
These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites
To implement that project in ylou live system you need the following components:

* [Azure Automation Account](https://azure.microsoft.com/de-de/services/automation/) - 500 Runbook minutes per month are free
* [Automation RunAs Account](https://docs.microsoft.com/en-us/azure/automation/manage-runas-account) - Create a RunAs account durring creation
* Global Admin permissions for Automation RunAs Account
* On-Prem Active Directory groups for Azure AD mapping
* [Configured AD-Connect](https://docs.microsoft.com/en-us/azure/active-directory/hybrid/how-to-connect-install-roadmap) - Sync your On-Prem Active Directory Groups and Users to Azure AD
* Configure the mapping inside the script
* The following powershell modules should be imported into Azure Automation: AzureAD, AzureRM.Profile   

### Installation
All prerequisits are in place, so we can start with the implementation.

#### Update the Azure Automation modules
It's important that you use the newest PowerShell Module versions.
Implement the [Update Script](https://github.com/your/project/tags) 
#### Create a Runbook
First create a Runbook in Azure Automation (Type: Powershell Script)
Add the Source code to the Runbook

#### AD Group to Azure AD Role mapping
Define the Active Directory Group to Azure AD Role mapping. ***Important*** The Active Diretory groups and their users should be synced to Azure AD!

The source code have a region "Define global variables". This region includes the following source code:
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
which represent the Active Directory Group to Azure AD Role mapping. 