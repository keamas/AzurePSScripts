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


    $resourcegroup = "RG-TestDoka"
    $location = "West Europe"
    $appsvcplanname = "dokatestappsvcplan"
    $webappname = "dokatestwebapp"

    #Deploy App service with stack (dotnet,...)
    $appsvcplan = New-AzAppServicePlan -ResourceGroupName $resourcegroup -Location $location -Name $appsvcplanname `
                                       -Tier Standard -NumberofWorkers 1 -WorkerSize Small

        
    $webapp = New-AzWebApp -Name $webappname -Location $location -ResourceGroupName $resourcegroup -AppServicePlan $appsvcplan.Name 

    $PropertiesObject = @{
        "CURRENT_STACK" =  "dotnetcore";
        "majorVersions" = "3.0"
    }

    New-AzResource -PropertyObject $PropertiesObject -ResourceGroupName $resourcegroup `
                   -ResourceType Microsoft.Web/sites/config -ResourceName "$webappname/metadata" -ApiVersion 2018-02-01 -Force

#######################################################################################################################


