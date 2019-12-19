<#
    .SYNOPSIS
        
    .DESCRIPTION
        
    .EXAMPLE
        
    .NOTES  
        
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Connect-AzAccount

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


#region Custom role for DCS Onboarding

    #Get exist role
    $role = (Get-AzRoleDefinition "Azure.RBAC.VMDscOnboardCustom")
    $role.Actions.Clear()

    #Add permission to custom RBAC role
    $role.Actions.Add("Microsoft.Automation/automationAccounts/*/read")
    #$role.Actions.Add("Microsoft.OperationalInsights/workspaces/write")
    #$role.Actions.Add("Microsoft.Automation/automationAccounts/nodes/read")
    #$role.Actions.Add("Microsoft.Automation/automationAccounts/compilationjobs/read")
    #$role.Actions.Add("Microsoft.Automation/automationAccounts/compilationjobs/read")

    #Remove permission from custom role
    #$role.Actions.Remove()

    #Add new role to subscription
    Set-AzRoleDefinition -Role $role

#endregion



