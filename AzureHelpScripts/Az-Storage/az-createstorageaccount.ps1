<#
    .SYNOPSIS
        
    .DESCRIPTION
        
    .EXAMPLE
        
    .NOTES  
        
#>

[CmdletBinding()]
param (
    [Parameter()]
    [TypeName]
    $ParameterName
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
    
        Connect-AzAccount               
    }
    catch {
        Write-Error "Error in function Login-Azure. Error message: $($_.Exception.Message)"
    }
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
        $subscriptions = Get-AzSubscription

        if (($subscriptions).count -gt 0)
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
        }
        else 
        {
            $selectedsubscription = $subscriptions[0]
            Select-AzSubscription -SubscriptionObject $selectedsubscription
        }
    }
    catch {
        Write-Error "Error in select subscription section. Error message: $($_.Exception.Message)"
    }

    #endregion

    #region
    #Create Storage Account with pse    

    $vnet_name = "vnet-test"
    $vnet_resourcegroup = "RG-TestDoka"
    $subnet_name = "AzWE-SUBN-DEV-PAAS-MYDOKA"
    $subnet_addressprefix = "10.251.132.0/24"

    $StrAccName = "stracctestdoka01"
    $StrAccRG = "RG-TestDoka"
    $Location = "West Europe"

    $virtualNetwork = Get-AzVirtualNetwork -ResourceGroupName $vnet_resourcegroup -Name $vnet_name

    #Configure Subnet delegation (at the moment needed by private service endpoint (preview) feature)
    $delegation = New-AzDelegation -Name "PseDelegation" -ServiceName "Microsoft.Web/serverFarms"

    #Add a new Subnet Configuration to exist Virtual Network
    $addsubnetconfig = Add-AzVirtualNetworkSubnetConfig -AddressPrefix $subnet_addressprefix -Name $subnet_name `
                                                        -ServiceEndpoint Microsoft.Web,Microsoft.Sql,Microsoft.KeyVault,Microsoft.Storage `
                                                        -Delegation $delegation -VirtualNetwork $virtualNetwork
    #Add new subnet
    $subnet = $virtualNetwork | Set-AzVirtualNetwork

    $subnetid = ($subnet.Subnets | Where-Object Name -EQ $subnet_name).Id

    #Create new Stracc with PSE
    $stracc = New-AzStorageAccount -Name $StrAccName -ResourceGroupName $StrAccRG `
                                   -Kind StorageV2 -SkuName Standard_LRS -Location $Location `
                                   -NetworkRuleSet (@{bypass="Logging,Metrics";
                                                      virtualNetworkRules=(@{VirtualNetworkResourceId=$subnetid;Action="allow"});
                                                      defaultAction="Deny"})

    #Update Stracc
    $straccupdate = Update-AzStorageAccountNetworkRuleSet -ResourceGroupName $StrAccRG -AccountName $StrAccName `
                                                          -Bypass Logging,Metrics -DefaultAction Deny `
                                                          -VirtualNetworkRule (@{VirtualNetworkResourceId=$subnetid;Action="allow"})

    #endregion

#endregion
#######################################################################################################################
