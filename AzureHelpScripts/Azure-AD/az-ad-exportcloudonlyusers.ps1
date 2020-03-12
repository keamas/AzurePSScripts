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
    try 
    {
        if(-not (Get-Module AzureAD)) {
            Import-Module AzureAD
        }
    
        Connect-AzureAD     
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
    LoginAzureAD

    $users = @()    
    $rolemembers = @()

    $roles = Get-AzureADDirectoryRole
    foreach ($role in $roles)
    {
        $members = Get-AzureADDirectoryRoleMember -ObjectId $role.ObjectId
        $m = ""
        if ($members -ne $null)
        {
            $m = $members.ObjectId
        }

        $memberrow = New-Object PSObject -Property @{
                        RoleID = $role.ObjectId
                        RoleName = $role.DisplayName
                        RoleMembers = $m
                    }
        
        $rolemembers += $memberrow
    }


    $cloudusers = Get-AzureADUser -all $true | where {$_.DirSyncEnabled -ne "True"} #| where-object {$_.ObjectId -eq "d7fff8ac-c573-482d-835c-17f0b502e6f3"}

    foreach ($user in $cloudusers)
    {
        $approles = ""
        if((Get-AzureADUserAppRoleAssignment -ObjectId $user.ObjectId) -ne $null)
        {
            $approles = (Get-AzureADUserAppRoleAssignment -ObjectId $user.ObjectId).ResourceDisplayName
        }

        $groups = ""
        if((Get-AzureADUserMembership -ObjectId $user.ObjectId) -ne $null)
        {
            $groups = (Get-AzureADUserMembership -ObjectId $user.ObjectId).DisplayName
        }
        
        $assignrole = ""
        if(($rolemembers | where-object {$_.RoleMembers -Match $user.ObjectId}) -ne $null)
        {
            $assignrole = ($rolemembers | where-object {$_.RoleMembers -Match $user.ObjectId}).RoleName
        }    

        $newuserrow = New-Object PSObject -Property @{
                                Name = $user.DisplayName
                                Enabled = $user.AccountEnabled
                                UPN = $user.UserPrincipalName
                                UserType = $user.UserType
                                AppRoles = $approles
                                MemberOf = $groups
                                DirectoryRoles = $assignrole
                        }

        $users += $newuserrow 
    }

    if ($ExporttoHTML)
    {
        $appreport = ""

        foreach ($user in $users)
        {
            $appreport += "<tr>
                            <td>$($user.Name)</td>
                            <td>$($user.UPN)</td>
                            <td>$($user.Enabled)</td>
                            <td>$($user.UserType)</td>"
                            
                            $roles = $user.AppRoles.replace(",","</br>")
                            $appreport += "<td>$roles</td>"
                            
                            $dirroles = $user.DirectoryRoles.replace(",","</br>")
                            $appreport += "<td>$dirroles</td>"

                            $mem = $user.MemberOf.replace(",","</br>")
                            $appreport += "<td>$mem</td>"

                            
            $appreport += "</tr>"
        }

        $report = "<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Strict//EN'  'http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd'>
                    <html xmlns='http://www.w3.org/1999/xhtml'>
                    <style>
                            {font-family: Arial; font-size: 13pt;}
                                TABLE{border: 1px solid black; border-collapse: collapse; font-size:13pt;}
                                TH{border: 1px solid black; background: #f3023c; padding: 5px; color: #ffffff;}
                                TD{border: 1px solid black; padding: 5px; }
                        </style>
                    <head>
                        <title>Cloud only User Report</title>                        
                    </head>
                    <body>
                        
                            <h2>Cloud User Report</h2>
                                <table>
                                    <tr>
                                        <th>Name</th>
                                        <th>UPN</th>
                                        <th>Enabled</th>
                                        <th>UserType</th>
                                        <th>AppRoles</th>
                                        <th>DirectoryRoles</th>
                                        <th>MemberOf</th>
                                    </tr>
                                    $appreport
                                </table>
                    </body>
                    </html>"

        $report > "$($PSScriptRoot)\temp\CloudUserReport.html"
    }

    if ($ExporttoJSON) {
        $users | ConvertTo-Json > "$($PSScriptRoot)\temp\CloudUserReport.json"
    }

    if($ExporttoCSV)
    {
        $csvlist =@()

        foreach ($user in $users)
        {
            $MemberOf = "("
            foreach ($member in $user.MemberOf)
            {
                $MemberOf += "$($member),"
            } 
            $MemberOf += ")"

            $DirectoryRoles = "("
            foreach ($appperm in $user.DirectoryRoles)
            {
                $DirectoryRoles += "$($appperm),"
            }  
            $DirectoryRoles += ")"

            $AppRoles = "("
            foreach ($roles in $user.AppRoles)
            {
                $AppRoles += "$($roles),"
            }   
            $AppRoles += ")"  

            $newrow = New-Object PSObject -Property @{
                        Name = $user.Name
                        UPN = $user.UPN
                        UserType = $user.UserType
                        Enabled = $user.Enabled
                        MemberOf = $MemberOf
                        DirectoryRoles = $DirectoryRoles
                        AppRoles = $AppRoles
                    }

            $csvlist += $newrow
        }
        $csvlist | export-csv -path "$($PSScriptRoot)\temp\CloudUserReport.csv" -notypeinformation
    }
     
#endregion
#######################################################################################################################
