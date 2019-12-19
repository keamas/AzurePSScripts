<#
    .SYNOPSIS
        
    .DESCRIPTION
        
    .EXAMPLE
        
    .NOTES  
        
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Connect-AzAccount

#region Custom role for DCS Onboarding

    ################################################
    #
    # In my workshops, the attendee's has to onboard
    # a VM to a Azure DSC account. They need the min.
    # of permissions to that account. With that custom
    # RBAC I archive that solution
    #
    ################################################

    #Get exist role
    $role = (Get-AzRoleDefinition "Network Contributor")

    #Reset unused parameters
    $role.Id = $null
    $role.Name = "Azure.RBAC.VMDscOnboardCustom"
    $role.Description = "Custom Permission to onboad VM into Azure Automation DSC"
    $role.Actions.Clear()
    $role.AssignableScopes.Clear()

    #Add custom permission to new RBAC role
    $role.Actions.Add("Microsoft.Resources/deployments/*")
    $role.Actions.Add("Microsoft.Resources/subscriptions/resourceGroups/write")
    $role.Actions.Add("Microsoft.Automation/automationAccounts/read")
    $role.Actions.Add("Microsoft.OperationalInsights/workspaces/intelligencepacks/read")
    #$role.Actions.Add("Microsoft.OperationalInsights/workspaces/write")
    #$role.Actions.Add("Microsoft.Automation/automationAccounts/write")
    $role.Actions.Add("Microsoft.Insights/register/action")
    $role.Actions.Add("Microsoft.Automation/automationAccounts/nodes/write")

    #Assign subscription
    $role.AssignableScopes.Add("/subscriptions/bb8e13db-cd67-4923-8aea-a4d66b65cf84")

    #Add new role to subscription
    New-AzRoleDefinition -Role $role

#endregion

#region Custom role for VNet Peering
    
    ################################################
    #
    # If you don't have permission to the destination
    # subscription where you wan't to create a 
    # VNet peering, use this custom RBAC to archive
    #
    ################################################

    #Get exist role
    $role = (Get-AzRoleDefinition "Network Contributor")

    #Reset unused parameters
    $role.Id = $null
    $role.Name = "Azure.RBAC.VNetPeeringCustom"
    $role.Description = "Custom Permission to assign VNetPeering"
    $role.Actions.Clear()
    $role.AssignableScopes.Clear()

    $role.Actions.Add("Microsoft.Network/VirtualNetworks/VirtualNetworkPeerings/write")
    $role.Actions.Add("Microsoft.Network/VirtualNetworks/VirtualNetworkPeerings/read")
    $role.Actions.Add("Microsoft.Network/virtualNetworks/peer/action")

    $role.AssignableScopes.Add("/subscriptions/bb8e13db-cd67-4923-8aea-a4d66b65cf84")
    New-AzRoleDefinition -Role $role

#endregion

#region Custom role for VM start and stop 

    ################################################
    #
    # If you don't have permission to the destination
    # subscription where you wan't to create a 
    # VNet peering, use this custom RBAC to archive
    #
    ################################################

    #Get exist role
    $role = (Get-AzRoleDefinition "Network Contributor")

    #Reset unused parameters
    $role.Id = $null
    $role.Name = "Azure.RBAC.VNetPeeringCustom"
    $role.Description = "Custom Permission to assign VNetPeering"
    $role.Actions.Clear()
    $role.AssignableScopes.Clear()

    

    $role.AssignableScopes.Add("/subscriptions/bb8e13db-cd67-4923-8aea-a4d66b65cf84")
    New-AzRoleDefinition -Role $role


#endregion



