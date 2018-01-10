$clientID       = "ApplicationID"
$clientSecret   = "key from Application"
$tennantId      = "tenant id"

$tokenEndpoint = {https://login.windows.net/{0}/oauth2/token} -f $tennantId 
$mgmtURI = "https://management.core.windows.net/";

$body = @{
        'resource'= $mgmtURI
        'client_id' = $clientID
        'grant_type' = 'client_credentials'
        'client_secret' = $clientSecret
}

$params = @{
    ContentType = 'application/x-www-form-urlencoded'
    Headers = @{'accept'='application/json'}
    Body = $body
    Method = 'Post'
    URI = $tokenEndpoint
}

$token = Invoke-RestMethod @params

$token | select access_token, @{L='Expires';E={[timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($_.expires_on))}} | fl *

#region Get Azure Subscription
$subscriptionID="cae76bde-fb86-4335-aef5-33674b746691"

$paramsRest = @{
    ContentType = 'application/json'
    Headers = @{
    'Authorization'="Bearer $($token.access_token)"
    }
    Method = 'Get'
    URI = "https://management.azure.com/subscriptions/$subscriptionID/providers/Microsoft.Commerce/RateCard?api-version=2016-08-31-preview&`$filter=OfferDurableId eq 'MS-AZR-0003P' and Currency eq 'KRW' and Locale eq 'ko-KR' and RegionInfo eq 'KR'"
}

$results = Invoke-RestMethod @paramsRest 
$vmSKUs = $results.Meters | Where-Object {$_.MeterCategory -eq '가상 컴퓨터'}


$row = New-Object PSObject

$row | Add-Member -MemberType NoteProperty -Name "EffectiveDate" -Value ""
$row | Add-Member -MemberType NoteProperty -Name "IncludedQuantity" -Value ""
$row | Add-Member -MemberType NoteProperty -Name "MeterCategory" -Value ""
$row | Add-Member -MemberType NoteProperty -Name "MeterId" -Value ""
$row | Add-Member -MemberType NoteProperty -Name "MeterName" -Value ""
$row | Add-Member -MemberType NoteProperty -Name "MeterRates" -Value ""
$row | Add-Member -MemberType NoteProperty -Name "Price" -Value ""
$row | Add-Member -MemberType NoteProperty -Name "Currency" -Value ""
$row | Add-Member -MemberType NoteProperty -Name "IsTaxIncluded" -Value ""
$row | Add-Member -MemberType NoteProperty -Name "MeterRegion" -Value ""
$row | Add-Member -MemberType NoteProperty -Name "MeterStatus" -Value ""
$row | Add-Member -MemberType NoteProperty -Name "MeterSubCategory" -Value ""
$row | Add-Member -MemberType NoteProperty -Name "Unit" -Value ""

$now = Get-Date -Format yyyyMMddHHmmss

$outputFilePath = ".\PriceList@$now.csv"
$resultSet = [System.Collections.ArrayList]@()

foreach($vmSKU in $vmSKUs)
{
    $row.EffectiveDate = $vmSKU.EffectiveDate
    $row.IncludedQuantity = $vmSKU.IncludedQuantity
    $row.MeterCategory = $vmSKU.MeterCategory
    $row.MeterId = $vmSKU.MeterId
    $row.MeterName = $vmSKU.MeterName
    $row.MeterRates = $vmSKU.MeterRates
    $row.Price = ($vmSKU.MeterRates -replace "@{0=", "").Replace("}", "")
    $row.Currency = $results.Currency
    $row.IsTaxIncluded = $results.IsTaxIncluded
    $row.MeterRegion = $vmSKU.MeterRegion
    $row.MeterStatus = $vmSKU.MeterStatus
    $row.MeterSubCategory = $vmSKU.MeterSubCategory
    $row.Unit = $vmSKU.Unit
    
    $resultSet.Add($row.PsObject.Copy()) | Out-Null
}

$resultSet | Export-Csv -Path $outputFilePath -NoTypeInformation  -Encoding UTF8 -Delimiter ","