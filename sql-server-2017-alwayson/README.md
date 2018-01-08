# sql-server-2017-alwayson

## SQL Server 2017 AlwaysOn 클러스터

* Domain Controller VMs : 2대, Windows Server 2016 Data Center
* SQL Server VMs : 2대, SQL Server 2017 Enterprise Edition
* Jumpbox VM : 1대
* Diagnostics용 Storage account for 
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