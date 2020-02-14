# Project RBAC ResourceGroup Permission Workflow
This project include an automation workflow, when a new Azure RessourceGroup (with a predefined naming schema) is created, the workflow create 
the predefined On-Prem groups in Active Directory and assign that groups after sync was successfull.

## Getting Started
These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites
To implement that project in ylou live system you need the following components:

* [Azure Automation Account](https://azure.microsoft.com/de-de/services/automation/) - 500 Runbook minutes per month are free
* [Azure Automation Hybrid Worker] (https://docs.microsoft.com/en-us/azure/automation/automation-hybrid-runbook-worker) - for production environment min. 3 hybrid worker should available
* [Automation RunAs Account](https://docs.microsoft.com/en-us/azure/automation/manage-runas-account) - Create a RunAs account durring creation
* [Configured AD-Connect](https://docs.microsoft.com/en-us/azure/active-directory/hybrid/how-to-connect-install-roadmap) - Sync your On-Prem Active Directory Groups and Users to Azure AD
* [Azure Log Analytics](https://azure.microsoft.com/de-de/services/monitor/?&ef_id=CjwKCAiA_MPuBRB5EiwAHTTvMUWMyDGo1F79aH80ha9X0IUuOY0TRhtQjGsPxB1uZelG8eXvJHDNuhoCg7MQAvD_BwE:G:s&OCID=AID2000054_SEM_EDnec3Ep&MarinID=EDnec3Ep_326090110929_azure%20log%20analytics_e_c__64531830149_aud-397602258452:kwd-359568735113&lnkd=Google_Azure_Brand&dclid=CjgKEAiA_MPuBRClpcrviYWejF4SJADQEM-2IcJ82gOUltHfI7qJKLWEjNRbs9J-em1KGh1A3kvSOvD_BwE) - To monitor the solutuion
* An user account which have the permission "Create/Move Active Directory Groups"

### Installation
All prerequisits are in place, so we can start with the implementation.

#### Update and import the required Azure Automation modules
It's important that you use the newest PowerShell Module versions.
Implement the [Update Script](https://github.com/laglergruener/AzurePSScripts/tree/master/RBAC/RB-ControlAzureADRBACRoles/UpdateModule) 

Import the modules:

* AzureRM
* Microsoft.OMS (from GitHub Repository)


into your Azure Automation Account

#### Create a new Azure Automation connection ressource 
After you import the custom module "Microsoft.OMS" you have a new connection variable type in you Azure Automation Account.
Please create new connection from type "Microsoft.OMS" with the name "AZLogAConProd".
Add the Azure Log Analytics WorkspaceID and the Azure Log Analytics SharedKey to the new connection.

#### Create a new Azure Automation Credential ressource
Create a new Azure Automation Credential ressource and add the Username (Domain\username) from your On-Prem environment how have the required permissions to Create/Move Active Directory Groups.

#### Install Hybrid Worker On-Prem
Install Azure Automation Hybrid Worker On-Prem and define a new Hybrid Worker Group.
***Important*** please install the following modules on each Hybrid Worker:
* AzureRM
* AzureAD

#### Create two Azure Automation Runbooks
Create the following Azure Automation Runbooks and add the source code from the GitHub repository:

* RB-Check-ResourceGroupPerm-Cloud.ps1
* RB-Check-ResourceGroupPerm-OnPrem.ps1

The Runbook "RB-Check-ResourceGroupPerm-Cloud.ps1" should run in "Azure" and the Runbook "RB-Check-ResourceGroupPerm-OnPrem.ps1" should run on the new defined Azure Automation Hybrid Worker Group!

