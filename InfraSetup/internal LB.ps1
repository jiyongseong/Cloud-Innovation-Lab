#region login
Login-AzureRmAccount

Select-AzureRmSubscription -Subscription "Azure Demo"
#endregion


#region resource group, location
$location = "korea central"
$resourceGroup = "rg-linux-kr"

New-AzureRmResourceGroup -Name $resourceGroup -Location $location
#endregion


#region virtual network
$vNetName = "vnet-sql"
$subnetName = "RedHat-Subnet"

$vNet = Get-AzureRmVirtualNetwork -Name $vNetName -ResourceGroupName $resourceGroup 
$subnet = $vNet.Subnets | Where-Object {$_.Name -eq $subnetName}
#endregion

#region LB
$feName = "Redhat-FE"
$feIpAddress = "10.0.3.100"

$frontendIP = New-AzureRmLoadBalancerFrontendIpConfig -Name $feName -PrivateIpAddress $ilbIpAddress -SubnetId $subnet.Id

$beName = "Redhat-BE"
$beaddresspool= New-AzureRmLoadBalancerBackendAddressPoolConfig -Name $beName

$healthProbeName = "Redhat-Probe"
$healthProbe = New-AzureRmLoadBalancerProbeConfig -Name $healthProbeName -Protocol tcp -Port 80 -IntervalInSeconds 5 -ProbeCount 2

$lbRuleName = "Redhat-LBRule"
$lbrule = New-AzureRmLoadBalancerRuleConfig -Name $lbRuleName -FrontendIpConfiguration $frontendIP -BackendAddressPool $beAddressPool -Probe $healthProbe -Protocol Tcp -FrontendPort 80 -BackendPort 80

$ilbName = "Redhat-ILB"
$NRPLB = New-AzureRmLoadBalancer -ResourceGroupName $resourceGroup -Name $ilbName -Location $location -FrontendIpConfiguration $frontendIP -LoadBalancingRule $lbrule -BackendAddressPool $beAddressPool -Probe $healthProbe
#endregion

#region Backend Pool update
$nic1 = Get-AzureRmNetworkInterface -ResourceGroupName $resourceGroup -Name "Linux-VM1-Nic"
$nic1.IpConfigurations[0].LoadBalancerBackendAddressPools = $NRPLB.BackendAddressPools
Set-AzureRmNetworkInterface -NetworkInterface $nic1

$nic2 = Get-AzureRmNetworkInterface -ResourceGroupName $resourceGroup -Name "Linux-VM2-Nic"
$nic2.IpConfigurations[0].LoadBalancerBackendAddressPools = $NRPLB.BackendAddressPools
Set-AzureRmNetworkInterface -NetworkInterface $nic2
#endregion


