#
# Copyright='© Microsoft Corporation. All rights reserved.'
#

configuration CreateSQLServerCluster
{
    param
    (
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$SQLServicecreds,

        [UInt32]$DatabaseEnginePort = 1433,

        [String]$DomainNetbiosName=(Get-NetBIOSName -DomainName $DomainName),

        [Parameter(Mandatory=$true)]
        [String]$ClusterName,

        [Parameter(Mandatory=$true)]
        [String]$ClusterOwnerNode,

        [Parameter(Mandatory=$true)]
        [String]$ClusterIP,

        [Parameter(Mandatory)]
        [String]$SQLServerVirtualName,

        [Parameter(Mandatory)]
        [String]$AvailabilityGroupName,


        [Parameter(Mandatory=$true)]
        [String]$witnessStorageBlobEndpoint,

        [Parameter(Mandatory=$true)]
        [String]$witnessStorageAccountKey,
        
        [Int]$RetryCount=5,
        [Int]$RetryIntervalSec=10
    )

    $DomainAdminName = $DomainNetbiosName+'\'+ $Admincreds.UserName
    $SQLSvcAcctName = $DomainNetbiosName +'\'+$SQLServicecreds.UserName

    Import-DscResource -ModuleName xStorage, xComputerManagement, xActiveDirectory, xNetworking, SqlServer, SqlServerDsc, xFailoverCluster
    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ($DomainAdminName, $Admincreds.Password)
    [System.Management.Automation.PSCredential]$SysAdminAccount = New-Object System.Management.Automation.PSCredential ($Admincreds.UserName, $Admincreds.Password)
    [System.Management.Automation.PSCredential]$SQLCreds = New-Object System.Management.Automation.PSCredential ($SQLSvcAcctName, $SQLServicecreds.Password)

    $RebootVirtualMachine = $false

    if ($DomainName)
    {
        $RebootVirtualMachine = $true
    }

    $ipcomponents = $ClusterIP.Split('.')
    $ipcomponents[3] = [convert]::ToString(([convert]::ToInt32($ipcomponents[3])) + 1)
    $ipdummy = $ipcomponents -join "."
    #$ClusterNameDummy = "c" + $ClusterName

    $suri = [System.uri]$witnessStorageBlobEndpoint
    $uricomp = $suri.Host.split('.')

    $witnessStorageAccount = $uriComp[0]
    $witnessEndpoint = $uricomp[-3] + "." + $uricomp[-2] + "." + $uricomp[-1]

    $computerName = $env:COMPUTERNAME
    $domainUserName = $DomainCreds.UserName.ToString()

    WaitForSqlSetup

    Node localhost
    {
       xWaitforDisk Disk2
        {
             DiskId = 2
             RetryIntervalSec =$RetryIntervalSec
             RetryCount = $RetryCount
        }
        
        xDisk DataDisk
        {
            DiskId = 2
            DriveLetter = 'F'
            FSLabel = 'DataDisk'
            AllocationUnitSize = 65536
            DependsOn = '[xWaitForDisk]Disk2'
        }
                
        xWaitforDisk Disk3
        {
             DiskId = 3
             RetryIntervalSec =$RetryIntervalSec
             RetryCount = $RetryCount
        }
        
        xDisk LogDisk
        {
            DiskId = 3
            DriveLetter = 'G'
            FSLabel = 'LogDisk'
            AllocationUnitSize = 65536
            DependsOn = '[xWaitForDisk]Disk3'
        }

        xWaitforDisk Disk4
        {
             DiskId = 4
             RetryIntervalSec =$RetryIntervalSec
             RetryCount = $RetryCount
        }
        
        xDisk BackupDisk
        {
            DiskId = 4
            DriveLetter = 'K'
            FSLabel = 'BackupDisk'
            AllocationUnitSize = 65536
            DependsOn = '[xWaitForDisk]Disk4'
        }

        File SQLDataPath
        {
            Checksum        = 'SHA-256'
            DestinationPath = 'F:\SQLData\'
            Ensure          = 'Present'
            Force           = $true
            Type            = 'Directory'
            DependsOn = '[xDisk]DataDisk'
        }

        File SQLLogPath
        {
            Checksum        = 'SHA-256'
            DestinationPath = 'G:\LogData\'
            Ensure          = 'Present'
            Force           = $true
            Type            = 'Directory'
            DependsOn = '[xDisk]LogDisk'
        }

        File SQLBackupPath
        {
            Checksum        = 'SHA-256'
            DestinationPath = 'K:\BackupData\'
            Ensure          = 'Present'
            Force           = $true
            Type            = 'Directory'
            DependsOn = '[xDisk]BackupDisk'
        }

        WindowsFeature FC
        {
            Name = 'Failover-Clustering'
            Ensure = 'Present'
        }

        WindowsFeature FailoverClusterTools 
        { 
            Ensure = 'Present' 
            Name = 'RSAT-Clustering-Mgmt'
            DependsOn = '[WindowsFeature]FC'
        } 

        WindowsFeature FCPS
        {
            Name = 'RSAT-Clustering-PowerShell'
            Ensure = 'Present'
        }

        WindowsFeature FCPSCMD
        {
            Ensure    = 'Present'
            Name      = 'RSAT-Clustering-CmdInterface'
            DependsOn = '[WindowsFeature]FCPS'
        }

        WindowsFeature ADPS
        {
            Name = 'RSAT-AD-PowerShell'
            Ensure = 'Present'
        }
        
        xFirewall DatabaseEngineFirewallRule
        {
            Direction = 'Inbound'
            Name = 'SQL-Server-Database-Engine-TCP-In'
            DisplayName = 'SQL Server Database Engine (TCP-In)'
            Description = 'Inbound rule for SQL Server to allow TCP traffic for the Database Engine.'
            Group = 'SQL Server'
            Enabled = 'True'
            Protocol = 'TCP'
            LocalPort = $DatabaseEnginePort -as [String]
            Ensure = 'Present'
        }

        xFirewall DatabaseMirroringFirewallRule
        {
            Direction = 'Inbound'
            Name = 'SQL-Server-Database-Mirroring-TCP-In'
            DisplayName = 'SQL Server Database Mirroring (TCP-In)'
            Description = 'Inbound rule for SQL Server to allow TCP traffic for the Database Mirroring.'
            Group = 'SQL Server'
            Enabled = 'True'
            Protocol = 'TCP'
            LocalPort = '5022'
            Ensure = 'Present'
        }

        xFirewall ListenerFirewallRule
        {
            Direction = 'Inbound'
            Name = 'SQL-Server-Availability-Group-Listener-TCP-In'
            DisplayName = 'SQL Server Availability Group Listener (TCP-In)'
            Description = 'Inbound rule for SQL Server to allow TCP traffic for the Availability Group listener.'
            Group = 'SQL Server'
            Enabled = 'True'
            Protocol = 'TCP'
            LocalPort = '59999'
            Ensure = 'Present'
        }
        
        SqlServerLogin AddDomainAdminAccountToSqlServer
        {
            Ensure = 'Present'
            Name = $DomainCreds.UserName
            LoginType = 'WindowsUser'
			ServerName = $env:COMPUTERNAME
			InstanceName = 'MSSQLSERVER'
            LoginPasswordPolicyEnforced = $false
            LoginMustChangePassword = $false
            LoginPasswordExpirationEnabled = $false
            Disabled = $false
        }
                
        SqlServerLogin AddSQLSvcAccountToSqlServer
        {
            Ensure = 'Present'
            Name = $SQLCreds.UserName
            LoginType = 'WindowsUser'
			ServerName = $env:COMPUTERNAME
			InstanceName = 'MSSQLSERVER'
            LoginPasswordPolicyEnforced = $false
            LoginMustChangePassword = $false
            LoginPasswordExpirationEnabled = $false
            Disabled = $false
        }

        SqlServerLogin AddClusterSvcAccountToSqlServer
        {
            Name = "NT SERVICE\ClusSvc"
            LoginType = "WindowsUser"
			ServerName = $env:COMPUTERNAME
			InstanceName = "MSSQLSERVER"
        }

        SqlServerRole AddDomainAccountToSysAdmin
        {
			Ensure = 'Present'
            MembersToInclude = $DomainCreds.UserName, $SQLCreds.UserName, "NT SERVICE\ClusSvc"
            ServerRoleName = 'sysadmin'
			ServerName = $env:COMPUTERNAME
			InstanceName = 'MSSQLSERVER'
            PsDscRunAsCredential = $SysAdminAccount
			DependsOn = '[SqlServerLogin]AddDomainAdminAccountToSqlServer', '[SqlServerLogin]AddSQLSvcAccountToSqlServer', '[SqlServerLogin]AddClusterSvcAccountToSqlServer'
        }      

        SqlServerNetwork AddSqlServerEndpoint
        {
            InstanceName = 'MSSQLSERVER'
            ProtocolName = 'Tcp'
            IsEnabled = $true
            TCPDynamicPort = $false
            TcpPort = $DatabaseEnginePort
        }

        SqlServiceAccount ConfigureSQLSvcAccount
        {
            ServerName = $env:COMPUTERNAME
            InstanceName = 'MSSQLSERVER'
            ServiceType = 'DatabaseEngine'
            ServiceAccount = $SQLCreds
            DependsOn = '[SqlServerRole]AddDomainAccountToSysAdmin'
        }

        AddSvcAccountToUserRight ($SQLCreds.UserName)

        SqlServerConfiguration MaxDOPConfigruation
        {
            ServerName     = $env:COMPUTERNAME
            InstanceName   = 'MSSQLSERVER'
            OptionName     = 'max degree of parallelism'
            OptionValue    = 1
            RestartService = $false
        }

        SqlDatabaseDefaultLocation DefaultDataLocation
        {
            ServerName     = $env:COMPUTERNAME
            InstanceName   = 'MSSQLSERVER'
            Type = 'Data'
            Path = 'F:\SQLData\'
            PsDscRunAsCredential = $SysAdminAccount
            DependsOn = '[File]SQLDataPath'
        }

        SqlDatabaseDefaultLocation DefaultLogLocation
        {
            ServerName     = $env:COMPUTERNAME
            InstanceName   = 'MSSQLSERVER'
            Type = 'Log'
            Path = 'G:\LogData\'
            PsDscRunAsCredential = $SysAdminAccount
            DependsOn = '[File]SQLLogPath'
        }

        SqlDatabaseDefaultLocation DefaultBackupLocation
        {
            ServerName     = $env:COMPUTERNAME
            InstanceName   = 'MSSQLSERVER'
            Type = 'Backup'
            Path = 'K:\BackupData\'
            PsDscRunAsCredential = $SysAdminAccount
            DependsOn = '[File]SQLBackupPath'
        }
         
        #The SPNs seem to end up in the wrong containers (COMPUTERNAME) as opposed to Domain user
        #This is a bit of a hack to make sure it is straight. 
        # - See also: https://support.microsoft.com/en-sg/help/811889/how-to-troubleshoot-the-cannot-generate-sspi-context-error-message
        Script ResetSpns
        {
            GetScript = { 
                return @{ 'Result' = $true }
            }

            SetScript = {
                $spn = "MSSQLSvc/" + $using:computerName + "." + $using:DomainName
                
                $cmd = "setspn -D $spn $using:computerName"
                Write-Verbose $cmd
                Invoke-Expression $cmd

                $cmd = "setspn -A $spn $using:domainUsername"
                Write-Verbose $cmd
                Invoke-Expression $cmd

                $spn = "MSSQLSvc/" + $using:computerName + "." + $using:DomainName + ":1433"
                
                $cmd = "setspn -D $spn $using:computerName"
                Write-Verbose $cmd
                Invoke-Expression $cmd

                $cmd = "setspn -A $spn $using:domainUsername"
                Write-Verbose $cmd
                Invoke-Expression $cmd
            }

            TestScript = {
                $false
            }

            DependsOn = "[SqlServiceAccount]ConfigureSQLSvcAccount"
            PsDscRunAsCredential = $DomainCreds
        }
        
        if ($ClusterOwnerNode -eq $env:COMPUTERNAME) { #This is the primary
            xCluster CreateCluster
            {
                Name                          = $ClusterName
                StaticIPAddress               = $ipdummy
                DomainAdministratorCredential = $DomainCreds
                DependsOn                     = "[WindowsFeature]FCPSCMD","[Script]ResetSpns"
            }

            Script SetCloudWitness
            {
                GetScript = { 
                    return @{ 'Result' = $true }
                }
                SetScript = {
                    Set-ClusterQuorum -CloudWitness -AccountName $using:witnessStorageAccount -AccessKey $using:witnessStorageAccountKey -Endpoint $using:witnessEndpoint
                }
                TestScript = {
                    $(Get-ClusterQuorum).QuorumResource.ResourceType -eq "Cloud Witness"
                }
                DependsOn = "[xCluster]CreateCluster"
                PsDscRunAsCredential = $DomainCreds
            }

            SqlAlwaysOnService EnableAlwaysOn
            {
                Ensure               = 'Present'
                ServerName           = $env:COMPUTERNAME
                InstanceName         = 'MSSQLSERVER'
                RestartTimeout       = 120
                DependsOn = "[xCluster]CreateCluster"
            }

            # Create a DatabaseMirroring endpoint
            SqlServerEndpoint HADREndpoint
            {
                EndPointName         = 'HADR'
                Ensure               = 'Present'
                Port                 = 5022
                ServerName           = $env:COMPUTERNAME
                InstanceName         = 'MSSQLSERVER'
                DependsOn            = "[SqlAlwaysOnService]EnableAlwaysOn"
            }

            # Create the availability group on the instance tagged as the primary replica
            SqlAG CreateAG
            {
                Ensure               = "Present"
                Name                 = $AvailabilityGroupName
                ServerName           = $env:COMPUTERNAME
                InstanceName         = 'MSSQLSERVER'
                AvailabilityMode     = "SynchronousCommit"
                FailoverMode         = "Automatic" 
            }

            SqlAGListener AvailabilityGroupListener
            {
                Ensure               = 'Present'
                ServerName           = $ClusterOwnerNode
                InstanceName         = 'MSSQLSERVER'
                AvailabilityGroup    = $AvailabilityGroupName
                Name                 = $SQLServerVirtualName
                IpAddress            = "$ClusterIP/255.255.255.0"
                Port                 = 1433
                PsDscRunAsCredential = $DomainCreds
                DependsOn            = "[SqlAG]CreateAG"
            }

            Script SetProbePort
            {

                GetScript = { 
                    return @{ 'Result' = $true }
                }
                SetScript = {
                    $ipResourceName = $using:AvailabilityGroupName + "_" + $using:ClusterIP
                    $ipResource = Get-ClusterResource $ipResourceName
                    $clusterResource = Get-ClusterResource -Name $using:AvailabilityGroupName 

                    Set-ClusterParameter -InputObject $ipResource -Name ProbePort -Value 59999

                    Stop-ClusterResource $ipResource
                    Stop-ClusterResource $clusterResource

                    Start-ClusterResource $clusterResource #This should be enough
                    Start-ClusterResource $ipResource #To be on the safe side

                }
                TestScript = {
                    $ipResourceName = $using:AvailabilityGroupName + "_" + $using:ClusterIP
                    $resource = Get-ClusterResource $ipResourceName
                    $probePort = $(Get-ClusterParameter -InputObject $resource -Name ProbePort).Value
                    Write-Verbose "ProbePort = $probePort"
                    ($(Get-ClusterParameter -InputObject $resource -Name ProbePort).Value -eq 59999)
                }
                DependsOn = "[SqlAGListener]AvailabilityGroupListener"
                PsDscRunAsCredential = $DomainCreds
            }

        } else {
            xWaitForCluster WaitForCluster
            {
                Name             = $ClusterName
                RetryIntervalSec = 10
                RetryCount       = 20
                DependsOn        = "[Script]ResetSpns"
            }

            #We have to do this manually due to a problem with xCluster:
            #  see: https://github.com/PowerShell/xFailOverCluster/issues/7
            #      - Cluster is added with an IP and the xCluster module tries to access this IP. 
            #      - Cluster is not not yet responding on that addreess
            Script JoinExistingCluster
            {
                GetScript = { 
                    return @{ 'Result' = $true }
                }
                SetScript = {
                    $targetNodeName = $env:COMPUTERNAME
                    Add-ClusterNode -Name $targetNodeName -Cluster $using:ClusterOwnerNode
                }
                TestScript = {
                    $targetNodeName = $env:COMPUTERNAME
                    $(Get-ClusterNode -Cluster $using:ClusterOwnerNode).Name -contains $targetNodeName
                }
                DependsOn = "[xWaitForCluster]WaitForCluster"
                PsDscRunAsCredential = $DomainCreds
            }

            SqlAlwaysOnService EnableAlwaysOn
            {
                Ensure               = 'Present'
                ServerName           = $env:COMPUTERNAME
                InstanceName         = 'MSSQLSERVER'
                RestartTimeout       = 120
                DependsOn = "[Script]JoinExistingCluster"
            }

              # Create a DatabaseMirroring endpoint
              SqlServerEndpoint HADREndpoint
              {
                  EndPointName         = 'HADR'
                  Ensure               = 'Present'
                  Port                 = 5022
                  ServerName           = $env:COMPUTERNAME
                  InstanceName         = 'MSSQLSERVER'
                  DependsOn            = "[SqlAlwaysOnService]EnableAlwaysOn"
              }
    
              SqlWaitForAG WaitForAG
              {
                  Name                 = $AvailabilityGroupName
                  RetryIntervalSec     = 20
                  RetryCount           = 30
                  PsDscRunAsCredential = $DomainCreds
                  DependsOn            = "[SqlServerEndpoint]HADREndpoint"
              }
      
                # Add the availability group replica to the availability group
                SqlAGReplica AddReplica
                {
                    Ensure                     = 'Present'
                    Name                       = $env:COMPUTERNAME
                    AvailabilityGroupName      = $AvailabilityGroupName
                    ServerName                 = $env:COMPUTERNAME
                    InstanceName               = 'MSSQLSERVER'
                    PrimaryReplicaServerName   = $ClusterOwnerNode
                    PrimaryReplicaInstanceName = 'MSSQLSERVER'
                    PsDscRunAsCredential = $DomainCreds
                    AvailabilityMode     = "SynchronousCommit"
                    FailoverMode         = "Automatic"
                    DependsOn            = "[SqlWaitForAG]WaitForAG"     
                }
        }

        LocalConfigurationManager 
        {
            RebootNodeIfNeeded = $true
        }

    }
}

function Get-NetBIOSName
{ 
    [OutputType([string])]
    param(
        [string]$DomainName
    )

    if ($DomainName.Contains('.')) {
        $length=$DomainName.IndexOf('.')
        if ( $length -ge 16) {
            $length=15
        }
        return $DomainName.Substring(0,$length)
    }
    else {
        if ($DomainName.Length -gt 15) {
            return $DomainName.Substring(0,15)
        }
        else {
            return $DomainName
        }
    }
}

function WaitForSqlSetup
{
    # Wait for SQL Server Setup to finish before proceeding.
    while ($true)
    {
        try
        {
            Get-ScheduledTaskInfo '\ConfigureSqlImageTasks\RunConfigureImage' -ErrorAction Stop
            Start-Sleep -Seconds 5
        }
        catch
        {
            break
        }
    }
}

function AddSvcAccountToUserRight
{
    param
    (
        [string]$serviceAccount
    )


    $sqlRights = ("SeManageVolumePrivilege", "SeLockMemoryPrivilege", "SeServiceLogonRight", "SeAssignPrimaryTokenPrivilege", "SeChangeNotifyPrivilege", "SeIncreaseQuotaPrivilege")
    foreach ($right in $sqlRights)
    {
        
        $sidstr = $null

        try {
            $ntprincipal = New-Object System.Security.Principal.NTAccount "$serviceAccount"
            $sid = $ntprincipal.Translate([System.Security.Principal.SecurityIdentifier])
            $sidstr = $sid.Value.ToString()
        } catch {
            $sidstr = $null
        }

        Write-Host "Account: $($serviceAccount)" -ForegroundColor DarkCyan

        if( [string]::IsNullOrEmpty($sidstr) ) {
            "Account not found!" 
            exit -1
        }

        $tmp = ""
        $tmp = [System.IO.Path]::GetTempFileName()
        "Export current Local Security Policy" 
        secedit.exe /export /cfg "$($tmp)" 
        $c = ""
        $c = Get-Content -Path $tmp
        $currentSetting = ""
        foreach($s in $c) {
            if( $s -like "$right*") {
                    $x = $s.split("=",[System.StringSplitOptions]::RemoveEmptyEntries)
                    $currentSetting = $x[1].Trim()
            }
        }

        if( $currentSetting -notlike "*$($sidstr)*" ) {
            "Modify Setting ""$right""" 
        
            if( [string]::IsNullOrEmpty($currentSetting) ) {
                    $currentSetting = "*$($sidstr)"
            } else {
                    $currentSetting = "*$($sidstr),$($currentSetting)"
            }

           $outfile = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[Privilege Rights]
$right = $($currentSetting)
"@

            $tmp2 = ""
            $tmp2 = [System.IO.Path]::GetTempFileName()

            "Import new settings to Local Security Policy" 
            $outfile | Set-Content -Path $tmp2 -Encoding Unicode -Force
            Push-Location (Split-Path $tmp2)
        
            try {
                    secedit.exe /configure /db "secedit.sdb" /cfg "$($tmp2)" /areas USER_RIGHTS
            } finally {  
                    Pop-Location
            }
        } else {
            "NO ACTIONS REQUIRED! Account already in ""$right""" 
        }
    }
}