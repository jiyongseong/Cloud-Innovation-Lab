# RateCard API를 이용한 VM 가격 확인

## 참조
* [Azure Billing API를 사용하여 프로그래밍 방식으로 Azure 사용량에 대한 통찰력을 얻기](https://docs.microsoft.com/ko-kr/azure/billing/billing-usage-rate-card-overview)
* [Resource RateCard (Preview)](https://msdn.microsoft.com/library/en-us/Mt219005.aspx)
* [Get price and metadata information for resources used in an Azure subscription](https://msdn.microsoft.com/en-us/library/mt219004.aspx)

## 주의할 점
RateCard API는 Offering을 명시하게 되어 있음. offering에 따라서 할인 비율 및 청구 기준이 달라짐.
스크립트에서 명시해주어야 하는 Offering Code는 [https://azure.microsoft.com/en-us/support/legal/offer-details/](https://azure.microsoft.com/en-us/support/legal/offer-details/)을 참고.
URI에 Offering Code가 추가되어야 하는데 'MS-AZR-' prefix를 반드시 추가해주어야 함.

```powershell
$paramsRest = @{
    ContentType = 'application/json'
    Headers = @{
    'Authorization'="Bearer $($token.access_token)"
    }
    Method = 'Get'
    URI = "https://management.azure.com/subscriptions/$subscriptionID/providers/Microsoft.Commerce/RateCard?api-version=2016-08-31-preview&`$filter=OfferDurableId eq 'MS-AZR-0003P' and Currency eq 'KRW' and Locale eq 'ko-KR' and RegionInfo eq 'KR'"
}
```

상기의 URI에서 
* OfferDurableId는 https://azure.microsoft.com/en-us/support/legal/offer-details/ 사이트를 참고
* Currency는 화폐 단위를 의미하며, 미국 달러의 경우에는 USD로 변경

Access Token을 만드는 방법은 [Using the Azure ARM REST API – Get Access Token](https://blogs.technet.microsoft.com/stefan_stranger/2016/10/21/using-the-azure-arm-rest-apin-get-access-token/) 사이트를 참조
