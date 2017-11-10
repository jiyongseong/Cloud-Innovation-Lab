#region login
Login-AzureRmAccount

Select-AzureRmSubscription -Subscription "Azure Demo"
#endregion

$filePath = "C:\Users\jyseong\OneDrive\Case\FY18 Cxs\Samsung SDS\Docs\InfraSetup"
cd $filePath

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
    Create-Vnet $fileUrl $resourceGroup $location

    #creating Public Ip Address
    Create-Pip $fileUrl $resourceGroup $location
#endregion

#region network security group(s)
. .\networkSecurityGroup.ps1
    
    #creating network security group(s)
    Create-NSG $fileUrl $resourceGroup $location
#endregion

#region availability set(s)
. .\avSet.ps1
    
    #creating availability set(s)
    Create-AVSet $fileUrl $resourceGroup $location
#endregion

#region virtual machine(s)
. .\VM.ps1
    
    #creating virtual machine(s)
    Create-MyVM $fileUrl $resourceGroup $location
#endregion