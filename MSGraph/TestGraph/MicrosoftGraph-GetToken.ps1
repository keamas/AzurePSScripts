<#
    SYNOPSIS
        This script is used to demonstrate the different permission types
    .DESCRIPTION
        This function demonstrate the delegated, delegated with admin consent and application permission
    .EXAMPLE
        get-msgraphtoken -Connectiontype delegated `
                         -UserUPN "demouser@contoso.com" `
                         -AppId "1234567-1234-1234-1234-123434534546" `
                         -AppSecred "Null" `
                         -Tenant "contoso.onmicrosoft.com"

        Authenticates you with the Graph API interface with delegated permissions
        .NOTES
    NAME: get-msgraphtoken
#>

function get-msgraphtoken
{
<#
    SYNOPSIS
        This function is used to authenticate with the Graph API REST interface
    .DESCRIPTION
        The function authenticate with the Graph API Interface with the tenant name
    .EXAMPLE
        Get-AuthToken
    Authenticates you with the Graph API interface
        .NOTES
    NAME: Get-AuthToken
#>

    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('delegated','delegatedwithadminconsent','application')]
        $Connectiontype,
        [Parameter(Mandatory=$true)]
        $UserUPN,
        [Parameter(Mandatory=$true)]
        $AppId,
        [Parameter(Mandatory=$true)]
        $AppSecred,
        [Parameter(Mandatory=$true)]
        $Tenant
    )

    $resourceAppIdURI = "https://graph.microsoft.com"
    $authority = "https://login.microsoftonline.com/$Tenant"
    $redirectUri = "urn:ietf:wg:oauth:2.0:oob"

    switch ($Connectiontype)
    {
        application
        {
            $body = @{grant_type="client_credentials";resource=$resourceAppIdURI;client_id=$AppId;client_secret=$AppSecred}
            $oauth = Invoke-RestMethod -Method Post -Uri $authority/oauth2/token?api-version=1.0 -Body $body

            if($oauth.access_token)
            {
                # Creating header for Authorization token

                $authHeader = @{
                        'Content-Type'='application/json'
                        'Authorization'="Bearer " + $oauth.access_token
                        'ExpiresOn'= $oauth.expires_on
                }

                return $authHeader
            }
            else 
            {
                Write-Host
                Write-Host "Authorization Access Token is null, please re-run authentication..." -ForegroundColor Red
                Write-Host
                break
            }
        }
        default
        {
            Write-Host "start with delegated authentication"
            $AadModule = Get-Module -Name "AzureAD" -ListAvailable
            if($AadModule.count -gt 1){

                $Latest_Version = ($AadModule | select version | Sort-Object)[-1]
                $aadModule = $AadModule | ? { $_.version -eq $Latest_Version.version }
         
                    # Checking if there are multiple versions of the same module found
                    if($AadModule.count -gt 1)
                    {
                        $aadModule = $AadModule | select -Unique
                    }

                $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
                $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
            }
            else
            {
                $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
                $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
            }

            [System.Reflection.Assembly]::LoadFrom($adal) | Out-Null

            [System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null


            try {
                $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority

                # https://msdn.microsoft.com/en-us/library/azure/microsoft.identitymodel.clients.activedirectory.promptbehavior.aspx
                # Change the prompt behaviour to force credentials each time: Auto, Always, Never, RefreshSession

                $platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList "Auto"

                $userId = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier" -ArgumentList ($UserUPN, "OptionalDisplayableId")

                if ($Connectiontype -eq "delegated")
                {
                    $authResult = $authContext.AcquireTokenAsync($resourceAppIdURI,$AppId,$redirectUri,$platformParameters,$userId).Result
                }
                else
                {
                    $authResult = $authContext.AcquireTokenAsync($resourceAppIdURI,$AppId,$redirectUri,$platformParameters,$userId,"prompt=admin_consent").Result
                }
        
                if($authResult.AccessToken)
                {

                    # Creating header for Authorization token

                    $authHeader = @{
                        'Content-Type'='application/json'
                        'Authorization'="Bearer " + $authResult.AccessToken
                        'ExpiresOn'=$authResult.ExpiresOn
                        }

                    return $authHeader

                }
                else 
                {
                    Write-Host
                    Write-Host "Authorization Access Token is null, please re-run authentication..." -ForegroundColor Red
                    Write-Host
                    break
                }
            }
            catch 
            {
                write-host $_.Exception.Message -f Red
                write-host $_.Exception.ItemName -f Red
                write-host
                break
            }
        }
    }
}

#############################################################################################################
#region Delegate permission
#

#Get user delegated token
$token = get-msgraphtoken -Connectiontype delegated `
                          -UserUPN "demo1@lagler-gruener.at" `
                          -AppId "775c0a92-f072-4e8e-a1c6-fb1b37dfcc4f" `
                          -AppSecred "Null" `
                          -Tenant "laglerh.onmicrosoft.com"

# You get an error (403) Forbidden
$url = "https://graph.microsoft.com/v1.0/users"         
$response = Invoke-RestMethod -Method Get -Uri $url -Headers @{Authorization = $token.Authorization} 

foreach ($user in $response.value)
{
    Write-Host "Displayname: $($user.displayname)"
    Write-Host "GivenName: $($user.givenName)"
    Write-Host "Surename: $($user.surname)"
    Write-Host "#########################"
    Write-Host " "
}

# Work fine
$url = "https://graph.microsoft.com/v1.0/me"         
$response = Invoke-RestMethod -Method Get -Uri $url -Headers @{Authorization = $token.Authorization} 

foreach ($user in $response.value)
{
    Write-Host "Displayname: $($user.displayname)"
    Write-Host "GivenName: $($user.givenName)"
    Write-Host "Surename: $($user.surname)"
    Write-Host "#########################"
    Write-Host " "
}
#endregion

#############################################################################################################
#region Delegate with admin consent permission
#

#Get user delegated token with admin consent
$token = get-msgraphtoken -Connectiontype delegatedwithadminconsent `
                          -UserUPN "demouser1@lagler-gruener.at" `
                          -AppId "775c0a92-f072-4e8e-a1c6-fb1b37dfcc4f" `
                          -AppSecred "Null" `
                          -Tenant "laglerh.onmicrosoft.com"

# Work fine
$url = "https://graph.microsoft.com/v1.0/users"         
$response = Invoke-RestMethod -Method Get -Uri $url -Headers @{Authorization = $token.Authorization} 

foreach ($user in $response.value)
{
    Write-Host "Displayname: $($user.displayname)"
    Write-Host "GivenName: $($user.givenName)"
    Write-Host "Surename: $($user.surname)"
    Write-Host "#########################"
    Write-Host " "
}

# Work fine
$url = "https://graph.microsoft.com/v1.0/me"         
$response = Invoke-RestMethod -Method Get -Uri $url -Headers @{Authorization = $token.Authorization} 

foreach ($user in $response.value)
{
    Write-Host "Displayname: $($user.displayname)"
    Write-Host "GivenName: $($user.givenName)"
    Write-Host "Surename: $($user.surname)"
    Write-Host "#########################"
    Write-Host " "
}

#endregion                          

#############################################################################################################
#region Application permission
#

#Get application token
$token = get-msgraphtoken -Connectiontype application `
                          -UserUPN "Null" `
                          -AppId "775c0a92-f072-4e8e-a1c6-fb1b37dfcc4f" `
                          -AppSecred "vb4:f2qM[B[*ovFIPxKjqZatLxwY7vn7" `
                          -Tenant "laglerh.onmicrosoft.com"
             
             
 # Work fine
$url = "https://graph.microsoft.com/v1.0/users"         
$response = Invoke-RestMethod -Method Get -Uri $url -Headers @{Authorization = $token.Authorization}   

foreach ($user in $response.value)
{
    Write-Host "Displayname: $($user.displayname)"
    Write-Host "GivenName: $($user.givenName)"
    Write-Host "Surename: $($user.surname)"
    Write-Host "#########################"
    Write-Host " "
}

#endregion


$SearchTimeRange = "{0:s}" -f (get-date).AddHours(-4) + "Z"

$url = 'https://graph.microsoft.com/v1.0/auditLogs/directoryAudits?&$filter=activityDateTime gt ' + $SearchTimeRange + ' and activityDisplayName eq ''Add member to role'''

$myReport = (Invoke-WebRequest -Method Get -Headers @{Authorization = $token.Authorization} -Uri $url)