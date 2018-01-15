#region Azure Login
$azure_securePassword = ConvertTo-SecureString "CjKV9HghCaPbdBoYpXJGlJCZylx0FCmmnhajP8Jz3F0=" -AsPlainText -Force #app key
$azure_credential = New-Object System.Management.Automation.PSCredential("bc881e49-f0f4-406b-ae7b-fdc88e074622",$azure_securePassword) #app ID, App Key
$tenantID = "72f988bf-86f1-41af-91ab-2d7cd011db47" #Directory ID

Login-AzureRmAccount -Credential $azure_credential -ServicePrincipal -TenantId $tenantID

Select-AzureRmSubscription -Subscription "Azure Demo"
#endregion

Clear-Host

$path = 'C:\Users\jyseong\Documents\Visual Studio 2017\Projects\all-about-windows-server-vm\all-about-windows-server-vm\bin\Debug\'

Push-Location -Path $path

$storageAccountForDeploy = 'jyseongdeploy'
$resourceGroupName = "rg-allwindows1-krc"
$location = "koreacentral"
$templateFile = $path+'azuredeploy.json'
$templateParameterFile = $path+'azuredeploy.parameters.json'

./Deploy-AzureResourceGroup.ps1 -StorageAccountName $storageAccountForDeploy -ResourceGroupName $resourceGroupName -ResourceGroupLocation $location `
                                -TemplateFile $templateFile -TemplateParametersFile $templateParameterFile -ArtifactStagingDirectory '.' -DSCSourceFolder '.\DSC' -UploadArtifacts