[CmdletBinding()]
param (
    [ValidateSet("SQLServer", "Oracle", "PostgreSQL", "MySQL", "Db2", "Informix")][String[]]$DBMS = @("SQLServer", "Oracle", "PostgreSQL", "MySQL", "Db2", "Informix"),
    [String]$NuGetPath = "~/NuGet",
    [String]$GitHubPath = "~/GitHub",
    [String]$SoftwarePath = "~/Software",
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

# Download the needed NuGet packages
foreach ($package in 'Oracle.ManagedDataAccess.Core', 'MySql.Data', 'Npgsql', 'Net.IBM.Data.Db2-lnx', 'IBM.Data.DB2.Core-lnx') {
    if (-not (Test-Path -Path $NuGetPath/$package)) {
        Write-LogMessage -Message "Downloading NuGet package $package to $NuGetPath/$package"
        Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/$package -OutFile package.zip -UseBasicParsing
        Expand-Archive -Path package.zip -DestinationPath $NuGetPath/$package
        Remove-Item -Path package.zip
    }
}

$network = docker network ls -f name=^dbms-net$
if ($network.Count -eq 1) {
    Write-LogMessage -Message "Creating network dbms-net"
    $null = docker network create dbms-net
}

if ($runPowerShellA) {
    Write-LogMessage -Message "Starting setup of PowerShell-A"
    # Works for SQL Server, Oracle, MySQL and PostgreSQL, but not for Db2 and Informix.
    
    $container = docker container ls -a -f name=^/PowerShell-A$
    if ($container.Count -gt 1) {
        Write-LogMessage -Level Verbose -Message "Removing existing container"
        $null = docker rm -f PowerShell-A
    }
    
    Write-LogMessage -Message "Building new container from image mcr.microsoft.com/powershell:7.2-ubuntu-22.04"
    $null = docker run --name PowerShell-A --net dbms-net -v ${GitHubPath}:/mnt/GitHub -v ${NuGetPath}:/mnt/NuGet -di mcr.microsoft.com/powershell:7.2-ubuntu-22.04
    
    Write-LogMessage -Message "Creating environment"
    $null = docker exec -ti PowerShell-A pwsh -c @'
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module -Name dbatools
'@
}

if ($runPowerShellB) {
    Write-LogMessage -Message "Starting setup of PowerShell-B"
    # Needed for Db2 and Informix.
    # I only managed to install the Informix client SDK on Ubuntu 18.04, not on 20.04 or 22.04.
    # If you are able to use newer versions, let me know how.

    $container = docker container ls -a -f name=^/PowerShell-B$
    if ($container.Count -gt 1) {
        Write-LogMessage -Level Verbose -Message "Removing existing container"
        $null = docker rm -f PowerShell-B
    }

    Write-LogMessage -Message "Building new container from image ubuntu:18.04"
    $null = docker run --name PowerShell-B --net dbms-net -v ${GitHubPath}:/mnt/GitHub -v ${NuGetPath}:/mnt/NuGet -v ${SoftwarePath}:/mnt/Software -e INFORMIXDIR=/opt/IBM/Informix_Client-SDK -e LD_LIBRARY_PATH=/mnt/NuGet/Net.IBM.Data.Db2-lnx/buildTransitive/clidriver/lib:/mnt/NuGet/IBM.Data.DB2.Core-lnx/buildTransitive/clidriver/lib:/opt/IBM/Informix_Client-SDK/lib:/opt/IBM/Informix_Client-SDK/lib/cli:/opt/IBM/Informix_Client-SDK/lib/esql -e CLIENT_LOCALE=en_US.utf8 -di ubuntu:18.04

    Write-LogMessage -Message "Installing en_US.utf8"
    $null = docker exec -ti PowerShell-B sh -c @'
apt-get update && \
apt-get install -y locales && \
rm -rf /var/lib/apt/lists/* && \
localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
'@

    Write-LogMessage -Message "Installing Informix client SDK"
    $null = docker exec -ti PowerShell-B sh -c @'
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
    $null = docker exec -ti PowerShell-B sh -c @'
apt-get update && \
apt-get install -y wget apt-transport-https software-properties-common && \
wget -q "https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb" && \
dpkg -i packages-microsoft-prod.deb && \
apt-get update && \
apt-get install -y powershell
'@
}


if ('SQLServer' -in $DBMS) {
    Write-LogMessage -Message "Starting setup of SQLServer-1"

    $container = docker container ls -a -f name=^/SQLServer-1$
    if ($container.Count -gt 1) {
        Write-LogMessage -Level Verbose -Message "Removing existing container"
        $null = docker rm -f SQLServer-1
    }
    
    Write-LogMessage -Message "Building new container from image mcr.microsoft.com/mssql/server:2019-latest"
    $null = docker run --name SQLServer-1 --net dbms-net --cpus=2 --memory=2g -p 1433:1433 -e ACCEPT_EULA=Y -e "MSSQL_SA_PASSWORD=P#ssw0rd" -e MSSQL_PID=Express -d mcr.microsoft.com/mssql/server:2019-latest
    while (1) {
        $logs = docker logs SQLServer-1 2>&1
        if ($logs -match 'SQL Server is now ready for client connections') { break }
        Start-Sleep -Seconds 1
    }

    Write-LogMessage -Message "Creating user"
    $null = docker exec -ti SQLServer-1 bash -c @'
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

    Write-LogMessage -Message "Creating application"
    $output = docker exec -ti PowerShell-A pwsh -c @'
$ProgressPreference = 'SilentlyContinue'
Set-Location -Path /mnt/GitHub/PowerShell-for-DBAs/SQLServer
../PowerShell/SetEnvironment.ps1 -Client Docker -Server Docker
./Application.ps1
'@
    Write-LogMessage -Message "Output: $output"

    if ($StopContainer) {
        $null = docker stop SQLServer-1
    }
}

if ('Oracle' -in $DBMS) { 
    # https://docs.oracle.com/cd/E37670_01/E75728/html/oracle-registry-server.html
    # https://container-registry.oracle.com/
    Write-LogMessage -Message "Starting setup of Oracle-1"

    $container = docker container ls -a -f name=^/Oracle-1$
    if ($container.Count -gt 1) {
        Write-LogMessage -Level Verbose -Message "Removing existing container"
        $null = docker rm -f Oracle-1
    }

    Write-LogMessage -Message "Building new container from image container-registry.oracle.com/database/express:latest"
    $null = docker run --name Oracle-1 --net dbms-net --cpus=2 --memory=2g -p 1521:1521 -p 5500:5500 -e ORACLE_PWD=start123 -e ORACLE_CHARACTERSET=AL32UTF8 -d container-registry.oracle.com/database/express:latest
    while (1) {
        $logs = docker logs Oracle-1 2>&1
        if ($logs -match 'DATABASE IS READY TO USE!') { break }
        Start-Sleep -Seconds 1
    }

    Write-LogMessage -Message "Creating user"
    $null = docker exec -ti Oracle-1 bash -c @'
sqlplus / as sysdba <<END_OF_SQL
ALTER SESSION SET CONTAINER=XEPDB1;
CREATE USER stackoverflow IDENTIFIED BY start456 DEFAULT TABLESPACE users QUOTA UNLIMITED ON users TEMPORARY TABLESPACE temp;
GRANT CREATE SESSION TO stackoverflow;
GRANT ALL PRIVILEGES TO stackoverflow;
exit
END_OF_SQL
'@

    Write-LogMessage -Message "Creating application"
    $output = docker exec -ti PowerShell-A pwsh -c @'
$ProgressPreference = 'SilentlyContinue'
Set-Location -Path /mnt/GitHub/PowerShell-for-DBAs/Oracle
../PowerShell/SetEnvironment.ps1 -Client Docker -Server Docker
./Application.ps1
'@
    Write-LogMessage -Message "Output: $output"

    if ($StopContainer) {
        $null = docker stop Oracle-1
    }
}

if ('MySQL' -in $DBMS) { 
    Write-LogMessage -Message "Starting setup of MySQL-1"

    $container = docker container ls -a -f name=^/MySQL-1$
    if ($container.Count -gt 1) {
        Write-LogMessage -Level Verbose -Message "Removing existing container"
        $null = docker rm -f MySQL-1
    }
    
    Write-LogMessage -Message "Building new container from image mysql:latest"
    $null = docker run --name MySQL-1 --net dbms-net --cpus=2 --memory=2g -p 3306:3306 -e MYSQL_ROOT_PASSWORD=start123 -d mysql:latest
    while (1) {
        $logs = docker logs MySQL-1 2>&1
        if ($logs -match 'ready for connections.*port: 3306 ') { break }
        Start-Sleep -Seconds 1
    }

    Write-LogMessage -Message "Creating user and database"
    $null = docker exec -ti MySQL-1 bash -c @'
mysql -p'start123' <<END_OF_SQL
CREATE USER 'stackoverflow'@'%' IDENTIFIED BY 'start456';
CREATE DATABASE stackoverflow;
GRANT ALL PRIVILEGES ON stackoverflow.* TO 'stackoverflow'@'%';
exit
END_OF_SQL
'@

    Write-LogMessage -Message "Creating application"
    $output = docker exec -ti PowerShell-A pwsh -c @'
$ProgressPreference = 'SilentlyContinue'
Set-Location -Path /mnt/GitHub/PowerShell-for-DBAs/MySQL
../PowerShell/SetEnvironment.ps1 -Client Docker -Server Docker
./Application.ps1
'@
    Write-LogMessage -Message "Output: $output"

    if ($StopContainer) {
        $null = docker stop MySQL-1
    }
}

if ('MariaDB' -in $DBMS) { 
    Write-LogMessage -Message "Starting setup of MariaDB-1"

    $container = docker container ls -a -f name=^/MariaDB-1$
    if ($container.Count -gt 1) {
        Write-LogMessage -Level Verbose -Message "Removing existing container"
        $null = docker rm -f MariaDB-1
    }
    
    Write-LogMessage -Message "Building new container from image mariadb:latest"
    $null = docker run --name MariaDB-1 --net dbms-net --cpus=2 --memory=2g -p 3307:3306 -e MARIADB_ROOT_PASSWORD=start123 -d mariadb:latest
    while (1) {
        $logs = docker logs MariaDB-1 2>&1
        if ($logs -match 'port: 3306') { break }
        Start-Sleep -Seconds 1
    }
    
    Write-LogMessage -Message "Creating user and database"
    $null = docker exec -ti MariaDB-1 bash -c @'
mariadb -p'start123' <<END_OF_SQL
CREATE USER 'stackoverflow'@'%' IDENTIFIED BY 'start456';
CREATE DATABASE stackoverflow;
GRANT ALL PRIVILEGES ON stackoverflow.* TO 'stackoverflow'@'%';
exit
END_OF_SQL
'@

    Write-LogMessage -Message "Creating application"
    $output = docker exec -ti PowerShell-A pwsh -c @'
$ProgressPreference = 'SilentlyContinue'
Set-Location -Path /mnt/GitHub/PowerShell-for-DBAs/MySQL
../PowerShell/SetEnvironment.ps1 -Client Docker -Server Docker
$Env:MYSQL_INSTANCE = 'MariaDB-1'
./Application.ps1
'@
    Write-LogMessage -Message "Output: $output"

    if ($StopContainer) {
        $null = docker stop MariaDB-1
    }
}

if ('PostgreSQL' -in $DBMS) { 
    Write-LogMessage -Message "Starting setup of PostgreSQL-1"

    $container = docker container ls -a -f name=^/PostgreSQL-1$
    if ($container.Count -gt 1) {
        Write-LogMessage -Level Verbose -Message "Removing existing container"
        $null = docker rm -f PostgreSQL-1
    }

    Write-LogMessage -Message "Building new container from image postgres:latest"
    $null = docker run --name PostgreSQL-1 --net dbms-net --cpus=2 --memory=2g -e POSTGRES_PASSWORD=start123 -p 5432:5432 -d postgres:latest
    while (1) {
        $logs = docker logs PostgreSQL-1 2>&1
        if ($logs -match 'database system is ready to accept connections') { break }
        Start-Sleep -Seconds 1
    }

    Write-LogMessage -Message "Creating user and database"
    $null = docker exec -ti PostgreSQL-1 bash -c @'
su - postgres <<"END_OF_SHELL"
psql <<"END_OF_SQL"
CREATE USER stackoverflow WITH PASSWORD 'start456';
CREATE DATABASE stackoverflow WITH OWNER stackoverflow;
END_OF_SQL
END_OF_SHELL
'@

    Write-LogMessage -Message "Creating application"
    $output = docker exec -ti PowerShell-A pwsh -c @'
$ProgressPreference = 'SilentlyContinue'
Set-Location -Path /mnt/GitHub/PowerShell-for-DBAs/PostgreSQL
../PowerShell/SetEnvironment.ps1 -Client Docker -Server Docker
./Application.ps1
'@
    Write-LogMessage -Message "Output: $output"

    if ($StopContainer) {
        $null = docker stop PostgreSQL-1
    }
}

if ('Db2' -in $DBMS) { 
    Write-LogMessage -Message "Starting setup of Db2-1"

    $container = docker container ls -a -f name=^/Db2-1$
    if ($container.Count -gt 1) {
        Write-LogMessage -Level Verbose -Message "Removing existing container"
        $null = docker rm -f Db2-1
    }
    
    Write-LogMessage -Message "Building new container from image ibmcom/db2:latest"
    $null = docker run --name Db2-1 --net dbms-net --cpus=2 --memory=3g --privileged=true -p 50000:50000 -e LICENSE=accept -e DB2INST1_PASSWORD=start123 -e DBNAME=DEMO -d ibmcom/db2:latest
    while (1) {
        $logs = docker logs Db2-1 2>&1
        if ($logs -match 'Setup has completed') { break }
        Start-Sleep -Seconds 1
    }
    
    Write-LogMessage -Message "Creating user"
    $null = docker exec -ti Db2-1 sh -c @'
useradd stackoverflow
echo "stackoverflow:start456" | chpasswd
'@

    Write-LogMessage -Message "Creating application with /NuGet/Net.IBM.Data.Db2-lnx/lib/net6.0/IBM.Data.Db2.dll"
    $output = docker exec -ti PowerShell-B pwsh -c @'
$ProgressPreference = 'SilentlyContinue'
Set-Location -Path /mnt/GitHub/PowerShell-for-DBAs/Db2
../PowerShell/SetEnvironment.ps1 -Client Docker -Server Docker
./Application.ps1
'@
    Write-LogMessage -Message "Output: $output"

<# Does not work, the pwsh process just aborts somewhere during the process, not always at the same step:
    Write-LogMessage -Message "Creating application with /NuGet/IBM.Data.DB2.Core-lnx/lib/netstandard2.1/IBM.Data.DB2.Core.dll"
    $output = docker exec -ti PowerShell-B pwsh -c @'
$ProgressPreference = 'SilentlyContinue'
Set-Location -Path /mnt/GitHub/PowerShell-for-DBAs/Db2
../PowerShell/SetEnvironment.ps1 -Client Docker -Server Docker
$Env:DB2_DLL = '/mnt/NuGet/IBM.Data.DB2.Core-lnx/lib/netstandard2.1/IBM.Data.DB2.Core.dll'
./Application.ps1
'@
    Write-LogMessage -Message "Output: $output"
#>

    if ($StopContainer) {
        $null = docker stop Db2-1
    }
}

if ('Informix' -in $DBMS) { 
    # https://github.com/informix/informix-dockerhub-readme/blob/master/14.10.FC7W1/informix-developer-database.md
    Write-LogMessage -Message "Starting setup of Informix-1"

    $container = docker container ls -a -f name=^/Informix-1$
    if ($container.Count -gt 1) {
        Write-LogMessage -Level Verbose -Message "Removing existing container"
        $null = docker rm -f Informix-1
    }

    Write-LogMessage -Message "Building new container from image ibmcom/informix-developer-database:latest"
    $null = docker run --name Informix-1 --net dbms-net --cpus=2 --memory=2g --privileged=true -p 9088:9088 -p 9089:9089 -e LICENSE=accept -e TYPE=oltp -e DB_LOCALE=en_US.utf8 -d ibmcom/informix-developer-database:latest
    while (1) {
        $logs = docker logs Informix-1 2>&1
        if ($logs -match 'Started .+ dbWorker threads') { break }
        Start-Sleep -Seconds 1
    }

    Write-LogMessage -Message "Creating user and database"
    $null = docker exec -ti Informix-1 bash -c @'
sudo su -c 'useradd stackoverflow'
sudo su -c 'echo 'stackoverflow:start456' | chpasswd'
. ./.bashrc
/opt/ibm/informix/bin/dbaccess <<"END_OF_SQL"
CREATE DATABASE stackoverflow WITH BUFFERED LOG;
GRANT CONNECT TO stackoverflow;
GRANT RESOURCE TO stackoverflow;
END_OF_SQL
'@

    Write-LogMessage -Message "Creating application with /NuGet/Net.IBM.Data.Db2-lnx/lib/net6.0/IBM.Data.Db2.dll"
    $output = docker exec -ti PowerShell-B pwsh -c @'
$ProgressPreference = 'SilentlyContinue'
Set-Location -Path /mnt/GitHub/PowerShell-for-DBAs/Informix
../PowerShell/SetEnvironment.ps1 -Client Docker -Server Docker
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
    $output = docker exec -ti PowerShell-B pwsh -c @'
$ProgressPreference = 'SilentlyContinue'
Set-Location -Path /mnt/GitHub/PowerShell-for-DBAs/Informix
../PowerShell/SetEnvironment.ps1 -Client Docker -Server Docker
$Env:INFORMIX_DLL = '/opt/IBM/Informix_Client-SDK/bin/Informix.Net.Core.dll'
$Env:INFORMIX_INSTANCE = 'Informix-1:9088:informix'
./Application.ps1
'@
    Write-LogMessage -Message "Output: $output"

    if ($StopContainer) {
        $null = docker stop Informix-1
    }
}

if ('Cassandra' -in $DBMS) { 
    Write-LogMessage -Message "Starting setup of Cassandra-1"

    Write-LogMessage -Message "Pulling image cassandra:latest"
    $null = docker pull cassandra:latest

    $container = docker container ls -a -f name=^/Cassandra-1$
    if ($container.Count -gt 1) {
        Write-LogMessage -Level Verbose -Message "Removing existing container"
        $null = docker rm -f Cassandra-1
    }

    Write-LogMessage -Message "Building new container"
    $null = docker run --name Cassandra-1 --net dbms-net --cpus=2 --memory=4g -p 9042:9042 -d cassandra:latest
    while (1) {
        $logs = docker logs Cassandra-1 2>&1
        if ($logs -match 'Created default superuser role') { break }
        Start-Sleep -Seconds 1
    }

    Write-LogMessage -Message "Configuring authenticator and authorizer"
    docker exec -ti Cassandra-1 bash -c @'
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
    docker exec -ti Cassandra-1 bash -c @'
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
        $null = docker stop Informix-1
    }
}

if ($StopContainer) {
    $null = docker stop PowerShell-A
    $null = docker stop PowerShell-B
}
