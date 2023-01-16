[CmdletBinding()]
param (
    [ValidateSet("SQLServer", "Oracle", "PostgreSQL", "PostGIS", "MySQL", "MariaDB")][String[]]$DBMS = @("SQLServer", "Oracle", "PostgreSQL", "MySQL"),
    [String]$NuGetPath = (Resolve-Path -Path "~/NuGet").Path,
    [String]$GitHubPath = (Resolve-Path -Path "~/GitHub").Path,
    [String]$SoftwarePath = (Resolve-Path -Path "~/Software").Path,
    [Switch]$ServerContainerOnly,
    [Switch]$StopContainer
)

# Test, if we can use PSFramework and create a local logging function
try {
    Import-Module -Name PSFramework -ErrorAction Stop
    function Write-LogMessage {
        param(
            [String]$Message,
            [String]$Level = 'Host'
        )
        Write-PSFMessage -Level $Level -Message $Message
    }
} catch {
    function Write-LogMessage {
        param(
            [String]$Message,
            [String]$Level = 'Host'
        )
        if ($Level -eq 'Verbose') {
            Write-Verbose -Message $Message
        } else {
            Write-Host $Message
        }
    }
}

# Loading my docker function and always use -EnableException
. ./MyDocker.ps1
$PSDefaultParameterValues = @{ "*-MyDocker*:EnableException" = $true }

# Suppress all progress bars
$ProgressPreference = 'SilentlyContinue'

# Download the needed NuGet packages
if (-not $ServerContainerOnly) {
    foreach ($package in 'Oracle.ManagedDataAccess.Core', 'MySql.Data', 'Npgsql', 'Microsoft.Extensions.Logging.Abstractions') {
        if (-not (Test-Path -Path $NuGetPath/$package)) {
            Write-LogMessage -Message "Downloading NuGet package $package to $NuGetPath/$package"
            Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/$package -OutFile package.zip -UseBasicParsing
            Expand-Archive -Path package.zip -DestinationPath $NuGetPath/$package
            Remove-Item -Path package.zip
        }
    }
}

if (-not (Get-MyDockerNetwork -Name dbms-net)) {
    $null = New-MyDockerNetwork -Name dbms-net
}

$containerParams = @{
    Name        = 'PowerShell'
    Image       = 'mcr.microsoft.com/powershell:7.3-ubuntu-22.04'
    Network     = 'dbms-net'
    Memory      = '2g'
    Volume      = @(
        "$($GitHubPath):/mnt/GitHub"
        "$($NuGetPath):/mnt/NuGet"
    )
    Environment = @(
        'SQLSERVER_INSTANCE=SQLServer'
        'SQLSERVER_DATABASE=StackOverflow'
        'SQLSERVER_USERNAME=StackOverflow'
        'SQLSERVER_PASSWORD=start456'
        'ORACLE_DLL=/mnt/NuGet/Oracle.ManagedDataAccess.Core/lib/netstandard2.1/Oracle.ManagedDataAccess.dll'
        'ORACLE_INSTANCE=Oracle/XEPDB1'
        'ORACLE_USERNAME=stackoverflow'
        'ORACLE_PASSWORD=start456'
        'MYSQL_DLL=/mnt/NuGet/MySql.Data/lib/net7.0/MySql.Data.dll'
        'MYSQL_INSTANCE=MySQL'
        'MYSQL_DATABASE=stackoverflow'
        'MYSQL_USERNAME=stackoverflow'
        'MYSQL_PASSWORD=start456'
        'POSTGRESQL_DLL=/mnt/NuGet/Npgsql/lib/net7.0/Npgsql.dll'
        'POSTGRESQL_INSTANCE=PostgreSQL'
        'POSTGRESQL_DATABASE=stackoverflow'
        'POSTGRESQL_USERNAME=stackoverflow'
        'POSTGRESQL_PASSWORD=start456'
    )
    Interactive = $true
}
Write-LogMessage -Message "Starting setup of container $($containerParams.Name)"
if (Get-MyDockerContainer -Name $containerParams.Name) {
    Write-LogMessage -Level Verbose -Message "Removing existing container"
    Remove-MyDockerContainer -Name $containerParams.Name -Force
}
Write-LogMessage -Message "Building new container from image $($containerParams.Image)"
New-MyDockerContainer @containerParams

Write-LogMessage -Message "Creating environment"
$null = Invoke-MyDockerContainer -Name $containerParams.Name -Shell pwsh -Command @'
$ProgressPreference = 'SilentlyContinue'
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module -Name PSFramework
'@

if ('SQLServer' -in $DBMS) {
    $containerParams = @{
        Name        = 'SQLServer'
        Image       = 'mcr.microsoft.com/mssql/server:2019-latest'
        Network     = 'dbms-net'
        Memory      = '2g'
        Port        = @('1433:1433')
        Environment = @(
            'ACCEPT_EULA=Y'
            '"MSSQL_SA_PASSWORD=P#ssw0rd"'
            'MSSQL_PID=Express'
        )
    }
    Write-LogMessage -Message "Starting setup of container $($containerParams.Name)"
    if (Get-MyDockerContainer -Name $containerParams.Name) {
        Write-LogMessage -Level Verbose -Message "Removing existing container"
        Remove-MyDockerContainer -Name $containerParams.Name -Force
    }
    Write-LogMessage -Message "Building new container from image $($containerParams.Image)"
    New-MyDockerContainer @containerParams
    Wait-MyDockerContainer -Name $containerParams.Name -LogRegex 'SQL Server is now ready for client connections' -EnableException

    Write-LogMessage -Message "Creating database and user"
    $null = Invoke-MyDockerContainer -Name $containerParams.Name -Shell bash -Command @'
/opt/mssql-tools/bin/sqlcmd -U sa -P 'P#ssw0rd' <<END_OF_SQL
CREATE LOGIN StackOverflow WITH PASSWORD = 'start456', CHECK_POLICY = OFF
GO
CREATE DATABASE StackOverflow
GO
ALTER AUTHORIZATION ON DATABASE::StackOverflow TO StackOverflow
GO
exit
END_OF_SQL
'@

    if (-not $ServerContainerOnly) {
        Write-LogMessage -Message "Creating application using namespace System.Data.SqlClient"
        $output = Invoke-MyDockerContainer -Name PowerShell -Shell pwsh -Command @'
$ProgressPreference = 'SilentlyContinue'
Set-Location -Path /mnt/GitHub/PowerShell-for-DBAs/SQLServer
./Application.ps1
'@
        Write-LogMessage -Message "Output: $output"
    }

    if ($StopContainer) {
        Stop-MyDockerContainer -Name $containerParams.Name
    }
}

if ('Oracle' -in $DBMS) { 
    # https://docs.oracle.com/cd/E37670_01/E75728/html/oracle-registry-server.html
    # https://container-registry.oracle.com/
    $containerParams = @{
        Name        = 'Oracle'
        Image       = 'container-registry.oracle.com/database/express:latest'
        Network     = 'dbms-net'
        Memory      = '3g'
        Port        = @(
            '1521:1521'
            '5500:5500'
        )
        Environment = @(
            'ORACLE_PWD=start123'
            'ORACLE_CHARACTERSET=AL32UTF8'
        )
    }
    Write-LogMessage -Message "Starting setup of container $($containerParams.Name)"
    if (Get-MyDockerContainer -Name $containerParams.Name) {
        Write-LogMessage -Level Verbose -Message "Removing existing container"
        Remove-MyDockerContainer -Name $containerParams.Name -Force
    }
    Write-LogMessage -Message "Building new container from image $($containerParams.Image)"
    New-MyDockerContainer @containerParams
    Wait-MyDockerContainer -Name $containerParams.Name -LogRegex 'DATABASE IS READY TO USE!' -EnableException

    Write-LogMessage -Message "Creating user stackoverflow"
    $null = Invoke-MyDockerContainer -Name $containerParams.Name -Shell bash -Command @'
sqlplus / as sysdba <<END_OF_SQL
ALTER SESSION SET CONTAINER=XEPDB1;
CREATE USER stackoverflow IDENTIFIED BY start456 DEFAULT TABLESPACE users QUOTA UNLIMITED ON users TEMPORARY TABLESPACE temp;
GRANT CREATE SESSION TO stackoverflow;
GRANT ALL PRIVILEGES TO stackoverflow;
exit
END_OF_SQL
'@

    Write-LogMessage -Message "Creating user geodemo"
    $null = Invoke-MyDockerContainer -Name $containerParams.Name -Shell bash -Command @'
sqlplus / as sysdba <<END_OF_SQL
ALTER SESSION SET CONTAINER=XEPDB1;
CREATE USER geodemo IDENTIFIED BY start456 DEFAULT TABLESPACE users QUOTA UNLIMITED ON users TEMPORARY TABLESPACE temp;
GRANT CREATE SESSION TO geodemo;
GRANT ALL PRIVILEGES TO geodemo;
exit
END_OF_SQL
'@

    if (-not $ServerContainerOnly) {
        Write-LogMessage -Message "Creating application"
        $output = Invoke-MyDockerContainer -Name PowerShell -Shell pwsh -Command @'
$ProgressPreference = 'SilentlyContinue'
Set-Location -Path /mnt/GitHub/PowerShell-for-DBAs/Oracle
./Application.ps1
'@
        Write-LogMessage -Message "Output: $output"
    }

    if ($StopContainer) {
        Stop-MyDockerContainer -Name $containerParams.Name
    }
}

if ('MySQL' -in $DBMS) { 
    $containerParams = @{
        Name        = 'MySQL'
        Image       = 'mysql:latest'
        Network     = 'dbms-net'
        Memory      = '2g'
        Port        = @(
            '3306:3306'
        )
        Environment = @(
            'MYSQL_ROOT_PASSWORD=start123'
        )
    }
    Write-LogMessage -Message "Starting setup of container $($containerParams.Name)"
    if (Get-MyDockerContainer -Name $containerParams.Name) {
        Write-LogMessage -Level Verbose -Message "Removing existing container"
        Remove-MyDockerContainer -Name $containerParams.Name -Force
    }
    Write-LogMessage -Message "Building new container from image $($containerParams.Image)"
    New-MyDockerContainer @containerParams
    Wait-MyDockerContainer -Name $containerParams.Name -LogRegex 'ready for connections.*port: 3306 ' -EnableException

    Write-LogMessage -Message "Creating user and database"
    $null = Invoke-MyDockerContainer -Name $containerParams.Name -Shell bash -Command @'
mysql -p'start123' <<END_OF_SQL
CREATE USER 'stackoverflow'@'%' IDENTIFIED BY 'start456';
CREATE DATABASE stackoverflow;
GRANT ALL PRIVILEGES ON stackoverflow.* TO 'stackoverflow'@'%';
exit
END_OF_SQL
'@

    if (-not $ServerContainerOnly) {
        Write-LogMessage -Message "Creating application"
        $output = Invoke-MyDockerContainer -Name PowerShell -Shell pwsh -Command @'
$ProgressPreference = 'SilentlyContinue'
Set-Location -Path /mnt/GitHub/PowerShell-for-DBAs/MySQL
./Application.ps1
'@
        Write-LogMessage -Message "Output: $output"
    }

    if ($StopContainer) {
        Stop-MyDockerContainer -Name $containerParams.Name
    }
}

if ('MariaDB' -in $DBMS) { 
    $containerParams = @{
        Name        = 'MariaDB'
        Image       = 'mariadb:10.9'
        Network     = 'dbms-net'
        Memory      = '2g'
        Port        = @(
            '3307:3306'
        )
        Environment = @(
            'MARIADB_ROOT_PASSWORD=start123'
        )
    }
    Write-LogMessage -Message "Starting setup of container $($containerParams.Name)"
    if (Get-MyDockerContainer -Name $containerParams.Name) {
        Write-LogMessage -Level Verbose -Message "Removing existing container"
        Remove-MyDockerContainer -Name $containerParams.Name -Force
    }
    Write-LogMessage -Message "Building new container from image $($containerParams.Image)"
    New-MyDockerContainer @containerParams
    Wait-MyDockerContainer -Name $containerParams.Name -LogRegex 'port: 3306' -EnableException
    
    Write-LogMessage -Message "Creating user and database"
    $null = Invoke-MyDockerContainer -Name $containerParams.Name -Shell bash -Command @'
mariadb -p'start123' <<END_OF_SQL
CREATE USER 'stackoverflow'@'%' IDENTIFIED BY 'start456';
CREATE DATABASE stackoverflow;
GRANT ALL PRIVILEGES ON stackoverflow.* TO 'stackoverflow'@'%';
exit
END_OF_SQL
'@

    if (-not $ServerContainerOnly) {
        Write-LogMessage -Message "Creating application"
        $output = Invoke-MyDockerContainer -Name PowerShell -Shell pwsh -Command @'
$ProgressPreference = 'SilentlyContinue'
Set-Location -Path /mnt/GitHub/PowerShell-for-DBAs/MySQL
$Env:MYSQL_INSTANCE = 'MariaDB'
./Application.ps1
'@
        Write-LogMessage -Message "Output: $output"
    }

    if ($StopContainer) {
        Stop-MyDockerContainer -Name $containerParams.Name
    }
}

if ('PostgreSQL' -in $DBMS) { 
    $containerParams = @{
        Name        = 'PostgreSQL'
        Image       = 'postgres:latest'
        Network     = 'dbms-net'
        Memory      = '2g'
        Port        = @(
            '5432:5432'
        )
        Environment = @(
            'POSTGRES_PASSWORD=start123'
        )
    }
    Write-LogMessage -Message "Starting setup of container $($containerParams.Name)"
    if (Get-MyDockerContainer -Name $containerParams.Name) {
        Write-LogMessage -Level Verbose -Message "Removing existing container"
        Remove-MyDockerContainer -Name $containerParams.Name -Force
    }
    Write-LogMessage -Message "Building new container from image $($containerParams.Image)"
    New-MyDockerContainer @containerParams
    Wait-MyDockerContainer -Name $containerParams.Name -LogRegex 'database system is ready to accept connections' -EnableException

    Write-LogMessage -Message "Creating user and database"
    $null = Invoke-MyDockerContainer -Name $containerParams.Name -Shell bash -Command @'
su - postgres <<END_OF_SHELL
psql <<END_OF_SQL
CREATE USER stackoverflow WITH PASSWORD 'start456';
CREATE DATABASE stackoverflow WITH OWNER stackoverflow;
END_OF_SQL
END_OF_SHELL
'@

    if (-not $ServerContainerOnly) {
        Write-LogMessage -Message "Creating application"
        $output = Invoke-MyDockerContainer -Name PowerShell -Shell pwsh -Command @'
$ProgressPreference = 'SilentlyContinue'
Set-Location -Path /mnt/GitHub/PowerShell-for-DBAs/PostgreSQL
Add-Type -Path /mnt/NuGet/Microsoft.Extensions.Logging.Abstractions/lib/net7.0/Microsoft.Extensions.Logging.Abstractions.dll
./Application.ps1
'@
        Write-LogMessage -Message "Output: $output"
    }

    if ($StopContainer) {
        Stop-MyDockerContainer -Name $containerParams.Name
    }
}

if ('PostGIS' -in $DBMS) { 
    $containerParams = @{
        Name        = 'PostGIS'
        Image       = 'postgis/postgis:latest'
        Network     = 'dbms-net'
        Memory      = '2g'
        Port        = @(
            '5433:5432'
        )
        Environment = @(
            'POSTGRES_PASSWORD=start123'
        )
    }
    Write-LogMessage -Message "Starting setup of container $($containerParams.Name)"
    if (Get-MyDockerContainer -Name $containerParams.Name) {
        Write-LogMessage -Level Verbose -Message "Removing existing container"
        Remove-MyDockerContainer -Name $containerParams.Name -Force
    }
    Write-LogMessage -Message "Building new container from image $($containerParams.Image)"
    New-MyDockerContainer @containerParams
    Wait-MyDockerContainer -Name $containerParams.Name -LogRegex 'database system is ready to accept connections' -EnableException

    Write-LogMessage -Message "Creating user and database"
    $null = Invoke-MyDockerContainer -Name $containerParams.Name -Shell bash -Command @'
su - postgres <<END_OF_SHELL
psql <<END_OF_SQL
CREATE USER geodemo WITH PASSWORD 'start456';
CREATE DATABASE geodemo WITH OWNER geodemo;
\connect geodemo
CREATE EXTENSION postgis;
END_OF_SQL
END_OF_SHELL
'@

    if ($StopContainer) {
        Stop-MyDockerContainer -Name $containerParams.Name
    }
}

if ($StopContainer) {
    if (Get-MyDockerContainer -Name PowerShell) {
        Stop-MyDockerContainer -Name PowerShell
    }
}
