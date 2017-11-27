Login-AzureRmAccount 

Select-AzureRmSubscription -Subscription "Azure Demo"

$location = "korea central"

Get-AzureRmVMSize -Location $location | Select Name