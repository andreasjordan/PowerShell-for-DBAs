[CmdletBinding()]
param (
    [ValidateSet("SQLServer", "Oracle", "PostgreSQL", "MySQL", "MariaDB", "Db2", "Informix", "Cassandra")][String[]]$DBMS = @("SQLServer", "Oracle", "PostgreSQL", "MySQL", "MariaDB", "Db2", "Informix"),
    [String]$NuGetPath = (Resolve-Path -Path "~/NuGet").Path,
    [String]$GitHubPath = (Resolve-Path -Path "~/GitHub").Path,
    [String]$SoftwarePath = (Resolve-Path -Path "~/Software").Path,
    [Switch]$StopContainer
)

# Test, if we need the container PowerShell-A
$runPowerShellA = $false
foreach ($db in 'SQLServer', 'Oracle', 'MySQL', 'MariaDB', 'PostgreSQL') {
    if ($db -in $DBMS) {
        $runPowerShellA = $true
    }
}

# Test, if we need the container PowerShell-B
$runPowerShellB = $false
foreach ($db in 'Db2', 'Informix') {
    if ($db -in $DBMS) {
        $runPowerShellB = $true
    }
}

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
foreach ($package in 'Oracle.ManagedDataAccess.Core', 'MySql.Data', 'Npgsql', 'Net.IBM.Data.Db2-lnx', 'IBM.Data.DB2.Core-lnx') {
    if (-not (Test-Path -Path $NuGetPath/$package)) {
        Write-LogMessage -Message "Downloading NuGet package $package to $NuGetPath/$package"
        Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/$package -OutFile package.zip -UseBasicParsing
        Expand-Archive -Path package.zip -DestinationPath $NuGetPath/$package
        Remove-Item -Path package.zip
    }
}

if (-not (Get-MyDockerNetwork -Name dbms-net)) {
    $null = New-MyDockerNetwork -Name dbms-net
}

if ($runPowerShellA) {
    # Works for SQL Server, Oracle, MySQL and PostgreSQL, but not for Db2 and Informix.
    $containerParams = @{
        Name        = 'PowerShell-A'
        Image       = 'mcr.microsoft.com/powershell:7.2-ubuntu-22.04'
        Network     = 'dbms-net'
        Memory      = '2g'
        Volume      = @(
            "$($GitHubPath):/mnt/GitHub"
            "$($NuGetPath):/mnt/NuGet"
        )
        Environment = @(
            'SQLSERVER_INSTANCE=SQLServer-1'
            'SQLSERVER_DATABASE=StackOverflow'
            'SQLSERVER_USERNAME=StackOverflow'
            'SQLSERVER_PASSWORD=start456'
            'ORACLE_DLL=/mnt/NuGet/Oracle.ManagedDataAccess.Core/lib/netstandard2.1/Oracle.ManagedDataAccess.dll'
            'ORACLE_INSTANCE=Oracle-1/XEPDB1'
            'ORACLE_USERNAME=stackoverflow'
            'ORACLE_PASSWORD=start456'
            'MYSQL_DLL=/mnt/NuGet/MySql.Data/lib/net6.0/MySql.Data.dll'
            'MYSQL_INSTANCE=MySQL-1'
            'MYSQL_DATABASE=stackoverflow'
            'MYSQL_USERNAME=stackoverflow'
            'MYSQL_PASSWORD=start456'
            'POSTGRESQL_DLL=/mnt/NuGet/Npgsql/lib/net6.0/Npgsql.dll'
            'POSTGRESQL_INSTANCE=PostgreSQL-1'
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
Install-Module -Name dbatools
'@
}

if ($runPowerShellB) {
    # Needed for Db2 and Informix.
    # I only managed to install the Informix client SDK on Ubuntu 18.04, not on 20.04 or 22.04.
    # If you are able to use newer versions, let me know how.
    $containerParams = @{
        Name        = 'PowerShell-B'
        Image       = 'ubuntu:18.04'
        Network     = 'dbms-net'
        Memory      = '2g'
        Volume      = @(
            "$($GitHubPath):/mnt/GitHub"
            "$($NuGetPath):/mnt/NuGet"
            "$($SoftwarePath):/mnt/Software"
        )
        Environment = @(
            "CLIENT_LOCALE=en_US.utf8"
            "INFORMIXDIR=/opt/IBM/Informix_Client-SDK"
            "LD_LIBRARY_PATH=$(
                @(
                    "/mnt/NuGet/Net.IBM.Data.Db2-lnx/buildTransitive/clidriver/lib"
                    "/mnt/NuGet/IBM.Data.DB2.Core-lnx/buildTransitive/clidriver/lib"
                    "/opt/IBM/Informix_Client-SDK/lib"
                    "/opt/IBM/Informix_Client-SDK/lib/cli"
                    "/opt/IBM/Informix_Client-SDK/lib/esql"
                ) -join ':'
            )"
            'DB2_DLL=/mnt/NuGet/Net.IBM.Data.Db2-lnx/lib/net6.0/IBM.Data.Db2.dll'
            'DB2_INSTANCE=Db2-1:50000'
            'DB2_DATABASE=DEMO'
            'DB2_USERNAME=stackoverflow'
            'DB2_PASSWORD=start456'
            'INFORMIX_DLL=/mnt/NuGet/Net.IBM.Data.Db2-lnx/lib/net6.0/IBM.Data.Db2.dll'
            'INFORMIX_INSTANCE=Informix-1:9089'
            'INFORMIX_DATABASE=stackoverflow'
            'INFORMIX_USERNAME=stackoverflow'
            'INFORMIX_PASSWORD=start456'
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

    Write-LogMessage -Message "Installing en_US.utf8"
    $null = Invoke-MyDockerContainer -Name $containerParams.Name -Shell sh -Command @'
apt-get update && \
apt-get install -y locales && \
rm -rf /var/lib/apt/lists/* && \
localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
'@

    Write-LogMessage -Message "Installing Informix client SDK"
    $null = Invoke-MyDockerContainer -Name $containerParams.Name -Shell sh -Command @'
apt-get update && \
apt-get install -y unixodbc-dev libelf-dev && \
cd /tmp && \
tar -xf /mnt/Software/INFO_CLT_SDK_LNX_X86_4.50.FC8.tar
echo 'LICENSE_ACCEPTED=TRUE' > response
echo 'USER_INSTALL_DIR=/opt/IBM/Informix_Client-SDK' >> response
echo 'CHOSEN_INSTALL_FEATURE_LIST=SDK-NETCORE,GLS' >> response
./installclientsdk -i silent -f response
'@

    Write-LogMessage -Message "Installing PowerShell"
    $null = Invoke-MyDockerContainer -Name $containerParams.Name -Shell sh -Command @'
apt-get update && \
apt-get install -y wget apt-transport-https software-properties-common && \
wget -q "https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb" && \
dpkg -i packages-microsoft-prod.deb && \
apt-get update && \
apt-get install -y powershell
'@
}


if ('SQLServer' -in $DBMS) {
    $containerParams = @{
        Name        = 'SQLServer-1'
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

    Write-LogMessage -Message "Creating user"
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

    Write-LogMessage -Message "Creating application with only SMO from dbatools"
    $output = Invoke-MyDockerContainer -Name PowerShell-A -Shell pwsh -Command @'
$ProgressPreference = 'SilentlyContinue'
Set-Location -Path /mnt/GitHub/PowerShell-for-DBAs/SQLServer
./Application.ps1
'@
    Write-LogMessage -Message "Output: $output"

    Write-LogMessage -Message "Creating application with commands from dbatools"
    $output = Invoke-MyDockerContainer -Name PowerShell-A -Shell pwsh -Command @'
$ProgressPreference = 'SilentlyContinue'
Set-Location -Path /mnt/GitHub/PowerShell-for-DBAs/SQLServer
./Application_dbatools.ps1
'@
    Write-LogMessage -Message "Output: $output"

    if ($StopContainer) {
        Stop-MyDockerContainer -Name $containerParams.Name
    }
}

if ('Oracle' -in $DBMS) { 
    # https://docs.oracle.com/cd/E37670_01/E75728/html/oracle-registry-server.html
    # https://container-registry.oracle.com/
    $containerParams = @{
        Name        = 'Oracle-1'
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

    Write-LogMessage -Message "Creating user"
    $null = Invoke-MyDockerContainer -Name $containerParams.Name -Shell bash -Command @'
sqlplus / as sysdba <<END_OF_SQL
ALTER SESSION SET CONTAINER=XEPDB1;
CREATE USER stackoverflow IDENTIFIED BY start456 DEFAULT TABLESPACE users QUOTA UNLIMITED ON users TEMPORARY TABLESPACE temp;
GRANT CREATE SESSION TO stackoverflow;
GRANT ALL PRIVILEGES TO stackoverflow;
exit
END_OF_SQL
'@

    Write-LogMessage -Message "Creating application"
    $output = Invoke-MyDockerContainer -Name PowerShell-A -Shell pwsh -Command @'
$ProgressPreference = 'SilentlyContinue'
Set-Location -Path /mnt/GitHub/PowerShell-for-DBAs/Oracle
./Application.ps1
'@
    Write-LogMessage -Message "Output: $output"

    if ($StopContainer) {
        Stop-MyDockerContainer -Name $containerParams.Name
    }
}

if ('MySQL' -in $DBMS) { 
    $containerParams = @{
        Name        = 'MySQL-1'
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

    Write-LogMessage -Message "Creating application"
    $output = Invoke-MyDockerContainer -Name PowerShell-A -Shell pwsh -Command @'
$ProgressPreference = 'SilentlyContinue'
Set-Location -Path /mnt/GitHub/PowerShell-for-DBAs/MySQL
./Application.ps1
'@
    Write-LogMessage -Message "Output: $output"

    if ($StopContainer) {
        Stop-MyDockerContainer -Name $containerParams.Name
    }
}

if ('MariaDB' -in $DBMS) { 
    $containerParams = @{
        Name        = 'MariaDB-1'
        Image       = 'mariadb:latest'
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

    Write-LogMessage -Message "Creating application"
    $output = Invoke-MyDockerContainer -Name PowerShell-A -Shell pwsh -Command @'
$ProgressPreference = 'SilentlyContinue'
Set-Location -Path /mnt/GitHub/PowerShell-for-DBAs/MySQL
$Env:MYSQL_INSTANCE = 'MariaDB-1'
./Application.ps1
'@
    Write-LogMessage -Message "Output: $output"

    if ($StopContainer) {
        Stop-MyDockerContainer -Name $containerParams.Name
    }
}

if ('PostgreSQL' -in $DBMS) { 
    $containerParams = @{
        Name        = 'PostgreSQL-1'
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

    Write-LogMessage -Message "Creating application"
    $output = Invoke-MyDockerContainer -Name PowerShell-A -Shell pwsh -Command @'
$ProgressPreference = 'SilentlyContinue'
Set-Location -Path /mnt/GitHub/PowerShell-for-DBAs/PostgreSQL
./Application.ps1
'@
    Write-LogMessage -Message "Output: $output"

    if ($StopContainer) {
        Stop-MyDockerContainer -Name $containerParams.Name
    }
}

if ('Db2' -in $DBMS) { 
    $containerParams = @{
        Name        = 'Db2-1'
        Image       = 'ibmcom/db2:latest'
        Network     = 'dbms-net'
        Memory      = '4g'
        Port        = @(
            '50000:50000'
        )
        Environment = @(
            'LICENSE=accept'
            'DB2INST1_PASSWORD=start123'
            'DBNAME=DEMO'
        )
        Privileged  = $true
    }
    Write-LogMessage -Message "Starting setup of container $($containerParams.Name)"
    if (Get-MyDockerContainer -Name $containerParams.Name) {
        Write-LogMessage -Level Verbose -Message "Removing existing container"
        Remove-MyDockerContainer -Name $containerParams.Name -Force
    }
    Write-LogMessage -Message "Building new container from image $($containerParams.Image)"
    New-MyDockerContainer @containerParams
    Wait-MyDockerContainer -Name $containerParams.Name -LogRegex 'Setup has completed' -EnableException
    
    Write-LogMessage -Message "Creating user"
    $null = Invoke-MyDockerContainer -Name $containerParams.Name -Shell bash -Command @'
useradd stackoverflow
echo 'stackoverflow:start456' | chpasswd
'@

    Write-LogMessage -Message "Creating application with /NuGet/Net.IBM.Data.Db2-lnx/lib/net6.0/IBM.Data.Db2.dll"
    $output = Invoke-MyDockerContainer -Name PowerShell-B -Shell pwsh -Command @'
$ProgressPreference = 'SilentlyContinue'
Set-Location -Path /mnt/GitHub/PowerShell-for-DBAs/Db2
./Application.ps1
'@
    Write-LogMessage -Message "Output: $output"

<# Does not work, the pwsh process just aborts somewhere during the process, not always at the same step:
    Write-LogMessage -Message "Creating application with /NuGet/IBM.Data.DB2.Core-lnx/lib/netstandard2.1/IBM.Data.DB2.Core.dll"
    $output = Invoke-MyDockerContainer -Name PowerShell-B -Shell pwsh -Command @'
$ProgressPreference = 'SilentlyContinue'
Set-Location -Path /mnt/GitHub/PowerShell-for-DBAs/Db2
../PowerShell/SetEnvironment.ps1 -Client Docker -Server Docker
$Env:DB2_DLL = '/mnt/NuGet/IBM.Data.DB2.Core-lnx/lib/netstandard2.1/IBM.Data.DB2.Core.dll'
./Application.ps1
'@
    Write-LogMessage -Message "Output: $output"
#>

    if ($StopContainer) {
        Stop-MyDockerContainer -Name $containerParams.Name
    }
}

if ('Informix' -in $DBMS) { 
    # https://github.com/informix/informix-dockerhub-readme/blob/master/14.10.FC7W1/informix-developer-database.md
    $containerParams = @{
        Name        = 'Informix-1'
        Image       = 'ibmcom/informix-developer-database:latest'
        Network     = 'dbms-net'
        Memory      = '2g'
        Port        = @(
            '9088:9088'
            '9089:9089'
        )
        Environment = @(
            'LICENSE=accept'
            'TYPE=oltp'
            'DB_LOCALE=en_US.utf8'
        )
    }
    Write-LogMessage -Message "Starting setup of container $($containerParams.Name)"
    if (Get-MyDockerContainer -Name $containerParams.Name) {
        Write-LogMessage -Level Verbose -Message "Removing existing container"
        Remove-MyDockerContainer -Name $containerParams.Name -Force
    }
    Write-LogMessage -Message "Building new container from image $($containerParams.Image)"
    New-MyDockerContainer @containerParams
    Wait-MyDockerContainer -Name $containerParams.Name -LogRegex 'Started .+ dbWorker threads' -EnableException

    Write-LogMessage -Message "Creating user and database"
    $null = Invoke-MyDockerContainer -Name $containerParams.Name -Shell bash -Command @'
sudo su -c 'useradd stackoverflow'
sudo su -c 'echo 'stackoverflow:start456' | chpasswd'
. ./.bashrc
/opt/ibm/informix/bin/dbaccess <<"END_OF_SQL"
CREATE DATABASE stackoverflow WITH LOG;
GRANT CONNECT TO stackoverflow;
GRANT RESOURCE TO stackoverflow;
END_OF_SQL
'@

    Write-LogMessage -Message "Creating application with /NuGet/Net.IBM.Data.Db2-lnx/lib/net6.0/IBM.Data.Db2.dll"
    $output = Invoke-MyDockerContainer -Name PowerShell-B -Shell pwsh -Command @'
$ProgressPreference = 'SilentlyContinue'
Set-Location -Path /mnt/GitHub/PowerShell-for-DBAs/Informix
$Env:INFORMIX_DLL = '/mnt/NuGet/Net.IBM.Data.Db2-lnx/lib/net6.0/IBM.Data.Db2.dll'
$Env:INFORMIX_INSTANCE = 'Informix-1:9089'
./Application.ps1
'@
    Write-LogMessage -Message "Output: $output"

<# Does not work, the pwsh process just aborts somewhere during the process, not always at the same step:
    Write-LogMessage -Message "Creating application with /NuGet/IBM.Data.DB2.Core-lnx/lib/netstandard2.1/IBM.Data.DB2.Core.dll"
    $output = docker exec -ti PowerShell-B pwsh -c @'
$ProgressPreference = 'SilentlyContinue'
Set-Location -Path /mnt/GitHub/PowerShell-for-DBAs/Informix
../PowerShell/SetEnvironment.ps1 -Client Docker -Server Docker
$Env:INFORMIX_DLL = '/mnt/NuGet/IBM.Data.DB2.Core-lnx/lib/netstandard2.1/IBM.Data.DB2.Core.dll'
./Application.ps1
'@
    Write-LogMessage -Message "Output: $output"
#>

    Write-LogMessage -Message "Creating application with /opt/IBM/Informix_Client-SDK/bin/Informix.Net.Core.dll"
    $output = Invoke-MyDockerContainer -Name PowerShell-B -Shell pwsh -Command @'
$ProgressPreference = 'SilentlyContinue'
Set-Location -Path /mnt/GitHub/PowerShell-for-DBAs/Informix
../PowerShell/SetEnvironment.ps1 -Client Docker -Server Docker
$Env:INFORMIX_DLL = '/opt/IBM/Informix_Client-SDK/bin/Informix.Net.Core.dll'
$Env:INFORMIX_INSTANCE = 'Informix-1:9088:informix'
./Application.ps1
'@
    Write-LogMessage -Message "Output: $output"

    if ($StopContainer) {
        Stop-MyDockerContainer -Name $containerParams.Name
    }
}

if ('Cassandra' -in $DBMS) { 
    $containerParams = @{
        Name        = 'Cassandra-1'
        Image       = 'cassandra:latest'
        Network     = 'dbms-net'
        Memory      = '4g'
        Port        = @(
            '9042:9042'
        )
    }
    Write-LogMessage -Message "Starting setup of container $($containerParams.Name)"
    if (Get-MyDockerContainer -Name $containerParams.Name) {
        Write-LogMessage -Level Verbose -Message "Removing existing container"
        Remove-MyDockerContainer -Name $containerParams.Name -Force
    }
    Write-LogMessage -Message "Building new container from image $($containerParams.Image)"
    New-MyDockerContainer @containerParams
    Wait-MyDockerContainer -Name $containerParams.Name -LogRegex 'Created default superuser role' -EnableException

    Write-LogMessage -Message "Configuring authenticator and authorizer"
    $null = Invoke-MyDockerContainer -Name $containerParams.Name -Shell bash -Command @'
cat /etc/cassandra/cassandra.yaml \
| sed -e 's/^authenticator:.*/authenticator: PasswordAuthenticator/' \
| sed -e 's/^authorizer:.*/authorizer: CassandraAuthorizer/' \
> /etc/cassandra/cassandra_new.yaml
mv /etc/cassandra/cassandra_new.yaml /etc/cassandra/cassandra.yaml
'@

    Write-LogMessage -Message "Restarting container"
    $null = docker restart Cassandra-1
    while (1) {
        $logs = docker logs Cassandra-1 2>&1
        if (($logs -match 'Startup complete').Count -gt 1) { break }
        Start-Sleep -Seconds 1
    }

    # We need to wait some more seconds...
    Start-Sleep -Seconds 10

    Write-LogMessage -Message "Creating keyspace and role"
    $null = Invoke-MyDockerContainer -Name $containerParams.Name -Shell bash -Command @'
cqlsh -u cassandra -p cassandra <<"END_OF_SQL"
CREATE KEYSPACE stackoverflow WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };
CREATE ROLE stackoverflow WITH PASSWORD = 'start456' AND LOGIN = true;
CREATE ROLE stackoverflow_admin;
GRANT ALL PERMISSIONS on KEYSPACE stackoverflow to stackoverflow_admin;
GRANT stackoverflow_admin TO stackoverflow;
END_OF_SQL
'@

<# Does not work yet:
    Write-LogMessage -Message "Creating application"
    $output = docker exec -ti PowerShell-B pwsh -c @'
$ProgressPreference = 'SilentlyContinue'
Set-Location -Path /mnt/GitHub/PowerShell-for-DBAs/Cassandra
../PowerShell/SetEnvironment.ps1 -Client Docker -Server Docker
./Application.ps1
'@
    Write-LogMessage -Message "Output: $output"
#>

    if ($StopContainer) {
        Stop-MyDockerContainer -Name $containerParams.Name
    }
}

if ($StopContainer) {
    if (Get-MyDockerContainer -Name PowerShell-A) {
        Stop-MyDockerContainer -Name PowerShell-A
    }
    if (Get-MyDockerContainer -Name PowerShell-B) {
        Stop-MyDockerContainer -Name PowerShell-B
    }
}
