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