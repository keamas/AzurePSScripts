   
    ############################################################################################################
    # Script to check Azure ResourceGroup Permissions
    #
    # Author: Hannes Lagler-gruener
    #
    #
    # Functionality:
    #               Monitor each Azure ResourceGroup of their RBAC Permissions
    #               
    #
    # Modifications:
    #
    #               Date: 31.08.2017
    #               Changes: Initial create runnbook
    #
    #
    # Requironments:
    #              Modul: AzureAD (min. Version 2.0.0.131)
    #              Seperate AD Attribute: displayNamePrintable > for ResourceGroup Name
    #
    ###########################################################################################################

    Param (   
        [parameter(Mandatory=$true)]
        [ValidateSet("Prod", "Test")] 
        [String]  
        $AzureEnv,
        [parameter(Mandatory=$true)] 
        [string]
        $RunCleanup
    )

    try
    {

    #####################################################################################################################################
    #region Functions

    #RBAC Add Function
    Function FunctionCheckResourceGroupRBACPermission
    {
         Param (   
            [parameter(Mandatory=$true)]  
            [String]  
            $searchgroupname,
            [parameter(Mandatory=$true)]  
            [String]  
            $defaultgroupstartstring,            
            [parameter(Mandatory=$true)]  
            [ValidateSet("Owner", "Reader", "Contributor")]
            [String]  
            $rbacgrouppermission           
        )

        try
        {

            [string]$definedgroupname = "" #Endresult for AD Groupname
            [string]$defaultgroupendstring = ".$($rbacgrouppermission)" #Group Endstring (sample: .Owner)
            [int]$maxgrouplenght = $maxgroupnamecount - $defaultgroupstartstring.Length - $defaultgroupendstring.Length -3 #Define the max. lenght for the groupname
                                                                                                                           #Sample: $maxgroupnamecount = 64
                                                                                                                           #        $defaultgroupstartstring = Az-RBAC-Prod-. (14 Chars)
                                                                                                                           #        $defaultgroupendstring = .Owner (6 Chars)
                                                                                                                           #        Remove 3 more chars because we add the following chars if the string is to long: "..."
                                                                                                                           #        $maxgrouplenght = 41 Chars
                                                                                                                           #
                                                                                                                           #Result: The max lenght for the ResourceGroup (without resgroup) is 35

            #Define a Hashtable to return the result            
            [hashtable]$returnhashtable = @{}
            
            #Compare the groupname (without resgroup) with the max. grouplenght
            if ($searchgroupname.Length -le $maxgrouplenght)
            {
                #The defined groupname (without resgroup) is shorter than maxgrouplenght
                $definedgroupname = "$($defaultgroupstartstring)$($searchgroupname)$($defaultgroupendstring)" 
                $definedgroupshortname = ""
                
                
                #Check if there is an rbac role defined with the following settings:
                #      RoleDefinitionName equals the current role (Reader, Owner, Contributor)
                #      The rbac scope equals resourcegroup name (thi means, the permission isn't set global)
                #      The rbac display name match the definied one
                if (!($rbacroles | where {($_.RoleDefinitionName -eq $rbacgrouppermission.ToString()) -and `
                     ($_.Scope.EndsWith($ResourceGroup.ResourceGroupName)) -and `
                     ($_.DisplayName.ToLower() -eq $definedgroupname.ToLower())}))
                {
                    #Define Hashtable with the needing returl values
                    $returnhashtable.State = "notfound"
                    $returnhashtable.GroupCN = $definedgroupname
                    $returnhashtable.GroupShortName = ""
                    $returnhashtable.ProjectName = $searchgroupname
                    $returnhashtable.GroupDisplayName = $definedgroupname
            
                    return $returnhashtable
                }
                else
                {
                    #Define Hashtable with the needing returl values
                    $returnhashtable.State = "found"
                    $returnhashtable.GroupCN = $definedgroupname
                    $returnhashtable.GroupShortName = ""
                    $returnhashtable.ProjectName = $searchgroupname
                    $returnhashtable.GroupDisplayName = $definedgroupname
                  
                    return $returnhashtable
                }               
            }
            else                
            {
                #The defined groupname (without resgroup) is greater than maxgrouplenght
                #Cut the defined groupname.
                #Sample:
                #        $searchgroupname = resgrouptestazuregroup12343323325253253252352353255235353253252367890244444242412412414124
                #        $shortgroupname = .Azure.RBAC.PostAG.Dev.testazuregroup123433233252532532....Owner
                #$shortgroupname = "$($searchgroupname.Substring(0, $maxgrouplenght))..."
                #$definedgroupname = "$($defaultgroupstartstring)$($shortgroupname)$($defaultgroupendstring)"

                #Define Hashtable with the needing returl values
                $returnhashtable.State = "toolong"
                $returnhashtable.GroupCN = ""
                $returnhashtable.GroupShortName = ""
                $returnhashtable.ProjectName = ""
                $returnhashtable.GroupDisplayName = ""
                $returnhashtable.ErrorMsg = "The Resourcegroup is to long $($searchgroupname)"
                  
                return $returnhashtable
            }                                                    
        }
        catch
        {
            throw "Error in Function 'FunctionCheckResourceGroupRBACPermission'. Error Message: $($_.Exception.Message)"
        }
    }

    Function FunctionCheckAzureADforGroup
    {
        Param (   
            [parameter(Mandatory=$true)]  
            [String]  
            $GroupName
        )

        try
        {
            [hashtable]$returnhashtable = @{}

            #Check Azure AD and search the definied rbac name
            if (Get-AzureADGroup -Filter "DisplayName eq '$($GroupName)'" -ErrorAction Stop)
            {
                $adgroup = Get-AzureADGroup -Filter "DisplayName eq '$($GroupName)'" -ErrorAction Stop
            
                $returnhashtable.State = $true
                $returnhashtable.ObjectId = $adgroup.ObjectId

                return $returnhashtable
            }
            else
            {     
                $returnhashtable.State = $false
                $returnhashtable.ObjectId = ""
                 
                return $returnhashtable
            }        
        }
        Catch
        {
            throw "Error in Function 'FunctionCheckAzureADforGroup'. Error Message: $($_.Exception.Message)"
        }
    }

    Function FunctionAssignRBACPermission
    {
        Param (   
            [parameter(Mandatory=$true)]    
            [String]  
            $ADPermissionGroup,
            [parameter(Mandatory=$true)]    
            [String]  
            $ADPermissionGroupObjectID,
            [parameter(Mandatory=$true)]  
            [ValidateSet("Owner", "Reader", "Contributor")]
            [String]  
            $AddPermissionType,           
            [parameter(Mandatory=$true)]    
            [String]  
            $ResourceGroup
        )

        try
        {
            Write-Output "`t Add AzureAD Group $($ADPermissionGroup) with Permission $($AddPermissionType) to RessourceGroup $($ResourceGroup)"

            New-AzureRmRoleAssignment -ResourceGroupName $ResourceGroup -ObjectId $ADPermissionGroupObjectID -RoleDefinitionName $AddPermissionType -ErrorAction Stop

        }
        Catch
        {
            throw "Error in Function 'FunctionAssignRBACPermission'. Error Message: $($_.Exception.Message)"
        }

    }  
    
    $omsmessagearray = [System.Collections.ArrayList]@()
    Function GenerateLoganalyticsMessage
    {
        param(
            [parameter(Mandatory=$true)]
            [ValidateSet('Success','Error')]
            [String]
            $State,
            [parameter(Mandatory=$true)]
            [String]
            $Subscription,
            [parameter(Mandatory=$true)]
            [String]
            $ResGroup,
            [parameter(Mandatory=$true)]
            [String]
            $Permission,
            [parameter(Mandatory=$true)]
            [String]
            $InformationDetail
        )


        $OMSMessage = [System.Collections.ArrayList]@()
        $date = get-date -Format G

        $OMSMessage = @{"MonitorType"=$MonitorType;`
                        "Hostname"=$Computername;`
                        "Date"=$date;`
                        "LogName"=$LogType;`
                        "State"=$State;`
                        "Subscription"=$Subscription
                        "ResourceGroup"=$ResGroup; `
                        "Permission"=$Permission; `
                        "StateDetail"=$InformationDetail;`
                        "FunctionError"=$global:functionerror}
        
        $omsmessagearray.Add($OMSMessage)
        
    }

    Function SendLoganalyticsMessage
    {
        $json = $omsmessagearray | ConvertTo-Json
        Post-LogAnalyticsData -customerId $LogAnalyWorkSpace.WorkspaceID `
                              -sharedKey $LogAnalyWorkSpace.SharedKey `
                              -body ([System.Text.Encoding]::UTF8.GetBytes($json)) `
                              -logType $logType 
    }  

    #endregion
    #####################################################################################################################################


    #####################################################################################################################################
    #region Define public variables

        Write-Output "Define public variables"
        Write-Output "###########################################################################"
    
        $global:functionerror = ""

        #Global Variables
        [int]$maxgroupnamecount = 64
        [array]$arrmissingadgroups = @()
        [array]$arrmissingadgroupsfailedtocreate = @()

        [string]$defaultadgroupdescription = "%Permission% Permission for ressourcegroup ''%resgroup%'' in %subscription% subscription."        

        [string]$customrbacrolename = ""


        #Default Automation Account subscription
        [string]$automationresgroup = "resgroupoms"
        [string]$automationonpremrunbook = "RB-Check-ResourceGroupPerm-OnPrem"
        [string]$automationaccountname = "omsautomationaccount"
        [string]$automationhybridworkergroup = "ProdHybridWorker"         
        [string]$automationaccountscubscription = "Visual Studio Enterprise – MPN" #This Variable is only be used when the On-Prem Runbook will be executed!


        #Active Directory variables
        [string]$activedirectoryrootgroupdn = "OU=Azure,OU=Applications,OU=UmdaschGlobalGroups,DC=testdomlagler,DC=local"
        [string]$activedirectoryprodgroupdn = "OU=L3,OU=ResGroupProd,OU=Azure,OU=Applications,OU=UmdaschGlobalGroups,DC=testdomlagler,DC=local"                      
        [string]$activedirectorydevtestgroupdn = "OU=L3,OU=ResGroupDev,OU=Azure,OU=Applications,OU=UmdaschGlobalGroups,DC=testdomlagler,DC=local"
        [string]$activedirectorycleanupgroupdn = "OU=OldGroups,OU=Applications,OU=UmdaschGlobalGroups,DC=testdomlagler,DC=local"        
       

        #Cleanup variables
        [string[]]$arrlcleanupexclusion = @("") # Define the excludet Group name in Active Directory


        if($AzureEnv -eq "Prod")
        {
            #$UseAzureSubscription = "Enterprise Doka Prod"
            $UseAzureSubscription = "Visual Studio Enterprise – MPN"
            $ResGroupStartWith = "Az-rg-Prod-"
            $defaultgroupstartstring = "Az-RBAC-Prod-"
            $defaultgroupdn = $activedirectoryprodgroupdn
        }
        else
        {
            #$UseAzureSubscription = "Enterprise Doka Dev/Test"
            $UseAzureSubscription = "Visual Studio Enterprise – MPN"
            $ResGroupStartWith = "Az-rg-Test-"
            $defaultgroupstartstring = "Az.RBAC.Test."
            $defaultgroupdn = $activedirectorydevtestgroupdn
        }


        #OMSConfigurations
        $LogAnalyWorkSpace = Get-AutomationConnection -Name "ProdLogAWorkspaceID" -ErrorAction Stop
        $LogType = "DokaRBACAutomation"
        $MonitorType = "Client"
        $TimeStampField = "YYYY-MM-DDThh:mm:ssZ"
        #$Computername = $env:computername
        $Computername = "AzureAutomation"
        
    #endregion
    #####################################################################################################################################


    #####################################################################################################################################
    #region Login into Azure

    Write-Output "Login into Azure"
    Write-Output "###########################################################################"

        $Connection = Get-AutomationConnection -Name "AzureRunAsConnection" -ErrorAction Stop

        Connect-AzureRmAccount -ServicePrincipal `
                                -TenantId $Connection.TenantId `
                                -ApplicationId $Connection.ApplicationId `
                                -CertificateThumbprint $Connection.CertificateThumbprint -ErrorAction Stop


        Select-AzureRmSubscription -SubscriptionName $UseAzureSubscription -ErrorAction Stop

    Write-Output "Login into AzureAD"
    Write-Output "###########################################################################"

        Connect-AzureAD -TenantId $Connection.TenantId `
                        -ApplicationId $Connection.ApplicationId `
                        -CertificateThumbprint $Connection.CertificateThumbprint -ErrorAction Stop


    #endregion
    #####################################################################################################################################


    #####################################################################################################################################
    #region Get all Azure ResourceGroups

        Write-Output "Get all Azure ResourceGroups"
        Write-Output "###########################################################################"        

        $AllAzureResGroups = Get-AzureRmResourceGroup | where {$_.ResourceGroupName.StartsWith($ResGroupStartWith)} -ErrorAction Stop

    #endregion
    #####################################################################################################################################


    #####################################################################################################################################
    #region Stop Prozess

        if ($RunCleanup -eq "false")
        {        
            foreach ($ResourceGroup in $AllAzureResGroups)
            {
                try
                {
                    Write-Output "---------------------------------------------------------------------------"
                    Write-Output "Check defaut RBAC Permission for ResourceGroup: $($ResourceGroup.ResourceGroupName) `n"
                    $rbacroles = Get-AzureRmRoleAssignment -ResourceGroupName $ResourceGroup.ResourceGroupName -ErrorAction Stop
           
                    [string]$strgroupname = $ResourceGroup.ResourceGroupName.Replace($ResGroupStartWith,"")
                    
                    [string[]]$permissiontypes = @("Owner","Reader","Contributor")    
                    
                    foreach ($perm in $permissiontypes)
                    {
                        #Check the ResourceGroup if the default Owner Permission was set.
                        $resultpermission = FunctionCheckResourceGroupRBACPermission -defaultgroupstartstring $defaultgroupstartstring `
                                                                                     -searchgroupname $strgroupname `
                                                                                     -rbacgrouppermission $perm

                        #Analyse the function result
                        if ($resultpermission.State -eq "found")
                        {
                            Write-Output "`t Default $($perm) Group $($resultpermission.Groupname) exist. Nothing to do"
                        }
                        elseif ($resultpermission.State -eq "notfound")
                        {
                            #The default Owner Permission wasn't set, check azure ad if the group exist.
                            Write-Output "Search for Group $($resultpermission.GroupDisplayName) in Azure AD."
                            $resultcheckadgroup = FunctionCheckAzureADforGroup -GroupName $resultpermission.GroupDisplayName

                            #Check function result
                            if (!$resultcheckadgroup.State)
                            {                
                                Write-Output "`t Default $($perm) Group doesn't exist!"
                                Write-Output "`t Add Group $($resultpermission.GroupDisplayName) to add arraylist"
                        
                        
                                #Define Group Description
                                $GroupDescription = $defaultadgroupdescription.Replace("%Permission%", $perm).Replace(`
                                                                                       "%resgroup%", $ResourceGroup.ResourceGroupName).Replace(`
                                                                                       "%subscription%", $UseAzureSubscription)

                                #Add Information to Array
                                $arrmissingadgroups = $arrmissingadgroups += (New-Object PSObject -Property @{ResGroupName = $ResourceGroup.ResourceGroupName; `
                                                                                                              ADGroupGroupName = $resultpermission.GroupDisplayName; `
                                                                                                              ADGroupDN = $defaultgroupdn; `
                                                                                                              ADGroupDNPrintA = $resultpermission.ProjectName; `
                                                                                                              ADGroupDescription = $GroupDescription})
                            }
                            else
                            {
                                Write-Output "`t Group found in AzureAD, add RBAC permission to ResourceGroup"
             
                                #Assign the azure ad group to the resource group   
                                FunctionAssignRBACPermission -ADPermissionGroup $resultpermission.GroupDisplayName `
                                                             -ADPermissionGroupObjectID $resultcheckadgroup.ObjectId `
                                                             -AddPermissionType $perm `
                                                             -ResourceGroup $ResourceGroup.ResourceGroupName

                                GenerateLoganalyticsMessage -State Success `
                                                            -Subscription $UseAzureSubscription `
                                                            -ResGroup $ResourceGroup.ResourceGroupName `
                                                            -Permission $perm `
                                                            -InformationDetail "Azure AD Group $($resultpermission.GroupDisplayName) found. Assign permission $($perm) to group $($resultpermission.GroupDisplayName) for resourcegroup $($ResourceGroup.ResourceGroupName)"

                
                            }
                        }
                        elseif ($resultpermission.State -eq "toolong")
                        {
                            Write-Output "`t Resourcegroup is too long!"

                            $arrmissingadgroupsfailedtocreate = $arrmissingadgroupsfailedtocreate += (New-Object PSObject -Property @{ResGroupName = $ResourceGroup.ResourceGroupName; `
                                                                                                                                      ADGroupGroupName = $resultpermission.GroupDisplayName; `
                                                                                                                                      ADGroupDN = $defaultgroupdn; `
                                                                                                                                      ADGroupDNPrintA = $resultpermission.ProjectName; `
                                                                                                                                      ADGroupDescription = $GroupDescription; `
                                                                                                                                      ErrorMessage =  $resultpermission.ErrorMsg})
                            
                            GenerateLoganalyticsMessage -State Error `
                                                        -Subscription $UseAzureSubscription `
                                                        -ResGroup $ResourceGroup.ResourceGroupName `
                                                        -Permission $perm `
                                                        -InformationDetail "The resourcegroup $($ResourceGroup.ResourceGroupName) is too long. Please shring the resourcegroup!"
                        }
                    }          
                }
                Catch
                {
                    throw $_.Exception.Message
                }       
           }

       #Call On-Prem Runbook to create AD Groups
       if ($arrmissingadgroups.Count -gt 0)
       {
            Write-Output "Execute runbook on hybrideworkergroup $($automationhybridworkergroup)"
            $jsonparam = $arrmissingadgroups | ConvertTo-Json

            Write-Output "Switch to Automation Account Subscription $($automationaccountscubscription)"
            Select-AzureRmSubscription -SubscriptionName $automationaccountscubscription -ErrorAction Stop

            $job = Start-AzureRmAutomationRunbook -ResourceGroupName $automationresgroup `
                                                  -Name $automationonpremrunbook `
                                                  -Parameters @{"NewADGroupsJSON"=$jsonparam; "Cleanup"=$RunCleanup; "CleanupOU"="None";"CleanupDestinationOU"=$activedirectorycleanupgroupdn;"CleanupExclusion"=$arrlcleanupexclusion} `
                                                  -AutomationAccountName $automationaccountname `
                                                  -RunOn $automationhybridworkergroup            
       }
    }
    else
    {
        Write-Output "Cleanup"

        Write-Output "Switch to Automation Account Subscription $($automationaccountscubscription)"
        Select-AzureRmSubscription -SubscriptionName $automationaccountscubscription -ErrorAction Stop        

        $jsonparam = $AllAzureResGroups | ConvertTo-Json
        $job = Start-AzureRmAutomationRunbook -ResourceGroupName $automationresgroup `
                                              -Name $automationonpremrunbook `
                                              -Parameters @{"NewADGroupsJSON"=$jsonparam; "Cleanup"=$RunCleanup;"CleanupOU"=$defaultgroupdn;"CleanupDestinationOU"=$activedirectorycleanupgroupdn; "CleanupExclusion"=$arrlcleanupexclusion} `
                                              -AutomationAccountName $automationaccountname `
                                              -RunOn $automationhybridworkergroup  
    }

    Write-Output "########################################################################### `n"

    #endregion
    #####################################################################################################################################

    }
    Catch
    {
        Write-Error $_
        GenerateLoganalyticsMessage -State Error `
                                    -Subscription $UseAzureSubscription `
                                    -ResGroup "" `
                                    -Permission "" `
                                    -InformationDetail "Error in Script: $($_.Exception.Message)"
    }

    SendLoganalyticsMessage