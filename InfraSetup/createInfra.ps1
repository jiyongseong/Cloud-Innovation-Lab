#region login
Login-AzureRmAccount

Select-AzureRmSubscription -Subscription "Azure Demo"
#endregion

$filePath = "C:\Users\jyseong\source\repos\Cloud-Innovation-Lab\InfraSetup"
cd $filePath

#region Excel
$excel = New-Object -ComObject excel.application

$excel.Visible = $False
$excel.DisplayAlerts = $False

$wb=$excel.workbooks.open($fileUrl,$null,$true)
#endregion

#region resource group, location
$location = "korea central"
$resourceGroup = "rg-linux-kr"

New-AzureRmResourceGroup -Name $resourceGroup -Location $location
#endregion

#region infomation file
#$currentPath = (Get-Item -Path ".\" -Verbose).FullName
$file = "infra.xlsx"
$fileUrl =  $filePath+"\"+$file
#endregion

#region virtual network, subnet(s), public ip address(es)
. .\virtualNetwork.ps1
    
    #creating Virtual Network and subnets
    Create-Vnet $fileUrl $resourceGroup $location $wb

    #creating Public Ip Address
    Create-Pip $fileUrl $resourceGroup $location $wb
#endregion

#region network security group(s)
. .\networkSecurityGroup.ps1
    
    #creating network security group(s)
    Create-NSG $fileUrl $resourceGroup $location $wb
#endregion

#region availability set(s)
. .\avSet.ps1
    
    #creating availability set(s)
    Create-AVSet $fileUrl $resourceGroup $location $wb
#endregion

#region virtual machine(s)
. .\VM.ps1
    
    #creating virtual machine(s)
    Create-MyVM $fileUrl $resourceGroup $location $wb
#endregion

#region House-keeping
$wb.Close()
$excel.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($wb) | Out-Null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
#endregion