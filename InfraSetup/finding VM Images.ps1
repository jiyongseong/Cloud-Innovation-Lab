
$location = "korea central"
$publisherName = (Get-AzureRmVMImagePublisher -Location $location | Out-GridView -Title "Select Image Publisher" -PassThru).PublisherName
$offerName = (Get-AzureRmVMImageOffer -Location $location -PublisherName $publisherName | Out-GridView -Title "Select Image Offer" -PassThru).Offer
$skuName = (Get-AzureRmVMImageSku -Location $location -PublisherName $publisherName -Offer $offerName | Out-GridView -Title "Select Image" -PassThru).Skus
Get-AzureRmVMImage -Location $location -PublisherName $publisherName -Offer $offerName -Skus $skuName


$publisherName 
$offerName 
$skuName