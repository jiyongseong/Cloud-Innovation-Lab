Login-AzureRmAccount 

Select-AzureRmSubscription -Subscription "<<your subscription name>>"

$path = '<<your file path>>'
Push-Location -Path $path

$storageAccountForDeploy = '<<storage account prefix for deploying template>>'
$resourceGroupName = "<<resource group name for deploying>>"
$location = "<<region>>"
$templateFile = $path+'\azuredeploy.json'
$templateParameterFile = $path+'\azuredeploy.parameters.json'

./Deploy-AzureResourceGroup.ps1 -StorageAccountName $storageAccountForDeploy -ResourceGroupName $resourceGroupName -ResourceGroupLocation $location `
                                -TemplateFile $templateFile -TemplateParametersFile $templateParameterFile -ArtifactStagingDirectory '.' -DSCSourceFolder '.\DSC' -UploadArtifacts