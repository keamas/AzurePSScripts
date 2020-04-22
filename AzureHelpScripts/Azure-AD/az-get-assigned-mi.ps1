<#
    .SYNOPSIS
        
    .DESCRIPTION
        
    .EXAMPLE
        
    .NOTES         
        
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("true", "false")]
    [string]
    $MIsfromTenant,
    [Parameter(Mandatory=$true)]
    [string]
    $TenantID

)

#######################################################################################################################
#region define global variables

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

#endregion
#######################################################################################################################

#######################################################################################################################
#region Functions

#login to azure and get access token
function Login-Azure()
{
    try 
    {
        if(-not (Get-Module Az.Accounts)) {
            Import-Module Az.Accounts
        }
    
        Connect-AzAccount -Tenant $TenantID              
    }
    catch {
        Write-Error "Error in function Login-Azure. Error message: $($_.Exception.Message)"
    }
}

function get-mis
{
    $csvlist =@()  

    #region Get VMs with MI assigned
    $vms = Get-AzVM | where {$_.Identity -ne $null}
    foreach ($vm in $vms)
    {
        $mirow = New-Object PSObject -Property @{
            Subscription = $subscription.Name
            ResourceGroup = $vm.ResourceGroupName        
            ResourceName = $vm.Name
            ResourceType = $vm.Type
            IdentityId = $vm.Identity.PrincipalId
        }

        $csvlist += $mirow
    }
    #endregion

    #region Get VMss with MI assigned
    $vmsss = Get-AzVMss | where {$_.Identity -ne $null}
    foreach ($vmss in $vmsss)
    {
        $mirow = New-Object PSObject -Property @{
            Subscription = $subscription.Name
            ResourceGroup = $vmss.ResourceGroupName        
            ResourceName = $vmss.Name
            ResourceType = $vmss.Type
            IdentityId = $vmss.Identity.PrincipalId
        }

        $csvlist += $mirow
    }
    #endregion

    #region Get WebApp/Functions with MI assigned
    $webapps = Get-AzWebApp | where {$_.Identity -ne $null}
    foreach ($webapp in $webapps)
    {
        $mirow = New-Object PSObject -Property @{
            Subscription = $subscription.Name
            ResourceGroup = $webapp.ResourceGroupName        
            ResourceName = $webapp.Name
            ResourceType = $webapp.Type
            IdentityId = $webapp.Identity.PrincipalId
        }

        $csvlist += $mirow
    }
    #endregion

    #region Get LogiApps with MI assigned
    $logicapps = Get-AzResource -ResourceType Microsoft.Logic/workflows | where {$_.Identity -ne $null}
    foreach ($logicapp in $logicapps)
    {
        $mirow = New-Object PSObject -Property @{
            Subscription = $subscription.Name
            ResourceGroup = $logicapp.ResourceGroupName        
            ResourceName = $logicapp.Name
            ResourceType = $logicapp.Type
            IdentityId = $logicapp.Identity.PrincipalId
        }

        $csvlist += $mirow
    }
    #endregion

    #region Get Service Fabric with MI assigned
    $servicefabrics = Get-AzServiceFabricCluster | where {$_.Identity -ne $null}
    foreach ($servicefabric in $servicefabrics)
    {
        $mirow = New-Object PSObject -Property @{
            Subscription = $subscription.Name
            ResourceGroup = $servicefabric.ResourceGroupName        
            ResourceName = $servicefabric.Name
            ResourceType = $servicefabric.Type
            IdentityId = $servicefabric.Identity.PrincipalId
        }

        $csvlist += $mirow
    }
    #endregion


    $csvlist | Select-Object Subscription,ResourceGroup,ResourceName,ResourceType,IdentityId | export-csv -path $("C:\temp\$($subscription.Id).csv") -NoTypeInformation    
}

#endregion
#######################################################################################################################


#######################################################################################################################
#region Script start

    Write-Host "Connect to Azure"
    Login-Azure

    #region section select subscription
    try 
    {            
        $subscriptions = Get-AzSubscription -TenantId $TenantID | where {$_.Name -ne "Zugriff auf Azure Active Directory"}

        if ((($subscriptions).count -gt 0) -and ($MIsfromTenant -eq "false"))
        {
            Write-Host "#######################################################################"
            Write-Host "There are more subscription available:"

            $count = 0
            foreach ($subscription in $subscriptions) 
            {
                Write-Host "$($count): $($subscription.Name)"
                $count++
            }

            Write-Host "Please select the right subscription (insert the number)"
            Write-Host "#######################################################################"
            $result = Read-Host

            $selectedsubscription = $subscriptions[$result]
            Select-AzSubscription -SubscriptionObject $selectedsubscription            
            get-mis               
        }
        elseif ((($subscriptions).count -eq 1)) 
        {
            $selectedsubscription = $subscriptions[0]
            Select-AzSubscription -SubscriptionObject $selectedsubscription
            get-mis
        }
        else 
        {
            foreach ($subscription in $subscriptions)
            {
                Select-AzSubscription -SubscriptionObject $subscription
                get-mis
            }
        }
    }
    catch {
        Write-Error "Error in select subscription section. Error message: $($_.Exception.Message)"
    }

    #endregion

#endregion
#######################################################################################################################
