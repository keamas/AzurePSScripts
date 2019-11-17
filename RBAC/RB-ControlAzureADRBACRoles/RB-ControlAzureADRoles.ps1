 ###########################################################################################################
#
#       Author: Hanens Lagler-Gruener
#       Job Description: CLoud Solutions Architect
#       Company: -
#       Created: 
#
#
#
#       Important prerq:
#                       
#
#       Script details:
#                 
#                 
###########################################################################################################


######################################################################################################################################    
    #region Define global variables

    $global:debuglog = ""
    $global:changelog = ""
    $debugscript = $true

    $spconnection = Get-AutomationConnection -Name "AzureRunAsConnection"

    #Engel Tenant
    $AppCertThumprint = $spconnection.CertificateThumbprint
    $ApplicationID = $spconnection.ApplicationId
    $TenantIT = $spconnection.TenantId

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

    [string[]]$ExcludefromDirectoryRoleremove = @("","")

    #endregion
######################################################################################################################################

try
{
######################################################################################################################################
    #region functions

    function function_connectazuread
    {
        try
        {
            Write-Output "Start Script at $(Get-Date)"
            Write-Output "Connect to Azure AD"

            Connect-AzureAD -TenantId $TenantIT -ApplicationId $ApplicationID -CertificateThumbprint $AppCertThumprint            
        }
        catch
        {
            throw "Error in Function function_connectazuread. Error: $($_.Exception.Message)"
        }
    }

    function function_getazureadrolemembers
    {        
        param(
            [parameter(Mandatory=$true)]
            [String]
            $azureadrole
        )
        try
        {
            $DirectoryRoleObjectID = (Get-AzureADDirectoryRole | where {$_.DisplayName -contains $azureadrole}).ObjectId

            $azureadrolememberhash = @{}
            if ($DirectoryRoleObjectID -ne $null)
            {
                foreach($user in (Get-AzureADDirectoryRoleMember -ObjectId $DirectoryRoleObjectID | where {$_.ObjectType -ne "ServicePrincipal"}))
                {
                    $azureadrolememberhash[$user.UserPrincipalName] = @($DirectoryRoleObjectID,$user.ObjectId)
                }

                return $azureadrolememberhash
            }
            else 
            {
                return $null
            }
        }
        catch
        {
            throw "Error in Function function_getazureadrolemembers. Error: $($_.Exception.Message)"
        }
    }

    function function_getazureadgroupmembers
    {
        param(
            [parameter(Mandatory=$true)]
            [String]
            $azureadgroupname
        )

        try
        {
            $AzureADGroupID = (Get-AzureADGroup -All $true | where {$_.DisplayName -contains $azureadgroupname}).ObjectId

            $azureadgroupmemberhash = @{}
            if($AzureADGroupID -ne $null)
            {
                #Get members from ad group
                foreach($user in (Get-AzureADGroupMember -All $true -ObjectId $AzureADGroupID | where {$_.ObjectType -eq "User"}))
                {
                    $azureadgroupmemberhash[$user.UserPrincipalName] = @($user.ObjectId)
                }
                
                #Get members from azure ad subgroup
                foreach($groups in (Get-AzureADGroupMember -All $true -ObjectId $AzureADGroupID | where {$_.ObjectType -eq "Group"}))
                {
                    foreach($user in (Get-AzureADGroupMember -All $true -ObjectId (Get-AzureADGroup -All $true | where {$_.DisplayName -contains $groups.DisplayName}).ObjectId) | where {$_.ObjectType -eq "User"})
                    {
                        $azureadgroupmemberhash[$user.UserPrincipalName] = @($user.ObjectId)                       
                    }
                }

                return $azureadgroupmemberhash
            }
            else 
            {
                return $azureadgroupmemberhash
            }
        }
        catch
        {
            throw "Error in Function function_getazureadgroupmembers. Error: $($_.Exception.Message)"
        }
    }

    function function_rem_orphaned_dir_members
    {
        param(
            [parameter(Mandatory=$true)]
            [String]
            $ADRole,
            [parameter(Mandatory=$true)]
            [System.Collections.Hashtable]
            $ADGroupMembers,            
            [parameter(Mandatory=$true)]
            [AllowEmptyString()]
            [System.Collections.Hashtable]
            $ADRoleMembers
        )

        try 
        {   
            Write-Output "Execute Function Remove User to Group" 

            foreach ($member in $ADRoleMembers.GetEnumerator())
            {
                if(($ExcludefromDirectoryRoleremove.Contains($member.Key)))
                {
                    Write-Output "User in exclusion Array $($member.Key)"
                } 
                elseif ($ADGroupMembers.ContainsKey($member.Key))
                {
                    Write-Output "No changes for user $($member.Key)"
                }     
                else 
                {
                    Write-Output "Remove user $($member.Key) from directory role $($ADRole)"

                    if ($debugscript -eq $false)
                    {
                        Remove-AzureADDirectoryRoleMember -ObjectId $member.Value[0] `
                                                          -MemberId $member.Value[1]
                    }
                    else
                    {
                        Write-Output "Debug Mode Active!"
                    }
                }          
            }
        }
        catch 
        {
            throw "Error in Function function_rem_orphaned_dir_members. Error: $($_.Exception.Message)"    
        }
    }

    function function_add_new_dir_members
    {
        param(
            [parameter(Mandatory=$true)]
            [String]
            $ADRole,
            [parameter(Mandatory=$true)]
            [System.Collections.Hashtable]
            $ADGroupMembers,            
            [parameter(Mandatory=$true)]
            [AllowEmptyString()]
            [System.Collections.Hashtable]
            $ADRoleMembers
        )

        try 
        {
            Write-Output "Execute Function Add User to Group" 

            $directoryobjectid = (Get-AzureADDirectoryRole | where {$_.DisplayName -eq $ADRole}).ObjectId
            
            foreach ($member in $ADGroupMembers.GetEnumerator())
            {
                if ($ADRoleMembers.ContainsKey($member.Key))
                {   
                    Write-Output "Nothing to do for User $($member.Key)"
                }
                else 
                {
                    Write-Output "Add User $($member.Key) to Directory Role $($ADRole)"

                    if($debugscript -eq $false)
                    {
                        Add-AzureADDirectoryRoleMember -ObjectId $directoryobjectid `
                                                       -RefObjectId $member.Value[0]
                    }
                    else
                    {
                        Write-Output "Debug Mode Active!"
                    }
                }
            }    
        }
        catch 
        {
            throw "Error in Function function_add_new_dir_members. Error: $($_.Exception.Message)"    
        }
    }

    #endregion
######################################################################################################################################

######################################################################################################################################
    #region scriptstartpoint    

    function_connectazuread

    foreach ($azureadgroup in $grouprolemapping.GetEnumerator())
    {
        #region Get directory role members
            Write-Output "Get Directory Role members for Role $($azureadgroup.Value)"

            [System.Collections.Hashtable]$roleresult = function_getazureadrolemembers -azureadrole $azureadgroup.Value
            if($roleresult -ne $null)
            {
                if($roleresult.Count -gt 0)
                {
                    Write-Output $roleresult.Keys               
                }
                else
                {
                    Write-Output "No Role member"    
                }
            }        
            else 
            {
                Write-Output "Azure AD Role not found. Please Enable the Role Template first!"      
            }  
            Write-Output " "         

        #endregion

        #region Get azure ad group member
            Write-Output "Get Azure AD Group members for group $($azureadgroup.Key)"

            [System.Collections.Hashtable]$groupresult = function_getazureadgroupmembers -azureadgroupname $azureadgroup.Key

            if($groupresult -ne $null)
            {
                if($groupresult.Count -gt 0)
                {
                    Write-Output $groupresult.Keys
                }
                else
                {
                    Write-Output "No Group member"
                }
            }
            else 
            {
                Write-Output "Azure AD Group not found!"
            }
            Write-Output " "
        #endregion

        #region Remove orphaned Directory Role Members
        if ($roleresult.Count -gt 0 -and $groupresult -ne $null)
        {
            function_rem_orphaned_dir_members -ADRole $azureadgroup.Value `
                                              -ADGroupMembers $groupresult `
                                              -ADRoleMembers $roleresult
            Write-Output " "
        }     
        #endregion

        #region Add new members to Directory Role members
        if ($groupresult.Count -gt 0 -and $groupresult -ne $null)
        {

            function_add_new_dir_members -ADRole $azureadgroup.Value `
                                         -ADGroupMembers $groupresult `
                                         -ADRoleMembers $roleresult
        }

        #endregion

        Write-Output "------------------------------------------------------------------------"   
    }    

    Write-Output "------------------------------------------------------------------------"

    #Write-Output "Write Log File"

######################################################################################################################################
}
catch
{
    Write-Error "Error $_"
}

#Disconnect-AzureAD