#region network security group
function Create-NSG($fileUrl, $rgName, $region, $wb)
{
    $ws = $wb.Worksheets["Network Security Group"]

    $nsgRuleObjects = [System.Collections.ArrayList]@()
        
    Write-Host "Creating Network Security Groups." -ForegroundColor Red -BackgroundColor Yellow

    for($i = 2; $i -le $ws.Rows.Count; $i++)
    {
        #check last
        if ($i -ne 2 -and $ws.Cells.Item($i, 1).Value2 -eq $null)
        {
            $nsgName
            New-AzureRmNetworkSecurityGroup -ResourceGroupName $rgName -Location $region -Name $nsgName -SecurityRules $nsgRuleObjects
            break
        }

        #check different nsg
        if ($nsgName -ne $null -and $nsgName -ne $ws.Cells.Item($i, 1).Value2)
        {
            $nsgName 
            New-AzureRmNetworkSecurityGroup -ResourceGroupName $rgName -Location $region -Name $nsgName -SecurityRules $nsgRuleObjects
            $nsgRuleObjects = $null
        }

        $nsgName = $ws.Cells.Item($i, 1).Value2
        $ruleName = $ws.Cells.Item($i, 2).Value2
        $protocol = $ws.Cells.Item($i, 3).Value2
        $direction = $ws.Cells.Item($i, 4).Value2
        $priority = $ws.Cells.Item($i, 5).Value2
        $sourceAddressPrefix = $ws.Cells.Item($i, 6).Value2
        $sourcePortRange = $ws.Cells.Item($i, 7).Value2
        $destinationAddressPrefix = $ws.Cells.Item($i, 8).Value2
        $destinationPortRange = $ws.Cells.Item($i, 9).Value2
        $access = $ws.Cells.Item($i, 10).Value2
        $description = $ws.Cells.Item($i, 11).Value2

        $nsgRule = New-AzureRmNetworkSecurityRuleConfig -Name $ruleName -Protocol $protocol -Direction $direction -Priority $priority -SourceAddressPrefix $sourceAddressPrefix -SourcePortRange $sourcePortRange -DestinationAddressPrefix $destinationAddressPrefix -DestinationPortRange $destinationPortRange -Access $access -Description $description
        $nsgRuleObjects += $nsgRule
    }
    Write-Host "Done." -ForegroundColor Red -BackgroundColor Yellow
}
#endregion