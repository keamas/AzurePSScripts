  
    ############################################################################################################
    # Script to create On-Prem AD Groups
    #
    # Author: Hannes Lagler-gruener
    #
    #
    # Functionality:
    #               Create On-Prem AD Groups with their parameters
    #               
    #
    # Modifications:
    #
    #               Date: 07.09.2017
    #               Changes: Initial create runnbook
    #
    #
    # Requironments:
    #              
    #
    ########################################################################################################### 


Param
(  
    $NewADGroupsJSON,
    [string]$Cleanup,
    [string]$CleanupOU,
    [string]$CleanupDestinationOU,
    [string[]]$CleanupExclusion
)

    #####################################################################################################################################
    #region Define public variables

        #OMSConfigurations
        $LogAnalyWorkSpace = Get-AutomationConnection -Name "ProdLogAWorkspaceID" -ErrorAction Stop        
        $LogType = "DokaRBACAutomation"
        $MonitorType = "Client"
        $TimeStampField = "YYYY-MM-DDThh:mm:ssZ"
        #$Computername = $env:computername
        $Computername = "AzureAutomation"

    #####################################################################################################################################

    #####################################################################################################################################
    #region Functions
    
    $omsmessagearray = [System.Collections.ArrayList]@()
    Function GenerateLoganalyticsMessage
    {
        param(
            [parameter(Mandatory=$true)]
            [ValidateSet('Success','Error', 'Warning')]
            [String]
            $State,
            [parameter(Mandatory=$true)]
            [ValidateSet('AddGroups','CleanUp')]
            [String]
            $Function,
            [parameter(Mandatory=$true)]            
            [String]
            $ADGroupName,
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
    #region Stop Prozess

    try
    {
        [object[]]$convertfromjson = $NewADGroupsJSON | ConvertFrom-Json

        if ($Cleanup -eq "false")
        {            
            for ($count = 0; $count -le ($convertfromjson.Length -1); $count++)
            {
                Write-Output "Start Process"
                Write-Output "###########################################################################"
                Write-Output "---------------------------------------------------------------------------"

                $groupname = $convertfromjson[$count].ADGroupGroupName

                Write-Output "Check if Group $($groupname) always exist." 

                if (!(Get-ADGroup -LDAPFilter "(SAMAccountName=$groupname)"))
                {

                    Write-Output "Create new AD Group with the following parameters: "`                                 "GroupFullname: $($convertfromjson[$count].ADGroupGroupName)" `                                 "GroupDisplayname: $($convertfromjson[$count].ADGroupGroupName)" `
                                 "displayNamePrintable: $($convertfromjson[$count].ADGroupDNPrintA)" `
                                 "GroupDescription: $($convertfromjson[$count].ADGroupDescription)" `
                                 "Path: $($convertfromjson[$count].ADGroupDN)"

                    New-ADGroup -Name $convertfromjson[$count].ADGroupGroupName `
                                -Path $convertfromjson[$count].ADGroupDN `
                                -Description $($convertfromjson[$count].ADGroupDescription ) `
                                -SamAccountName $convertfromjson[$count].ADGroupGroupName `
                                -GroupCategory Security `
                                -GroupScope Global `
                                -DisplayName $convertfromjson[$count].ADGroupGroupName `
                                -OtherAttributes @{'displayNamePrintable'=$convertfromjson[$count].ADGroupDNPrintA}

                    GenerateLoganalyticsMessage -State Success `
                                                -Function AddGroups `
                                                -ADGroupName $convertfromjson[$count].ADGroupGroupName `
                                                -InformationDetail "Create Active Directory Group $($convertfromjson[$count].ADGroupGroupName) in OU $($convertfromjson[$count].ADGroupDN)"
                 }           
                 else
                 {
                     Write-Output "Group exist in AD"

                     GenerateLoganalyticsMessage -State Error `
                                                 -Function AddGroups `
                                                 -ADGroupName $convertfromjson[$count].ADGroupGroupName `
                                                 -InformationDetail "Cannot create Active Directory Group $($convertfromjson[$count].ADGroupGroupName) because the group always exist!"
                 }
                           

                Write-Output "---------------------------------------------------------------------------"
                Write-Output "###########################################################################"
            }
        }
        else
        {
            Write-Output "Starting Cleanup Process"
            Write-Output "###########################################################################"
            Write-Output "---------------------------------------------------------------------------"
            Write-Output "Get all AD groups from DN: $($CleanupOU)"

            $adgroups = Get-ADGroup -SearchBase $CleanupOU -Filter * -Properties displayNamePrintable, description

            [string[]]$availableresgroups = @()

            for ($count = 0; $count -le ($convertfromjson.Length -1); $count++)
            {   
               $availableresgroups = $availableresgroups += $convertfromjson[$count].ResourceGroupName.ToLower()
            }

            foreach ($adgroup in $adgroups)
            {
                if ($CleanupExclusion -notcontains $adgroup.SamAccountName)
                {
                    if ($adgroup.displayNamePrintable -ne "")
                    {
                        $movegroup = $false
                        foreach ($resgroup in $availableresgroups)
                        {
                            if ($resgroup.Contains($adgroup.displayNamePrintable))
                            {
                                $movegroup = $false
                                break;
                            }
                            else
                            {
                                $movegroup = $true
                            }
                        }

                        if (!$movegroup)
                        {
                            Write-Output "Do not move Group $($adgroup.SamAccountName)"
                        }
                        else
                        {
                            Write-Warning "Move Group $($adgroup.SamAccountName)"
                            Set-ADGroup -Identity $adgroup -Description "$($adgroup.Description), MoveDate: $(Get-Date)"
                            Move-ADObject -Identity $adgroup.DistinguishedName -TargetPath $CleanupDestinationOU

                            GenerateLoganalyticsMessage -State Success `
                                                        -Function CleanUp `
                                                        -ADGroupName $adgroup.SamAccountName `
                                                        -InformationDetail "Move Active Directory Group $($adgroup.SamAccountName) to OU $($CleanupDestinationOU)"
                        }
                    }
                    else
                    {
                        Write-Warning "displayNamePrintable wasn't set for Group $($adgroup.SamAccountName)"
                        GenerateLoganalyticsMessage -State Warning `
                                                    -Function CleanUp `
                                                    -ADGroupName $adgroup.SamAccountName `
                                                    -InformationDetail "The displayNamePrintable wasn't set for Group $($adgroup.SamAccountName) and will be automatically excluded from cleanupprocess."
                    }
                }
                else
                {
                    Write-Output "Group $($adgroup.SamAccountName) was excludet from cleanup prozess."
                }
            }

            Write-Output "---------------------------------------------------------------------------"
            Write-Output "###########################################################################"
        }
    }
    Catch
    {
        Write-Error $_

        Write-Warning "displayNamePrintable wasn't set for Group $($adgroup.SamAccountName)"
                        GenerateLoganalyticsMessage -State Warning `
                                                    -Function CleanUp `
                                                    -ADGroupName "" `
                                                    -InformationDetail "Error in Script: $($_.Exception.Message)"
    }

    #####################################################################################################################################