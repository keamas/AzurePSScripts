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
    $PermissionfromTenant,
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

function collect-permission()
{
    $csvlist =@()    

    #region Collect Subscription Permission
    #$subscription.Name
    $SubPerms = Get-AzRoleAssignment -Scope $("/subscriptions/$($subscription.Id)") | where {$_.Scope -eq $("/subscriptions/$($subscription.Id)")} | Select-Object DisplayName,RoleDefinitionName,ObjectType 
    #$SubPerm

    foreach ($SubPerm in $SubPerms)
    {
        $subpermrow = New-Object PSObject -Property @{
                        Subscription = $subscription.Name
                        ResourceGroup = ""
                        ResourceName = ""
                        ResourceType = ""
                        RoleDisplayName = $SubPerm.DisplayName
                        RoleType = $SubPerm.RoleDefinitionName
                        Source = $SubPerm.ObjectType
                    }

        $csvlist += $subpermrow
    }

    #endregion


    #region Add single line
        $rgpermrow = New-Object PSObject -Property @{
            Subscription = ""
            ResourceGroup = ""
            ResourceName = ""
            ResourceType = ""
            RoleDisplayName = ""
            RoleType = ""
            Source = ""
        }

        $csvlist += $rgpermrow 
    #endregion

    #region Collect ResourceGroup and Resource Permissions
    $RGs = Get-AzResourceGroup

    foreach ($RG in $RGs)
    {
        $RGPerms = Get-AzRoleAssignment -Scope $RG.ResourceId | where {$_.Scope -eq $RG.ResourceId} | Select-Object DisplayName,RoleDefinitionName,ObjectType 

        #$RG.ResourceGroupName
        #$RGPerm

        if($null -ne $RGPerms)
        {
            foreach ($RGPerm in $RGPerms)
            {
                $rgpermrow = New-Object PSObject -Property @{
                                    Subscription = $subscription.Name
                                    ResourceGroup = $RG.ResourceGroupName
                                    ResourceName = ""
                                    ResourceType = ""
                                    RoleDisplayName = $RGPerm.DisplayName
                                    RoleType = $RGPerm.RoleDefinitionName
                                    Source = $RGPerm.ObjectType
                                }
                
                $csvlist += $rgpermrow
            }        
        }
        else {
            $rgpermrow = New-Object PSObject -Property @{
                Subscription = $subscription.Name
                ResourceGroup = $RG.ResourceGroupName
                ResourceName = ""
                ResourceType = ""
                RoleDisplayName = ""
                RoleType = ""
                Source = ""
            }

            $csvlist += $rgpermrow          
        }

        $RGRes = Get-AzResource -ResourceGroupName $RG.ResourceGroupName
        
        foreach ($Res in $RGRes)
        {
            try 
            {                                        
                $ResPerm = Get-AzRoleAssignment -Scope $Res.ResourceId | where {$_.Scope -eq $Res.ResourceId} | Select-Object DisplayName,RoleDefinitionName,ObjectType 

                if($null -ne $ResPerm)
                {
                    foreach ($ResPerm in $ResPerm)
                    {
                        $rspermrow = New-Object PSObject -Property @{
                                            Subscription = ""
                                            ResourceGroup = ""
                                            ResourceName = $Res.ResourceName
                                            ResourceType = $Res.ResourceType
                                            RoleDisplayName = $ResPerm.DisplayName
                                            RoleType = $ResPerm.RoleDefinitionName
                                            Source = $ResPerm.ObjectType
                                        }
                        
                        $csvlist += $rspermrow
                    }        
                }
                else {
                    $rspermrow = New-Object PSObject -Property @{
                        Subscription = ""
                        ResourceGroup = ""
                        ResourceName = $Res.ResourceName
                        ResourceType = $Res.ResourceType
                        RoleDisplayName = ""
                        RoleType = ""
                        Source = ""
                    }

                }
            }
            catch {
                $rspermrow = New-Object PSObject -Property @{
                    Subscription = ""
                    ResourceGroup = ""
                    ResourceName = $Res.ResourceName
                    ResourceType = $Res.ResourceType
                    RoleDisplayName = "Cannot get permission. Error: $($_.Exception.Message)"
                    RoleType = ""
                    Source = ""
                }
            }

            $csvlist += $rspermrow                      
        }

        #region Add single line
        $rgpermrow = New-Object PSObject -Property @{
            Subscription = ""
            ResourceGroup = ""
            ResourceName = ""
            ResourceType = ""
            RoleDisplayName = ""
            RoleType = ""
            Source = ""
        }

        $csvlist += $rgpermrow 
        #endregion
    }   

    #endregion
    
    $csvlist | Select-Object Subscription,ResourceGroup,ResourceName,ResourceType,RoleDisplayName,RoleType,Source | export-csv -path $("C:\temp\$($subscription.Id).csv") -NoTypeInformation    
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

        if ((($subscriptions).count -gt 0) -and ($PermissionfromTenant -eq "false"))
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
            collect-permission
        }
        elseif ((($subscriptions).count -eq 1)) 
        {
            $selectedsubscription = $subscriptions[0]
            Select-AzSubscription -SubscriptionObject $selectedsubscription
            collect-permission
        }
        else 
        {
            foreach ($subscription in $subscriptions)
            {
                Select-AzSubscription -SubscriptionObject $subscription
                collect-permission
            }
        }
    }
    catch {
        Write-Error "Error in select subscription section. Error message: $($_.Exception.Message)"
    }

    #endregion

#endregion
#######################################################################################################################
