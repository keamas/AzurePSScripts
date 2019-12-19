<#
    SYNOPSIS
        This script is used to demonstrate an azure PSE Architecture
    .DESCRIPTION
        This script is used to demonstrate an azure PSE Architecture
    .EXAMPLE

        Deploy VpnGw1 Single Site VPN
        az-deployvpngw.ps1 -VPNGWType "VpnGw1 (Max. 650 Mbps, Gen1)" -ZonenRedunat "no" -GWName "DemoGW01" -MultiSiteVPN "no" 
                           -LocalNwPip1 "12.32.12.32" -LocalNwAddPrefix1 "192.168.1.0/24" -LocalNwPip2 "none" -LocalNwPip2 "none"
                           -SharedAccessKey "Key12345"

        Deploy VpnGw2 Mult Site VPN
        az-deployvpngw.ps1 -VPNGWType "VpnGw2 (Max. 650 Mbps, Gen1)" -ZonenRedunat "no" -GWName "DemoGW01" -MultiSiteVPN "yes" 
                           -LocalNwPip1 "12.32.12.32" -LocalNwAddPrefix1 "192.168.1.0/24" -LocalNwPip2 "21.32.12.32" -LocalNwPip2 "192.168.1.0/24"
                           -SharedAccessKey "Key12345"

        Deploy Zonal VpnGw2 Mult Site VPN
        az-deployvpngw.ps1 -VPNGWType "VpnGw2 (Max. 650 Mbps, Gen1)" -ZonenRedunat "yes" -GWName "DemoGW01" -MultiSiteVPN "yes" 
                           -LocalNwPip1 "12.32.12.32" -LocalNwAddPrefix1 "192.168.1.0/24" -LocalNwPip2 "21.32.12.32" -LocalNwPip2 "192.168.1.0/24"
                           -SharedAccessKey "Key12345"
        
    .NOTES  
        Please install the latest Az Modules!       
#>

#######################################################################################################################

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true,
    HelpMessage="There are generation one and two available.")]
    [ValidateSet('VpnGw1 (Max. 650 Mbps, Gen1)',
                 'VpnGw2 (Max. 1 Gbps, Gen1)',
                 'VpnGw3 (Max. 1.25 Gbps, Gen1)', 
                 'VpnGw2 (Max. 1.25 Gbps, Gen2)', 
                 'VpnGw3 (Max. 2.5 Gbps, Gen2)' ,
                 'VpnGw4 (Max. 5 Gbps, Gen2)', 
                 'VpnGw5 (Max. 10 Gbps, Gen2)')]    
    [string]$VPNGWType='',
    [Parameter(Mandatory=$true)]
    [ValidateSet('yes','no')]    
    [string]$ZonenRedunat='',

    [Parameter(Mandatory=$true)]  
    [string]$GWName='',

    [Parameter(Mandatory=$true)]
    [ValidateSet('yes','no')]    
    [string]$MultiSiteVPN='',

    [Parameter(Mandatory=$true)]  
    [string]$LocalNwPip1='',

    [Parameter(Mandatory=$true)]  
    [string]$LocalNwAddPrefix1='',

    [Parameter(Mandatory=$true)]
    [string]$LocalNwPip2='',

    [Parameter(Mandatory=$true)]
    [string]$SharedAccessKey=''
)


#######################################################################################################################
#region define global variables


Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

#VPN Gateway mapping

$gwtypemapping = @{
    'VpnGw1 (Max. 650 Mbps, Gen1)' = "VpnGw1"
    'VpnGw2 (Max. 1 Gbps, Gen1)' = "VpnGw2"
    'VpnGw3 (Max. 1.25 Gbps, Gen1)' = "VpnGw3"
    'VpnGw2 (Max. 1.25 Gbps, Gen2)' = "VpnGw2"
    'VpnGw3 (Max. 2.5 Gbps, Gen2)' = "VpnGw3"
    'VpnGw4 (Max. 5 Gbps, Gen2)' = "VpnGw4"
    'VpnGw5 (Max. 10 Gbps, Gen2)' = "VpnGw5" 
}


#endregion

#######################################################################################################################


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


    #region section select virtual network
        try 
        {            
            $vnets = Get-AzVirtualNetwork
    
            if (($vnets).count -gt 0)
            {
                Write-Host "#######################################################################"
                Write-Host "There are more virtual networks available:"
    
                $count = 0
                foreach ($vnet in $vnets) 
                {
                    Write-Host "$($count): $($vnet.Name) (ResourceGroup: $($vnet.ResourceGroupName) Location: $($vnet.Location))"
                    $count++
                }
    
                Write-Host "Please select the right virtual network (insert the number)."                
                Write-Host "#######################################################################"
                $resultvnet = Read-Host

                $selectedvnet = $vnets[$resultvnet]

                Clear-Host                                
            }
            else 
            {
                $selectedvnet = $vnets[0]
            }

            $vnetsubnet = (Get-AzVirtualNetwork -ResourceGroupName $selectedvnet.ResourceGroupName -Name $selectedvnet.Name).Subnets
            if ($vnetsubnet.Name -contains "GatewaySubnet")
            {    
                $selectedgwtype = $gwtypemapping.Item($VPNGWType)
                if($ZonenRedunat -eq "yes")
                {
                    $selectedgwtype += "AZ"
                }                     
                
                Write-Host "The virtual network gateway $() has the following settings:"
                Write-Host "Deployed to resource group: $($selectedvnet.ResourceGroupName)"
                Write-Host "Bound to virtual network: $($selectedvnet.Name)"
                Write-Host "Located in Azure Datacenter: $($selectedvnet.Location)"
                Write-Host "VPN Gateway Type: $($selectedgwtype)"
                Write-Host "Create Multisite VPN: $MultiSiteVPN"
                Write-Host "-----------------------------------------------------------------"
                Write-Host "Everything is correct? (yes/no"
                $result = Read-Host

                Clear-Host

                Write-Host "Start with S2S VPN Gateway deployment."
                if($result -eq "yes")
                {         
                    Write-Host "Get gateway subnet" 
                    $gatewaysubnet = $vnetsubnet | Where-Object -Property name -EQ -Value "GatewaySubnet"
                    Write-Host "OK"
                      
                    Write-Host "Create public IP(s) and Gateway IPConfiguration"
                    if ($ZonenRedunat -eq "yes")
                    {
                        #region Create Zonal redundant GW (Single or MultiSite)
                        $ngwpip = New-AzPublicIpAddress -Name "$($GWName)-pip01" -ResourceGroupName $selectedvnet.ResourceGroupName `
                                                        -Location $selectedvnet.Location -AllocationMethod Static -Sku Standard -Zone 1
                        
                        $ngwipconfig = New-AzVirtualNetworkGatewayIpConfig -Name "$($GWName)nwconfig01" -SubnetId $gatewaysubnet.Id `
                                                                           -PublicIpAddressId $ngwpip.Id                                                                         

                        if($MultiSiteVPN -eq "yes")
                        {
                            #region Mult Site

                            $ngwpip1 = New-AzPublicIpAddress -Name "$($GWName)-pip02" -ResourceGroupName $selectedvnet.ResourceGroupName `
                                                             -Location $selectedvnet.Location -AllocationMethod Static -Sku Standard -Zone 1
                            
                            $ngwipconfig1 = New-AzVirtualNetworkGatewayIpConfig -Name "$($GWName)nwconfig02" -SubnetId $gatewaysubnet.Id `
                                                                               -PublicIpAddressId $ngwpip1.Id  
                                                                               
                            Write-Host "Create Zonen redunant gateway"
                            
                            $nwgw = New-AzVirtualNetworkGateway -Name $GWName -ResourceGroupName $selectedvnet.ResourceGroupName `
                                                                -Location $selectedvnet.Location -IpConfigurations $ngwipconfig, $ngwipconfig1 -EnableActiveActiveFeature `
                                                                -GatewayType "Vpn" -VpnType "RouteBased" -GatewaySku $selectedgwtype
                            
                            #endregion
                        } 
                        else {
                            #region Single Site

                                Write-Host "Create Zonen redunant gateway"
                                $nwgw = New-AzVirtualNetworkGateway -Name $GWName -ResourceGroupName $selectedvnet.ResourceGroupName `
                                                                                  -Location $selectedvnet.Location -IpConfigurations $ngwipconfig -GatewayType "Vpn" -VpnType "RouteBased" `
                                                                                  -GatewaySku $selectedgwtype
                            #endregion
                        }                                                      
                        
                        #endregion
                    }
                    else
                    {
                        $ngwpip = New-AzPublicIpAddress -Name "$($GWName)-pip01" -ResourceGroupName $selectedvnet.ResourceGroupName `
                                                        -Location $selectedvnet.Location -AllocationMethod Dynamic -Sku Basic
                        
                        $ngwipconfig = New-AzVirtualNetworkGatewayIpConfig -Name "$($GWName)nwconfig01" -SubnetId $gatewaysubnet.Id `
                                                                           -PublicIpAddressId $ngwpip.Id  

                        if($MultiSiteVPN -eq "yes")
                        {
                            #region Mult Site
                                                   
                            $ngwpip1 = New-AzPublicIpAddress -Name "$($GWName)-pip02" -ResourceGroupName $selectedvnet.ResourceGroupName `
                                                             -Location $selectedvnet.Location -AllocationMethod Dynamic -Sku Basic
                                                                               
                            $ngwipconfig1 = New-AzVirtualNetworkGatewayIpConfig -Name "$($GWName)nwconfig02" -SubnetId $gatewaysubnet.Id `
                                                                                -PublicIpAddressId $ngwpip1.Id  
                                                                                                                                  
                            Write-Host "Create Zonen redunant gateway"
                                                                               
                            $nwgw = New-AzVirtualNetworkGateway -Name $GWName -ResourceGroupName $selectedvnet.ResourceGroupName `
                                                                -Location $selectedvnet.Location -IpConfigurations $ngwipconfig, $ngwipconfig1 -EnableActiveActiveFeature `
                                                                -GatewayType "Vpn" -VpnType "RouteBased" -GatewaySku $selectedgwtype
                                                                               
                            #endregion
                        } 
                        else {
                            #region Single Site
                                                   
                            Write-Host "Create Zonen redunant gateway"
                            $nwgw = New-AzVirtualNetworkGateway -Name $GWName -ResourceGroupName $selectedvnet.ResourceGroupName `
                                                                -Location $selectedvnet.Location -IpConfigurations $ngwipconfig -GatewayType "Vpn" `
                                                                -VpnType "RouteBased" -GatewaySku $selectedgwtype
                            #endregion
                        }
                    }    
                    
                    Write-Host "Create local network gateway for Public IP: $($ngwpip.IpAddress)"
                    $lnwgw = New-AzLocalNetworkGateway -Name "$($GWName)-lngw01" -ResourceGroupName $selectedvnet.ResourceGroupName `
                                                       -Location $selectedvnet.Location -GatewayIpAddress $LocalNwPip1 -AddressPrefix $LocalNwAddPrefix1

                    Write-Host "Crate connection for local network gateway $($lnwgw.Name)"
                    $connection = New-AzVirtualNetworkGatewayConnection -Name "$($GWName)-con01" -ResourceGroupName $selectedvnet.ResourceGroupName `
                                                                        -VirtualNetworkGateway1 $nwgw -LocalNetworkGateway2  $lnwgw -Location $selectedvnet.Location `
                                                                        -ConnectionType IPsec -SharedKey $SharedAccessKey

                    if($MultiSiteVPN -eq "yes")
                    {
                        Write-Host "Create local network gateway for Public IP: $($ngwpip1.IpAddress)"
                        $lnwgw2 = New-AzLocalNetworkGateway -Name "$($GWName)-lngw02" -ResourceGroupName $selectedvnet.ResourceGroupName `
                                                           -Location $selectedvnet.Location -GatewayIpAddress $LocalNwPip2 -AddressPrefix $LocalNwAddPrefix2

                        Write-Host "Crate connection for local network gateway $($lnwgw2.Name)"
                        $connection2 = New-AzVirtualNetworkGatewayConnection -Name "$($GWName)-con02" -ResourceGroupName $selectedvnet.ResourceGroupName `
                                                                            -VirtualNetworkGateway1 $nwgw -LocalNetworkGateway $lnwgw2 -Location $selectedvnet.Location `
                                                                            -ConnectionType IPsec -SharedKey $SharedAccessKey
                    }
                
                }
                else 
                {
                    Write-Host "Exit script"
                }
            } 
            else {
                Write-Host "The selected virtual network doesn't have a Gateway subnet! Script exit."
            }           
        }
        catch {
            Write-Error "Error in select subscription section. Error message: $($_.Exception.Message)"
        }
    
    #endregion

#endregion
#######################################################################################################################


Clear-Host

Write-Host "----------------------------------------------------------------------------------------------"
Write-Host "You can now configure your On-Prem environment"
Write-Host "You need the following details:"
Write-Host " "
Write-Host "Public IP to connect: $($ngwpip)"
Write-Host "Public IP 1 to connect $($ngwpip2) (only for Multi Site VPN)"
Write-Host "Shared Secred: $($SharedAccessKey)"
Write-Host "----------------------------------------------------------------------------------------------"


