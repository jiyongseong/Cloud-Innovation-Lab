#region AV Set
function Create-AVSet($fileUrl, $rgName, $region, $wb)
{
    $ws = $wb.Worksheets["Availability Set"]
        
    Write-Host "Creating Availability Sets." -ForegroundColor Red -BackgroundColor Yellow

    for($i = 2; $i -le $ws.Rows.Count; $i++)
    {
        if ($ws.Cells.Item($i, 1).Value2 -eq $null)
        {
            break
        }
        $avSetName = $ws.Cells.Item($i, 1).Value2
        $avSetSku = $ws.Cells.Item($i, 2).Value2
        $platformUpdateDomainCount = $ws.Cells.Item($i, 3).Value2
        $platformFaultDomainCount = $ws.Cells.Item($i, 4).Value2

        New-AzureRmAvailabilitySet -ResourceGroupName $rgName -Location $region -Name $avSetName -Sku $avSetSku -PlatformUpdateDomainCount $platformUpdateDomainCount -PlatformFaultDomainCount $platformFaultDomainCount
    }
    Write-Host "Done." -ForegroundColor Red -BackgroundColor Yellow
}
#endregion