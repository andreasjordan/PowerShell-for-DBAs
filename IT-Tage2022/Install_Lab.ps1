Import-Module -Name AutomatedLab

$LabName = "ITTage"


<# Some commands that I use for importing, removing, stopping, starting or connecting to the lab:

Import-Lab -Name $LabName -NoValidation

Remove-Lab -Name $LabName -Confirm:$false; Get-NetNat -Name $LabName -ErrorAction SilentlyContinue | Remove-NetNat -Confirm:$false

Stop-VM -Name $LabName-*
Start-VM -Name $LabName-*

vmconnect.exe localhost $LabName-WIN-CL

#>


$LabNetworkBase = '192.168.111'
$LabDnsServer   = '1.1.1.1'

$LabAdminUser     = 'User'
$LabAdminPassword = 'Passw0rd!'

$MachineDefinition = @(
    @{
        Name            = 'WIN-CL'
        ResourceName    = "$LabName-WIN-CL"
        OperatingSystem = 'Windows Server 2022 Standard Evaluation (Desktop Experience)'
        Memory          = 2GB
        Processors      = 2
        Network         = $LabName
        IpAddress       = "$LabNetworkBase.10"
        Gateway         = "$LabNetworkBase.1"
        DnsServer1      =  $LabDnsServer
        TimeZone        = 'W. Europe Standard Time'
    }
    @{
        Name            = 'DOC-DB'
        ResourceName    = "$LabName-DOC-DB"
        OperatingSystem = 'CentOS-7'
        Memory          = 8GB
        Processors      = 4
        Network         = $LabName
        IpAddress       = "$LabNetworkBase.20"
        Gateway         = "$LabNetworkBase.1" 
        DnsServer1      =  $LabDnsServer
        TimeZone        = 'W. Europe Standard Time'
    }
    @{
        Name            = 'WIN-DB'
        ResourceName    = "$LabName-WIN-DB"
        OperatingSystem = 'Windows Server 2022 Standard Evaluation (Desktop Experience)'
        Memory          = 4GB
        Processors      = 4
        Network         = $LabName
        IpAddress       = "$LabNetworkBase.30"
        Gateway         = "$LabNetworkBase.1"
        DnsServer1      =  $LabDnsServer
        TimeZone        = 'W. Europe Standard Time'
    }
    @{
        Name            = 'LIN-CL'
        ResourceName    = "$LabName-LIN-CL"
        OperatingSystem = 'CentOS-7'
        Memory          = 2GB
        Processors      = 2
        Network         = $LabName
        IpAddress       = "$LabNetworkBase.40"
        Gateway         = "$LabNetworkBase.1" 
        DnsServer1      =  $LabDnsServer
        TimeZone        = 'W. Europe Standard Time'
    }
)

#$MachineDefinition = $MachineDefinition | Where-Object Name -in 'WIN-CL'


# Additional configuration for WIN-CL:

$ChocolateyPackages = @(
    'powershell-core'
    'notepadplusplus'
    'vscode'
    'vscode-powershell'
# Just in case you would like to have these as well:
#    '7zip'
#    'googlechrome'
# If you don't have it already as a download (see $CopyToWinCl):
#    'sql-server-management-studio'
)

$PowerShellModules = @(
    'dbatools'
    'PSFramework'
    'ImportExcel'
)

$HostEntries = @(
    "$LabNetworkBase.20   DOC-DB"
    "$LabNetworkBase.30   WIN-DB"
    "$LabNetworkBase.40   LIN-CL"
)

$CopyToWinCl = @(
    "$labSources\CustomAssets\Software\SSMS-Setup-ENU.exe"                    # SQL Server Management Studio from: https://learn.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms
    "$labSources\CustomAssets\Software\sqldeveloper-22.2.1.234.1810-x64.zip"  # SQL Developer from: https://www.oracle.com/database/sqldeveloper/technologies/download/
    "$labSources\CustomAssets\Software\WINDOWS.X64_193000_client.zip"         # Oracle Client 19c from: https://www.oracle.com/database/technologies/oracle19c-windows-downloads.html
)


# Additional configuration for WIN-DB:

$CopyToWinDb = @(
    "$labSources\CustomAssets\Software\OracleXE213_Win64.zip"   # Oracle Express for Windows from: https://www.oracle.com/database/technologies/xe-downloads.html
    "$labSources\CustomAssets\Software\SQLEXPR_x64_ENU.exe"     # SQL Server Express from: https://www.microsoft.com/en-US/download/details.aspx?id=101064
)


# Additional configuration for DOC-DB:

$DockerRunCommands = @(
    "docker run --name SQLServer  --memory=2g -p 1433:1433 -e MSSQL_SA_PASSWORD='$LabAdminPassword' -e ACCEPT_EULA=Y -e MSSQL_PID=Express --detach --restart always mcr.microsoft.com/mssql/server:2019-latest"
    "docker run --name Oracle     --memory=3g -p 1521:1521 -e ORACLE_PWD='$LabAdminPassword' -e ORACLE_CHARACTERSET=AL32UTF8 --detach --restart always container-registry.oracle.com/database/express:latest"
    "docker run --name MySQL      --memory=1g -p 3306:3306 -e MYSQL_ROOT_PASSWORD='$LabAdminPassword' --detach --restart always mysql:latest"
# As an alternative for MySQL:
#    "docker run --name MariaDB    --memory=1g -p 3306:3306 -e MARIADB_ROOT_PASSWORD='$LabAdminPassword' --detach --restart always mariadb:latest"
    "docker run --name PostgreSQL --memory=1g -p 5432:5432 -e POSTGRES_PASSWORD='$LabAdminPassword' --detach --restart always postgres:latest"
# As an alternative for PostgreSQL:
#    "docker run --name PostGIS    --memory=1g -p 5432:5432 -e POSTGRES_PASSWORD='$LabAdminPassword' --detach --restart always postgres:latest"
)



### End of configuration ###


Set-PSFConfig -Module AutomatedLab -Name DoNotWaitForLinux -Value $true
New-LabDefinition -Name $LabName -DefaultVirtualizationEngine HyperV
Set-LabInstallationCredential -Username $LabAdminUser -Password $LabAdminPassword
Add-LabVirtualNetworkDefinition -Name $LabName -AddressSpace "$LabNetworkBase.0/24"
foreach ($md in $MachineDefinition) {
    Add-LabMachineDefinition @md
}
Install-Lab -NoValidation

# I use NetNat to provide internat to the virtual maschines
$null = New-NetNat -Name $LabName -InternalIPInterfaceAddressPrefix "$LabNetworkBase.0/24"


# Test what virtual maschines have been deployed and fill some variables
$windowsVMs = @( )
$linuxVMs = @( )
$windowsVMs += Get-LabVM
$linuxVMs += Get-LabVM -IncludeLinux | Where-Object Name -notin $windowsVMs.Name


# After enabling internet connection, the linux maschines can be started
if ($linuxVMs.Count -gt 0) {
    Start-LabVM -ComputerName $linuxVMs
}


# Start configuration of virtual maschines

# Windows maschines

if ($windowsVMs.Count -gt 0) {
    Invoke-LabCommand -ComputerName $windowsVMs.Name -ActivityName 'Disable Windows updates' -ScriptBlock { 
        # https://learn.microsoft.com/en-us/windows/deployment/update/waas-wu-settings
        Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU -Name NoAutoUpdate -Value 1
    }

    Invoke-LabCommand -ComputerName $windowsVMs.Name -ActivityName 'Setting my favorite explorer settings' -ScriptBlock {
        Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name HideFileExt -Value 0
        Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name NavPaneShowAllFolders -Value 1
        Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name NavPaneExpandToCurrentFolder -Value 1
    }

    if ($HostEntries.Count -gt 0) {
        Invoke-LabCommand -ComputerName $windowsVMs.Name -ActivityName 'SetupHostEntries' -ArgumentList @(, $HostEntries) -ScriptBlock { 
            param($HostEntries)

            $HostEntries | Add-Content -Path C:\Windows\System32\drivers\etc\hosts
        }
    }
}


# WIN-DB

# Installing oracle database server often fails with only installing part of it resulting in only 2 services installed.
# So we start with that and remove the lab on failure.

if ($windowsVMs.Name -contains 'WIN-DB') {
    foreach ($file in $CopyToWinDb) {
        Copy-LabFileItem -Path $file -ComputerName WIN-DB -DestinationFolderPath C:\Software
    }
}

if ($windowsVMs.Name -contains 'WIN-DB' -and $CopyToWinDb -match 'OracleXE213_Win64.zip') {
    Invoke-LabCommand -ComputerName WIN-DB -ActivityName 'Installing Oracle Server' -ArgumentList $LabAdminPassword -ScriptBlock {
        param($Password)
        $rspContent = @(
            'INSTALLDIR=C:\oracle\product\21c\'
            "PASSWORD=$Password"
            'LISTENER_PORT=1521'
            'EMEXPRESS_PORT=5550'
            'CHAR_SET=AL32UTF8'
            'DB_DOMAIN='
        )
        $argumentList = @(
            '/s'
            '/v"RSP_FILE=C:\Software\OracleInstall.rsp"'
            '/v"/L*v C:\Software\OracleSetup.log"'
            '/v"/qn"'
        )
        Expand-Archive -Path C:\Software\OracleXE213_Win64.zip -DestinationPath C:\Software\OracleXE213_Win64
        $rspContent | Set-Content -Path C:\Software\OracleInstall.rsp
        Start-Process -FilePath C:\Software\OracleXE213_Win64\setup.exe -ArgumentList $argumentList -WorkingDirectory C:\Software -NoNewWindow -Wait
    }

    $numberOfOracleServices = Invoke-LabCommand -ComputerName WIN-DB -ActivityName 'Testing Oracle Server' -PassThru -ScriptBlock {
        (Get-Service | Where-Object Name -like Oracle*).Count
    }

    if ($numberOfOracleServices -lt 5) {
        Write-Warning -Message "We only have $numberOfOracleServices oracle services - so installation failed. Please rebuild the lab, will start removing the lab now..."
        Remove-Lab -Name $LabName -Confirm:$false
        Get-NetNat -Name $LabName -ErrorAction SilentlyContinue | Remove-NetNat -Confirm:$false
        break
    }
}

if ($windowsVMs.Name -contains 'WIN-DB' -and $CopyToWinDb -match 'SQLEXPR_x64_ENU.exe') {
    Invoke-LabCommand -ComputerName WIN-DB -ActivityName 'Installing SQL Server' -ArgumentList $LabAdminPassword -ScriptBlock {
        param($Password)
        $argumentList = @(
            '/x:C:\Software\SQLEXPR_x64_ENU'
            '/q'
            '/IACCEPTSQLSERVERLICENSETERMS'
            '/ACTION=INSTALL'
            '/UpdateEnabled=False'
            '/FEATURES=SQL'
            '/INSTANCENAME=SQLEXPRESS'
            '/SECURITYMODE=SQL'
            "/SAPWD=$Password"
            '/TCPENABLED=1'
            '/SQLSVCINSTANTFILEINIT=True'
        )
        Start-Process -FilePath C:\Software\SQLEXPR_x64_ENU.exe -ArgumentList $argumentList -Wait
    }
}


# WIN-CL

if ($windowsVMs.Name -contains 'WIN-CL' -and $ChocolateyPackages.Count -gt 0) {
    Invoke-LabCommand -ComputerName WIN-CL -ActivityName 'Installing chocolatey packages' -ArgumentList @(, $ChocolateyPackages) -ScriptBlock { 
        param($ChocolateyPackages)

        $ErrorActionPreference = 'Stop'

        $logPath = 'C:\DeployDebug\InstallChocolateyPackages.log'

        try {
            Invoke-Expression -Command ([System.Net.WebClient]::new().DownloadString('https://chocolatey.org/install.ps1')) *>$logPath
            $installResult = choco install $ChocolateyPackages --confirm --limitoutput --no-progress *>&1
            if ($installResult -match 'Warnings:') {
                Write-Warning -Message 'Chocolatey generated warnings'
            }
            $info = $installResult -match 'Chocolatey installed (\d+)/(\d+) packages' | Select-Object -First 1
            if ($info -match 'Chocolatey installed (\d+)/(\d+) packages') {
                if ($Matches[1] -ne $Matches[2]) {
                    Write-Warning -Message "Chocolatey only installed $($Matches[1]) of $($Matches[2]) packages"
                    $installResult | Add-Content -Path $logPath
                }
            } else {
                Write-Warning -Message "InstallResult: $installResult"
            }
        } catch {
            $message = "Setting up Chocolatey failed: $_"
            $message | Add-Content -Path $logPath
            Write-Warning -Message $message
        }
    }
}

if ($windowsVMs.Name -contains 'WIN-CL' -and $PowerShellModules.Count -gt 0) {
    Invoke-LabCommand -ComputerName WIN-CL -ActivityName 'Installing PowerShell modules' -ArgumentList @(, $PowerShellModules) -ScriptBlock { 
        param($PowerShellModules)

        $logPath = 'C:\DeployDebug\InstallPowerShellModules.log'

        $ErrorActionPreference = 'Stop'

        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            if ((Get-PackageProvider -ListAvailable).Name -notcontains 'Nuget') {
                $null = Install-PackageProvider -Name Nuget -Force
                'Install-PackageProvider ok' | Add-Content -Path $logPath
            } else {
                'Install-PackageProvider not needed' | Add-Content -Path $logPath
            }
            if ((Get-PSRepository -Name PSGallery).InstallationPolicy -ne 'Trusted') {
                Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
                'Set-PSRepository ok' | Add-Content -Path $logPath
            } else {
                'Set-PSRepository not needed' | Add-Content -Path $logPath
            }
            foreach ($name in $PowerShellModules) {
                if (-not (Get-Module -Name $name -ListAvailable)) {
                    Install-Module -Name $name
                    "Install-Module $name ok" | Add-Content -Path $logPath
                } else {
                    "Install-Module $name not needed" | Add-Content -Path $logPath
                }
            }
        } catch {
            $message = "Setting up PowerShell failed: $_"
            $message | Add-Content -Path $logPath
            Write-Warning -Message $message
        }
    }
}

if ($windowsVMs.Name -contains 'WIN-CL') {
    foreach ($file in $CopyToWinCl) {
        Copy-LabFileItem -Path $file -ComputerName WIN-CL -DestinationFolderPath C:\Software
    }
}

if ($windowsVMs.Name -contains 'WIN-CL' -and $CopyToWinCl -match 'WINDOWS.X64_193000_client.zip') {
    Invoke-LabCommand -ComputerName WIN-CL -ActivityName 'Installing Oracle Client' -ScriptBlock { 
        $rspContent = @(
            'ORACLE_BASE=C:\oracle'
            'ORACLE_HOME=C:\oracle\product\19.0.0\client_1'
            'oracle.install.responseFileVersion=/oracle/install/rspfmt_clientinstall_response_schema_v19.0.0'
            'oracle.install.IsBuiltInAccount=true'
            'oracle.install.client.installType=Custom'
            'oracle.install.client.customComponents=oracle.ntoledb.odp_net_2:19.0.0.0.0,oracle.sqlplus:19.0.0.0.0'
        )
        $argumentList = @(
            '-silent'
            '-responseFile C:\Software\OracleInstall.rsp'
            '-noConsole'
        )
        Expand-Archive -Path C:\Software\WINDOWS.X64_193000_client.zip -DestinationPath C:\Software\WINDOWS.X64_193000_client
        $rspContent | Set-Content -Path C:\Software\OracleInstall.rsp
        Start-Process -FilePath C:\Software\WINDOWS.X64_193000_client\client\setup.exe -ArgumentList $argumentList -Wait
    }
    Restart-LabVM -ComputerName WIN-CL -Wait
}

if ($windowsVMs.Name -contains 'WIN-CL' -and $CopyToWinCl -match 'sqldeveloper-.+zip') {
    Invoke-LabCommand -ComputerName WIN-CL -ActivityName 'Expanding SQL Developer' -ScriptBlock { 
        # zip file contains a subfolder "sqldeveloper", so expand in Software without a subfolder
        Expand-Archive -Path C:\Software\sqldeveloper-*.zip -DestinationPath C:\Software
    }
}

if ($windowsVMs.Name -contains 'WIN-CL' -and $CopyToWinCl -match 'SSMS-Setup-ENU.exe') {
    Invoke-LabCommand -ComputerName WIN-CL -ActivityName 'Installing SQL Server Management Studio' -ScriptBlock { 
        $argumentList = @(
            '/install'
            '/quiet'
            '/norestart'
        )
        Start-Process -FilePath C:\Software\SSMS-Setup-ENU.exe -ArgumentList $argumentList -Wait
    }
    Restart-LabVM -ComputerName WIN-CL -Wait
}

if ($windowsVMs.Name -contains 'WIN-CL') {
    Invoke-LabCommand -ComputerName WIN-CL -ActivityName 'Downloading files for IT-Tage 2022' -ScriptBlock { 
        Invoke-Expression -Command ([System.Net.WebClient]::new().DownloadString('https://raw.githubusercontent.com/andreasjordan/PowerShell-for-DBAs/main/IT-Tage2022/Setup_Lab_Windows.ps1'))
    }
}


# DOC-DB

if ($linuxVMs.Name -contains 'DOC-DB') {
    Write-PSFMessage -Level Host -Message "Connecting to DOC-DB"

    Import-Module -Name Posh-SSH
    $linuxVM = Get-LabVM -ComputerName DOC-DB -IncludeLinux 
    $sshComputerName = $linuxVM.IpAddress.IpAddress.AddressAsString
    $sshCredential = [PSCredential]::new('root', (ConvertTo-SecureString -String $LabAdminPassword -AsPlainText -Force))
    while (1) {
        $sshSession = New-SSHSession -ComputerName $sshComputerName -Credential $sshCredential -Force -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        if ($sshSession) {
            break
        }
        Start-Sleep -Seconds 30
    }
    Write-PSFMessage -Level Host -Message "Connected to DOC-DB"
}

if ($linuxVMs.Name -contains 'DOC-DB') {
    Write-PSFMessage -Level Host -Message "Installing docker on DOC-DB"

    $sshCommands = @(
        'yum -y update'
        'yum install -y yum-utils'
        'yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo'
        'yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin'
        'systemctl enable --now docker'
    )

    foreach ($cmd in $sshCommands) {
        $sshResult = Invoke-SSHCommand -SSHSession $sshSession -Command $cmd -TimeOut 600
        if ($sshResult.ExitStatus -gt 0) {
            Write-PSFMessage -Level Warning -Message "Command '$cmd' returned with ExitStatus $($sshResult.ExitStatus)"
            break
        }
    }

    if ($HostEntries.Count -gt 0) {
        Write-PSFMessage -Level Host -Message "Adding host entries"
        foreach ($entry in $HostEntries) {
            $null = Invoke-SSHCommand -SSHSession $sshSession -Command "echo '$entry' >> /etc/hosts"
        }
    }
}


if ($linuxVMs.Name -contains 'DOC-DB' -and (Test-Path -Path "$labSources\CustomAssets\DockerImages")) {
    Write-PSFMessage -Level Host -Message "Copying and importing docker images"
    $sftpSession = New-SFTPSession -ComputerName $sshComputerName -Credential $sshCredential -Force -WarningAction SilentlyContinue

    $imageFiles = Get-ChildItem -Path "$labSources\CustomAssets\DockerImages"
    foreach ($imageFile in $imageFiles) { 
        # $imageFile = $imageFiles[0]
        Set-SFTPItem -SFTPSession $sftpSession -Destination /tmp -Path $imageFile.FullName
        $cmd = "docker load -i /tmp/$($imageFile.Name)"
        $sshResult = Invoke-SSHCommand -SSHSession $sshSession -Command $cmd -TimeOut 600 # -ShowStandardOutputStream -ShowErrorOutputStream
        $cmd = "rm /tmp/$($imageFile.Name)"
        $sshResult = Invoke-SSHCommand -SSHSession $sshSession -Command $cmd -TimeOut 600 # -ShowStandardOutputStream -ShowErrorOutputStream
    }
}

if ($linuxVMs.Name -contains 'DOC-DB' -and $DockerRunCommands.Count -gt 0) {
    foreach ($cmd in $DockerRunCommands) {
        $containerName = $cmd -replace '^.*--name ([^ ]+).*$', '$1'
        Write-PSFMessage -Level Host -Message "Starting docker container $containerName"
        $null = Invoke-SSHCommand -SSHSession $sshSession -Command $cmd -TimeOut 36000
    }
}


# LIN-CL

if ($linuxVMs.Name -contains 'LIN-CL') {
    Write-PSFMessage -Level Host -Message "Connecting to LIN-CL"

    Import-Module -Name Posh-SSH
    $linuxVM = Get-LabVM -ComputerName LIN-CL -IncludeLinux 
    $sshComputerName = $linuxVM.IpAddress.IpAddress.AddressAsString
    $sshCredential = [PSCredential]::new('root', (ConvertTo-SecureString -String $LabAdminPassword -AsPlainText -Force))
    while (1) {
        $sshSession = New-SSHSession -ComputerName $sshComputerName -Credential $sshCredential -Force -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        if ($sshSession) {
            break
        }
        Start-Sleep -Seconds 30
    }
    Write-PSFMessage -Level Host -Message "Connected to LIN-CL"
}

if ($linuxVMs.Name -contains 'LIN-CL' -and $HostEntries.Count -gt 0) {
    Write-PSFMessage -Level Host -Message "Adding host entries"
    foreach ($entry in $HostEntries) {
        $null = Invoke-SSHCommand -SSHSession $sshSession -Command "echo '$entry' >> /etc/hosts"
    }
}

if ($linuxVMs.Name -contains 'LIN-CL') {
    Write-PSFMessage -Level Host -Message "Setup files for IT-Tage 2022"

    $sshUserCredential = [PSCredential]::new($LabAdminUser, (ConvertTo-SecureString -String $LabAdminPassword -AsPlainText -Force))
    $sshSession = New-SSHSession -ComputerName $sshComputerName -Credential $sshUserCredential -Force -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    $pwshCommand = "Invoke-Expression -Command ([System.Net.WebClient]::new().DownloadString('https://raw.githubusercontent.com/andreasjordan/PowerShell-for-DBAs/main/IT-Tage2022/Setup_Lab_Linux.ps1'))"
    $sshCommand = "pwsh -c ""$pwshCommand"""
    $null = Invoke-SSHCommand -SSHSession $sshSession -TimeOut 600 -Command $sshCommand
}


Write-PSFMessage -Level Host -Message "Finished"


<# To save the docker images for later to build the lab faster:

$linuxVM = Get-LabVM -ComputerName DOC-DB -IncludeLinux 
$sshComputerName = $linuxVM.IpAddress.IpAddress.AddressAsString
$sshCredential = [PSCredential]::new('root', (ConvertTo-SecureString -String $LabAdminPassword -AsPlainText -Force))
$sshSession = New-SSHSession -ComputerName $sshComputerName -Credential $sshCredential -Force -WarningAction SilentlyContinue
$sftpSession = New-SFTPSession -ComputerName $sshComputerName -Credential $sshCredential -Force -WarningAction SilentlyContinue
$saveImages = @(
    @{
        database = 'sqlserver'
        image    = 'mcr.microsoft.com/mssql/server:2019-latest'
    }
    @{
        database = 'oracle'
        image    = 'container-registry.oracle.com/database/express:latest'
    }
    @{
        database = 'mysql'
        image    = 'mysql:latest'
    }
    @{
        database = 'postgresql'
        image    = 'postgres:latest'
    }
)
$null = New-Item -Path "$labSources\CustomAssets\DockerImages" -ItemType Directory
foreach ($image in $saveImages) {
    $null = Invoke-SSHCommand -SSHSession $sshSession -Command "docker pull $($image.image)" -TimeOut 36000
    $null = Invoke-SSHCommand -SSHSession $sshSession -Command "docker save -o /tmp/$($image.database).tar $($image.image)" -TimeOut 36000
    $null = Invoke-SSHCommand -SSHSession $sshSession -Command "gzip /tmp/$($image.database).tar" -TimeOut 36000
    $null = Invoke-SSHCommand -SSHSession $sshSession -Command "chmod a+r /tmp/$($image.database).tar.gz" -TimeOut 36000
    Get-SFTPItem -SFTPSession $sftpSession -Path "/tmp/$($image.database).tar.gz" -Destination "$labSources\CustomAssets\DockerImages"
}

#>
