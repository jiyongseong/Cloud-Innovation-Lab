
#region opening file
function Get-Info($fileUrl)
{
    $excel = New-Object -ComObject excel.application

    $excel.Visible = $False
    $excel.DisplayAlerts = $False

    $wb=$excel.workbooks.open($fileUrl,$null,$true)

    return $wb
}
#endregion


function create-VM($ResourceGroupName, $Region, $Name, $Size, $AvailabilitySetId, $Credential, $PublisherName, $Offer, $Skus, $VMNetworkInterfaceID, $numOfDisk, $diskSize, $diskStorageAccountType, $caching)
{
    Write-Host "Creating VM - $name....." -BackgroundColor Yellow -ForegroundColor Red

    $vmConfig = New-AzureRmVMConfig -VMName $Name -VMSize $Size -AvailabilitySetId $AvailabilitySetId | `
                    Set-AzureRmVMOperatingSystem -Linux -ComputerName $Name -Credential $Credential  | `
                    Set-AzureRmVMSourceImage -PublisherName $PublisherName -Offer $Offer -Skus $Skus -Version latest | ` 
                    Set-AzureRmVMOSDisk -Name $Name"-OSDisk" -CreateOption FromImage -Linux -Caching ReadWrite | `
                    Add-AzureRmVMNetworkInterface -Id $VMNetworkInterfaceID | Set-AzureRmVMBootDiagnostics -Disable 

    $vmCount
    $numOfDisk
    $diskSize

    for ($i=0; $i -le $numOfDisk -1; $i++)
    {
        
        $lun = $i
        $diskName = $Name+"-DataDisk-"+($i+1).ToString()
        Write-Host "Adding disk -"$diskName 

        $vmConfig | Add-AzureRmVMDataDisk -Name $diskName -Lun $lun -CreateOption Empty -DiskSizeInGB $diskSize -StorageAccountType $diskStorageAccountType -Caching $caching
    }

    New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Region -VM $vmConfig 

    Write-Host "Creating VM $name is done....." -BackgroundColor Yellow -ForegroundColor Red
    Write-Host "VM $name will be restarted....." -BackgroundColor Yellow -ForegroundColor Red
}

#region creating VM(s)
function Create-MyVM($fileUrl, $rgName, $region)
{
    $wb = Get-Info($fileUrl)

    $ws = $wb.Worksheets["VM"]
        
    Write-Host "Creating Virtual Machines." -ForegroundColor Red -BackgroundColor Yellow

    $publisherName = $ws.Cells.Item(2, 2).Value2
    $offerName = $ws.Cells.Item(3, 2).Value2
    $skuName = $ws.Cells.Item(4, 2).Value2
    $vNetName = $ws.Cells.Item(5, 2).Value2
    $subnetName = $ws.Cells.Item(6, 2).Value2
    $avsetName = $ws.Cells.Item(7, 2).Value2
    $vmPrefix = $ws.Cells.Item(8, 2).Value2
    $userName = $ws.Cells.Item(9, 2).Value2
    $vmSize = $ws.Cells.Item(10, 2).Value2
    $vmCount = $ws.Cells.Item(11, 2).Value2
    $numOfDisk = $ws.Cells.Item(12, 2).Value2
    $diskSize= $ws.Cells.Item(13, 2).Value2
    $diskStorageAccountType= $ws.Cells.Item(14, 2).Value2
    $caching= $ws.Cells.Item(15, 2).Value2

    $publisherName
    $offerName 
    $skuName 
    $vNetName
    $subnetName 
    $avsetName 
    $vmPrefix 
    $userName 
    $vmSize 
    $vmCount
    $numOfDisk
    $diskSize
    $diskStorageAccountType
    $caching

    #region virtual network
    $vNet = Get-AzureRmVirtualNetwork -Name $vNetName -ResourceGroupName $rgName 
    $subnet = $vNet.Subnets | Where-Object {$_.Name -eq $subnetName}
    #endregion

    #region avset
    $avset = Get-AzureRmAvailabilitySet -ResourceGroupName $rgName -Name $avsetName 
    #endregion

    #region VM(s)
    $cred = Get-Credential -UserName $userName -Message "Enter credential for VM user" 

    if ($vmCount -eq 1)
    {
        $vmName = $vmPrefix
        $nicName="$vmName-Nic"
        $nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $location -SubnetId $subnet.Id
        create-VM $rgName $location $vmName $vmSize $avset.Id  $cred $publisherName $offerName $skuName $nic.Id $numOfDisk $diskSize $diskStorageAccountType $caching
    }
    elseif ($vmCount -gt 1)
    {
        if ($vmCount -gt 9)
        {
            $vmPrefix += "0"
        }
        for ($i = 1; $i -le $vmCount; $i++)
        {
            $vmName = $vmPrefix + $i.ToString()
            $nicName="$vmName-Nic"
            $nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $location -SubnetId $subnet.Id

            create-VM $rgName $location $vmName $vmSize $avset.Id $cred $publisherName $offerName $skuName $nic.Id $numOfDisk $diskSize $diskStorageAccountType $caching
        }
    }   
    #endregion

    Get-AzureRmVM -ResourceGroupName $rgName | Where-Object {$_.Name -like $vmPrefix+"*"} | Restart-AzureRmVM
    Write-Host "Done." -ForegroundColor Red -BackgroundColor Yellow
}
#endregion