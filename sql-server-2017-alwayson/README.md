# sql-server-2017-alwayson

## SQL Server 2017 AlwaysOn 클러스터

* Domain Controller VMs : 2대, Windows Server 2016 Data Center
* SQL Server VMs : 2대, SQL Server 2017 Enterprise Edition
* Jumpbox VM : 1대
* Diagnostics용 Storage account 
* Cloud witness용 Storage account

![](https://jyseongfileshare.blob.core.windows.net/images/CIL-AOAG-services.png)

## 템플릿 구성도

![](https://jyseongfileshare.blob.core.windows.net/images/CIL-AOAG-template.png)

## 매개변수 (parameters)
* AdminUsername / AdminPassword : 로컬 관리자 및 도메인 관리자 이름 / 비밀번호
* SqlServiceUserName / SqlServiceUserPassword : SQL Server 서비스 시작 사용자 이름 / 비밀번호
* SqlAuthenticationLogin / SqlAuthenticationPassword : SQL Server System admin 사용자 이름 / 비밀번호

## 변수 (variables)
* Nested Templates Path Variables : 하위 템플릿의 경로 정보
* Networks Variables : 네트워크 관련 정보
    * 가상 네트워크, 서브넷(이름, 주소 대역)
    * 가용성 집합
    * Public IP 이름
    * 저장소 계정 이름(diagnostics 용도, cloud witness 용도)
* Load Balancer Variables
    * SQL Server AlwaysOn Cluster용 internal load balancer 정보
* VM Variables
    * VM 정보 (이름, Private IP, NIC 이름 등)
* DC VMs Variables, SQL VMs Variables
    * DC VM 정보 : VM 크기, 도메인 이름, VM 이미지 게시자 / 이미지 오퍼 / 이미지 Sku
    * SQL Server VM 정보 : VM 크기, VM 이미지 게시자 / 이미지 오퍼 / 이미지 Sku
* Cluster Variables
    * Windows Failover Cluster 및 SQL Server AlwaysOn Cluster 관련 정보
* DC DSC Module Variables, SQL DSC Module Variables
    * DC 구성, Failover Cluster / SQL Server AlwaysOn 구성 파일 및 함수 이름 정보

## 사용 방법
전체 스크립트를 다운로드하여, Deploy-resource-template.ps1 파일의 관련 정보 수정 후 실행
수정할 정보
* $path : 스크립트를 다운로드한 위치
* $storageAccountForDeploy : 스크립트들을 배포할 storage account 이름
* $resourceGroupName : 리소스 그룹 이름
* $location : 배포할 지역

## To Do 목록
* AlwaysOn CopyIndex + Reference 오류 : "the resource template cannot reference itself"
    * CopyIndex의 Serial Mode로 설정한 경우에 발생
    * parallel mode로 하는 경우, SQL2VM에서 AlwaysOn cluster를 찾지 못하는 오류 발생
    * 현재는 수동으로 Serial 하게 처리되도록 함
* File Share 생성
    * AlwaysOn Database를 위한 공유 폴더 생성
* Tempdb Best Practice
    * Tempdb Data/Log 위치 및 크기 조정