<#
    .SYNOPSIS
        
    .DESCRIPTION
        
    .EXAMPLE
        
    .NOTES  
        
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]
    $TenantID,
    [Parameter(Mandatory=$true)]
    [string]
    $ExporttoJSON,
    [Parameter(Mandatory=$true)]
    [string]
    $ExporttoHTML,
    [Parameter(Mandatory=$true)]
    [string]
    $ExporttoCSV
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
function LoginAzureAD()
{
    param (
        [Parameter()]
        [string]
        $Tenant
    )
    try 
    {
        if(-not (Get-Module AzureAD)) {
            Import-Module AzureAD
        }
    
        Connect-AzureAD -TenantId $Tenant        
    }
    catch {
        Write-Error "Error in function Login-Azure. Error message: $($_.Exception.Message)"
    }
}

#endregion
#######################################################################################################################


#######################################################################################################################
#region Script start

    Write-Host "Connect to Azure AD"
    LoginAzureAD -Tenant $TenantID

    $sps = Get-AzureADServicePrincipal -All $true
    $delegatedgrantperm = Get-AzureADOAuth2PermissionGrant
    
    $apps = @()

    foreach ($sp in $sps)
    {
        $app = New-Object System.Object
        $app | Add-Member -type NoteProperty -name ServicePrincipalName -Value $sp.DisplayName
        $app | Add-Member -type NoteProperty -name ServicePrincipalID -Value $sp.ObjectId 
        $app | Add-Member -type NoteProperty -name Enabled -Value $sp.AccountEnabled 
        $app | Add-Member -type NoteProperty -name UserAssigmentRequired -Value $sp.AppRoleAssignmentRequired


        
        #Memberof SP
        #region            
            $appmembers = @()
            foreach ($member in (Get-AzureADServiceAppRoleAssignment -ObjectId $sp.ObjectId -ErrorAction SilentlyContinue))
            {                    
                $appmembers += $member.PrincipalDisplayName
            }
            $app | Add-Member -type NoteProperty -name Members -Value $appmembers
        #endregion

        #Get application permissions
        #region
            $appappperm = @()
            $appchache = @()
            foreach ($obj in (Get-AzureADServiceAppRoleAssignedTo -ObjectId $sp.ObjectId -All $true))
            {            
                $perm = Get-AzureADObjectByObjectId -ObjectId $obj.ResourceId
                $appRole = $perm.AppRoles | Where-Object { $_.Id -eq $obj.Id }
                
                if(!$appchache.Contains($appRole.Value))
                {
                    $appappperm += $appRole.Value
                    $appchache += $appRole.Value
                }                             

                #$apppermissions.Add($appRole.Value, $appRole.DisplayName)
            }

        $app | Add-Member -type NoteProperty -name AppPermission -Value $appappperm
        #endregion

        #Get delegated permissions
        #region

            $Oauth2perms = @()
            $delchache = @()
            foreach ($obj in ($delegatedgrantperm | where {$_.ClientId -eq $sp.ObjectId}))
            {
                $perm = Get-AzureADObjectByObjectId -ObjectId $obj.ResourceId
                $scope = $obj.Scope.Split(" ")
                
                foreach ($scopeobj in $scope)
                {
                    try {
                        $Oauth2perm = $perm.Oauth2Permissions | where {$_.Value -eq $scopeobj}    
                
                        #$Oauth2perms.Add($Oauth2perm.Value, $Oauth2perm.UserConsentDisplayName)

                        if(!$delchache.Contains($Oauth2perm.Value))
                        {
                            $Oauth2perms += $Oauth2perm.Value 
                            $delchache +=   $Oauth2perm.Value
                        }                        
                    }
                    catch {

                        if(!$delchache.Contains($scopeobj))
                        {
                            $Oauth2perms += $scopeobj
                            $delchache += $scopeobj
                        }
                    }                    
                }                
            }

            $app | Add-Member -type NoteProperty -name DelPermissions -Value $Oauth2perms
        #endregion

        $apps += $app
    }  

    if ($ExporttoHTML)
    {
        $appreport = ""

        foreach ($appobj in $apps)
        {
            $appreport += "<tr>
                            <td>$($appobj.ServicePrincipalName)</td>
                            <td>$($appobj.ServicePrincipalID)</td>
                            <td>$($appobj.Enabled)</td>
                            <td>$($appobj.UserAssigmentRequired)</td>"
                            
                            $appreport += "<td>"
                            foreach ($member in $appobj.Members)
                            {
                                $appreport += "$($member)</br>"
                            }                            
                            $appreport += "</td>"

                            $appreport += "<td>"
                            foreach ($appperm in $appobj.AppPermission)
                            {
                                $appreport += "$($appperm)</br>"
                            }      
                            $appreport += "</td>"                      

                            $appreport += "<td>"
                            foreach ($delperm in $appobj.DelPermissions)
                            {
                                $appreport += "$($delperm)</br>"
                            }     
                            $appreport += "</td>"                         

            $appreport += "</tr>"
        }

        $report =   "<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Strict//EN'  'http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd'>
                    <html xmlns='http://www.w3.org/1999/xhtml'>
                    <style>
                            {font-family: Arial; font-size: 13pt;}
                                TABLE{border: 1px solid black; border-collapse: collapse; font-size:13pt;}
                                TH{border: 1px solid black; background: #f3023c; padding: 5px; color: #ffffff;}
                                TD{border: 1px solid black; padding: 5px; }
                        </style>
                    <head>
                        <title>ACP App Report</title>                        
                    </head>
                    <body>
                        
                            <h2>ACP App Report</h2>
                                <table>
                                    <tr>
                                        <th>Name</th>
                                        <th>ID</th>
                                        <th>Enabled for users to sign-in</th>
                                        <th>User assignment required</th>
                                        <th>Members</th>
                                        <th>App Permission</th>
                                        <th>Delegated Permission</th>
                                    </tr>
                                    $appreport
                                </table>
                    </body>
                    </html>"

        $report > "$($PSScriptRoot)\temp\AppReport.html"
    }

    if ($ExporttoJSON) {
        $apps | ConvertTo-Json > "$($PSScriptRoot)\AppReport.json"
    }

    if($ExporttoCSV)
    {
        $csvlist =@()

        foreach ($appobj in $apps)
        {
            $members = "("
            foreach ($member in $appobj.Members)
            {
                $members += "$($member),"
            } 
            $members += ")"

            $appperm = "("
            foreach ($appperm in $appobj.AppPermission)
            {
                $appperm += "$($appperm),"
            }  
            $appperm += ")"

            $deleperm = "("
            foreach ($delperm in $appobj.DelPermissions)
            {
                $deleperm += "$($delperm),"
            }   
            $deleperm += ")"  

            $newrow = New-Object PSObject -Property @{
                        Name = $appobj.ServicePrincipalName
                        ID = $appobj.ServicePrincipalID
                        Enabled = $appobj.Enabled
                        UserAssigmentRequired = $appobj.UserAssigmentRequired
                        Members = $members
                        AppPerm = $appperm
                        DelPerm = $deleperm
                    }

            $csvlist += $newrow
        }
        $csvlist | export-csv -path "$($PSScriptRoot)\temp\AppReport.csv" -notypeinformation
    }
     
#endregion
#######################################################################################################################
