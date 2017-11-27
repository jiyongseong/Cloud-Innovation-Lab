#region virtual Network

function Create-Vnet($rgName, $region, $wb)
{
    $ws = $wb.Worksheets["Virtual Network"]

    $vNetname = $ws.Cells.Item(2, 1).Value2
    $vNetIPAddress = $ws.Cells.Item(2, 2).Value2

    $subNetObjects = [System.Collections.ArrayList]@()
        
    Write-Host "Creating Virtual Network and subnets." -ForegroundColor Red -BackgroundColor Yellow

    for($i = 5; $i -le $ws.Rows.Count; $i++)
    {
    
        $SubnetName = $ws.Cells.Item($i, 1).Value2
        $subNetAddressPrefix = $ws.Cells.Item($i, 2).Value2

        if ($SubnetName -eq $null)
        {
            break
        }

        Write-Host "Subnet Name : " $SubnetName
        Write-Host "Subnet AddressPrefix : "$subNetAddressPrefix
        
        $subnetObject = New-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $subNetAddressPrefix
        $subNetObjects += $subnetObject
    }
    
    New-AzureRmVirtualNetwork -ResourceGroupName $rgName -Location $region -Name $vNetname -AddressPrefix $vNetIPAddress -Subnet $subNetObjects
    
    Write-Host "Done." -ForegroundColor Red -BackgroundColor Yellow
}
#endregion

#region public ip address
function Create-Pip($rgName, $region)
{
    $ws = $wb.Worksheets["Virtual Network"]
    
    Write-Host "Creating Public Ipaddress." -ForegroundColor Red -BackgroundColor Yellow

    for($i = 2; $i -le $ws.Rows.Count; $i++)
    {
        $pipName = $ws.Cells.Item($i, 4).Value2
        $allocationMethod = $ws.Cells.Item($i, 5).Value2
        $fqdn = $ws.Cells.Item($i, 6).Value2

        if ($pipName -eq $null)
        {
            break
        }
        <#
        Write-Host "PIP Name : " $pipName
        Write-Host "Allocation Method : "$allocationMethod
        Write-Host "FQDN : "$fqdn
        #>

        if ($fqdn -eq  $null)
        {
            New-AzureRmPublicIpAddress -Name $pipName -ResourceGroupName $rgName -Location $region -AllocationMethod $allocationMethod
        }
        else
        {
             New-AzureRmPublicIpAddress -Name $pipName -ResourceGroupName $rgName -Location $region -AllocationMethod $allocationMethod -DomainNameLabel $fqdn
        }

    }
    Write-Host "Done." -ForegroundColor Red -BackgroundColor Yellow
}
#endregion