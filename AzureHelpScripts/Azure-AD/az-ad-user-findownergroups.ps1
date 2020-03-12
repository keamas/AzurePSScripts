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
    $UserUPN,
    [Parameter()]
    [bool]
    $ExporttoJSON,
    [Parameter()]
    [bool]
    $ExporttoHTML,
    [Parameter()]
    [bool]
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


    $foundusers = @()

    foreach ($user in (Get-AzureADUser -All $true | where {$_.UserPrincipalName -Match $UserUPN}))
    {
        $newrow = New-Object PSObject -Property @{
                DisplayName = $user.DisplayName
                ID = $user.ObjectId
                Mail = $user.Mail
        }

        $foundusers += $newrow
    }

    $convertforext = $UserUPN.replace("@", "_")
    foreach ($user in (Get-AzureADUser -All $true | where {$_.UserPrincipalName -match $convertforext}))
    {
        $newrow = New-Object PSObject -Property @{
                DisplayName = $user.DisplayName
                ID = $user.ObjectId
                Mail = $user.Mail
        }

        $foundusers += $newrow
    }
    
    $ownerof = @()
    if($foundusers){
        $Groups = Get-AzureADGroup

        foreach ($group in $groups)
        {
            $owners = Get-AzureADGroupOwner -All $true -ObjectId $group.ObjectId
            if (($owners) -and ($owners).ObjectId -eq $foundusers.ID)
            {
                Write-Output "User is Owner from group $($group.DisplayName)"
                
                $newrow = New-Object PSObject -Property @{
                        Username = $foundusers.DisplayName
                        Groupname = $group.DisplayName
                }
        
                $ownerof += $newrow
            }
        }
    }else{
        Write-Output "No user found"
    }


    if ($ExporttoHTML){
        $ownerreport = ""

        foreach ($group in $ownerof)
        {
            $ownerreport += "<tr>
                                <td>$($group.Username)</td>
                                <td>$($group.Groupname)</td>                                                    
                            </tr>"
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
                        <title>Group Owner Report</title>                        
                    </head>
                    <body>
                        
                            <h2>Group Owner Report</h2>
                                <table>
                                    <tr>
                                        <th>Username</th>
                                        <th>Groupname</th>
                                    </tr>
                                    $ownerreport
                                </table>
                    </body>
                    </html>"

        $report > "C:\temp\GroupOwnerReport.html"
    }

    if ($ExporttoJSON) {
        $ownerof | ConvertTo-Json > "C:\temp\GroupOwnerReport.json"   
    }

    if($ExporttoCSV)
    {
        $ownerof | export-csv -path "C:\temp\GroupOwnerReport.csv" -notypeinformation
    }
     
#endregion
#######################################################################################################################


