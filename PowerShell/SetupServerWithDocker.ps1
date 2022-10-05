# Setup of all DBMS with docker

# Remove those DBMS, that you don't want to install
$installDBMS = 'SQLServer', 'Oracle', 'MySQL', 'PostgreSQL', 'Db2', 'Informix'
#$installDBMS = 'SQLServer', 'Oracle'
#$installDBMS = 'MySQL', 'PostgreSQL'
#$installDBMS = 'Db2', 'Informix'

# Set to $true to stop all container after usage
$stopContainer = $false

# Install-Module -Name PSFramework -Scope CurrentUser
Import-Module -Name PSFramework
function Write-LogMessage {
    param(
        [String]$Message,
        [String]$Level = 'Host'
    )
    Write-PSFMessage -Level $Level -Message $Message
}


$network = docker network ls -f name=^dbms-net$
if ($network.Count -eq 1) {
    Write-LogMessage -Message "Creating network dbms-net"
    $null = docker network create dbms-net
}


Write-LogMessage -Message "Starting setup of PowerShell-A"
# Works for SQL Server, Oracle, MySQL and PostgreSQL, but not for Db2 and Informix.

Write-LogMessage -Message "Pulling image mcr.microsoft.com/powershell:7.2-ubuntu-22.04"
$null = docker pull mcr.microsoft.com/powershell:7.2-ubuntu-22.04

$container = docker container ls -a -f name=^/PowerShell-A$
if ($container.Count -gt 1) {
    Write-LogMessage -Message "Removing existing container"
    $null = docker rm -f PowerShell-A
}

Write-LogMessage -Message "Building new container"
$null = docker run --name PowerShell-A --net dbms-net -di mcr.microsoft.com/powershell:7.2-ubuntu-22.04

Write-LogMessage -Message "Creating environment"
$null = docker exec -ti PowerShell-A pwsh -c @'
$ProgressPreference = 'SilentlyContinue'

$null = New-Item -Path /GitHub -ItemType Directory
Invoke-WebRequest -Uri https://github.com/andreasjordan/PowerShell-for-DBAs/archive/refs/heads/main.zip -OutFile repo.zip -UseBasicParsing
Expand-Archive -Path repo.zip -DestinationPath /GitHub
Remove-Item -Path repo.zip
Rename-Item -Path /GitHub/PowerShell-for-DBAs-main -NewName PowerShell-for-DBAs

$null = New-Item -Path /NuGet -ItemType Directory 
foreach ($package in 'Oracle.ManagedDataAccess.Core', 'MySql.Data', 'Npgsql') {
    Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/$package -OutFile package.zip -UseBasicParsing
    Expand-Archive -Path package.zip -DestinationPath /NuGet/$package
    Remove-Item -Path package.zip
}

Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module -Name dbatools
'@


Write-LogMessage -Message "Starting setup of PowerShell-B"
# Needed for Db2 and Informix.

# Installation of Informix client SDK:
# * Ubuntu 22.04: 
#   * https://stackoverflow.com/questions/60186991/installing-informix-csdk-in-an-ubuntu-docker-container
#   * "apt install unixodbc-dev" does not solve the problem
# * Ubuntu 20.04:
#   * Only libncurses.so.5 is missing, but installation was not possible
# * Ubuntu 18.04:
#   * Works, but the used version "Informix Client-SDK 4.10.FC15" does not have the .NET library included.

Write-LogMessage -Message "Pulling image ubuntu:18.04"
$null = docker pull ubuntu:18.04

$container = docker container ls -a -f name=^/PowerShell-B$
if ($container.Count -gt 1) {
    Write-LogMessage -Message "Removing existing container"
    $null = docker rm -f PowerShell-B
}

Write-LogMessage -Message "Building new container"
#$null = docker run --name PowerShell-B --net dbms-net -v /home/anj/Software:/mnt/Software -e LD_LIBRARY_PATH=/NuGet/Net.IBM.Data.Db2-lnx/buildTransitive/clidriver/lib:/NuGet/IBM.Data.DB2.Core-lnx/buildTransitive/clidriver/lib -e CLIENT_LOCALE=en_US.utf8 -di ubuntu:18.04
$null = docker run --name PowerShell-B --net dbms-net -e LD_LIBRARY_PATH=/NuGet/Net.IBM.Data.Db2-lnx/buildTransitive/clidriver/lib:/NuGet/IBM.Data.DB2.Core-lnx/buildTransitive/clidriver/lib -e CLIENT_LOCALE=en_US.utf8 -di ubuntu:18.04

Write-LogMessage -Message "Installing en_US.utf8"
$null = docker exec -ti PowerShell-B sh -c @'
apt-get update && \
apt-get install -y locales && \
rm -rf /var/lib/apt/lists/* && \
localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
'@

<#
Write-LogMessage -Message "Preparing installation of Informix SDK"
$null = docker exec -ti PowerShell-B sh -c @'
apt-get update && \
apt-get install -y unixodbc-dev && \
cd /tmp && \
tar -xf /mnt/Software/clientsdk.4.10.FC15.linux-x86_64.tar
'@
#>

Write-LogMessage -Message "Installing PowerShell"
$null = docker exec -ti PowerShell-B sh -c @'
apt-get update && \
apt-get install -y wget apt-transport-https software-properties-common && \
wget -q "https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb" && \
dpkg -i packages-microsoft-prod.deb && \
apt-get update && \
apt-get install -y powershell
'@

Write-LogMessage -Message "Creating environment"
$null = docker exec -ti PowerShell-B pwsh -c @'
$ProgressPreference = 'SilentlyContinue'

$null = New-Item -Path /GitHub -ItemType Directory
Invoke-WebRequest -Uri https://github.com/andreasjordan/PowerShell-for-DBAs/archive/refs/heads/main.zip -OutFile repo.zip -UseBasicParsing
Expand-Archive -Path repo.zip -DestinationPath /GitHub
Remove-Item -Path repo.zip
Rename-Item -Path /GitHub/PowerShell-for-DBAs-main -NewName PowerShell-for-DBAs

$null = New-Item -Path /NuGet -ItemType Directory 
foreach ($package in 'Net.IBM.Data.Db2-lnx', 'IBM.Data.DB2.Core-lnx') {
    Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/$package -OutFile package.zip -UseBasicParsing
    Expand-Archive -Path package.zip -DestinationPath /NuGet/$package
    Remove-Item -Path package.zip
}
'@


if ('SQLServer' -in $installDBMS) {
    Write-LogMessage -Message "Starting setup of SQLServer-1"

    Write-LogMessage -Message "Pulling image mcr.microsoft.com/mssql/server:2019-latest"
    $null = docker pull mcr.microsoft.com/mssql/server:2019-latest

    $container = docker container ls -a -f name=^/SQLServer-1$
    if ($container.Count -gt 1) {
        Write-LogMessage -Message "Removing existing container"
        $null = docker rm -f SQLServer-1
    }
    
    Write-LogMessage -Message "Building new container"
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
Set-Location -Path /GitHub/PowerShell-for-DBAs/SQLServer
../PowerShell/SetEnvironment.ps1 -Client Docker -Server Docker
./Application.ps1
'@
    Write-LogMessage -Message "Output: $output"

    if ($stopContainer) {
        Write-LogMessage -Message "Stopping container"
        $null = docker stop SQLServer-1
    }
}

if ('Oracle' -in $installDBMS) { 
    # https://docs.oracle.com/cd/E37670_01/E75728/html/oracle-registry-server.html
    # https://container-registry.oracle.com/
    Write-LogMessage -Message "Starting setup of Oracle-1"

    Write-LogMessage -Message "Pulling image container-registry.oracle.com/database/express:latest"
    $null = docker pull container-registry.oracle.com/database/express:latest

    $container = docker container ls -a -f name=^/Oracle-1$
    if ($container.Count -gt 1) {
        Write-LogMessage -Message "Removing existing container"
        $null = docker rm -f Oracle-1
    }

    Write-LogMessage -Message "Building new container"
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
Set-Location -Path /GitHub/PowerShell-for-DBAs/Oracle
../PowerShell/SetEnvironment.ps1 -Client Docker -Server Docker
./Application.ps1
'@
    Write-LogMessage -Message "Output: $output"

    if ($stopContainer) {
        Write-LogMessage -Message "Stopping container"
        $null = docker stop Oracle-1
    }
}

if ('MySQL' -in $installDBMS) { 
    Write-LogMessage -Message "Starting setup of MySQL-1"

    Write-LogMessage -Message "Pulling image mysql:latest"
    $null = docker pull mysql:latest

    $container = docker container ls -a -f name=^/MySQL-1$
    if ($container.Count -gt 1) {
        Write-LogMessage -Message "Removing existing container"
        $null = docker rm -f MySQL-1
    }
    
    Write-LogMessage -Message "Building new container"
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
Set-Location -Path /GitHub/PowerShell-for-DBAs/MySQL
../PowerShell/SetEnvironment.ps1 -Client Docker -Server Docker
./Application.ps1
'@
    Write-LogMessage -Message "Output: $output"

    if ($stopContainer) {
        Write-LogMessage -Message "Stopping container"
        $null = docker stop MySQL-1
    }
}

if ('PostgreSQL' -in $installDBMS) { 
    Write-LogMessage -Message "Starting setup of PostgreSQL-1"

    Write-LogMessage -Message "Pulling image postgres:latest"
    $null = docker pull postgres:latest

    $container = docker container ls -a -f name=^/PostgreSQL-1$
    if ($container.Count -gt 1) {
        Write-LogMessage -Message "Removing existing container"
        $null = docker rm -f PostgreSQL-1
    }

    Write-LogMessage -Message "Building new container"
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
Set-Location -Path /GitHub/PowerShell-for-DBAs/PostgreSQL
../PowerShell/SetEnvironment.ps1 -Client Docker -Server Docker
./Application.ps1
'@
    Write-LogMessage -Message "Output: $output"

    if ($stopContainer) {
        Write-LogMessage -Message "Stopping container"
        $null = docker stop PostgreSQL-1
    }
}

if ('Db2' -in $installDBMS) { 
    Write-LogMessage -Message "Starting setup of Db2-1"

    Write-LogMessage -Message "Pulling image ibmcom/db2:latest"
    $null = docker pull ibmcom/db2:latest

    $container = docker container ls -a -f name=^/Db2-1$
    if ($container.Count -gt 1) {
        Write-LogMessage -Message "Removing existing container"
        $null = docker rm -f Db2-1
    }
    
    Write-LogMessage -Message "Building new container"
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

    Write-LogMessage -Message "Creating application"
    $output = docker exec -ti PowerShell-B pwsh -c @'
$ProgressPreference = 'SilentlyContinue'
Set-Location -Path /GitHub/PowerShell-for-DBAs/Db2
../PowerShell/SetEnvironment.ps1 -Client Docker -Server Docker
./Application.ps1
'@
    Write-LogMessage -Message "Output: $output"

<# Does not work, the pwsh process just aborts somewhere during the process, nmot always at the same step:
    Write-LogMessage -Message "Creating application"
    $output = docker exec -ti PowerShell-B pwsh -c @'
$ProgressPreference = 'SilentlyContinue'
Set-Location -Path /GitHub/PowerShell-for-DBAs/Db2
../PowerShell/SetEnvironment.ps1 -Client Docker -Server Docker
$Env:DB2_DLL = '/NuGet/IBM.Data.DB2.Core-lnx/lib/netstandard2.1/IBM.Data.DB2.Core.dll'
./Application.ps1
'@
    Write-LogMessage -Message "Output: $output"
#>

    if ($stopContainer) {
        Write-LogMessage -Message "Stopping container"
        $null = docker stop Db2-1
    }
}

if ('Informix' -in $installDBMS) { 
    # https://github.com/informix/informix-dockerhub-readme/blob/master/14.10.FC7W1/informix-developer-database.md
    Write-LogMessage -Message "Starting setup of Informix-1"

    Write-LogMessage -Message "Pulling image ibmcom/informix-developer-database:latest"
    $null = docker pull ibmcom/informix-developer-database:latest

    $container = docker container ls -a -f name=^/Informix-1$
    if ($container.Count -gt 1) {
        Write-LogMessage -Message "Removing existing container"
        $null = docker rm -f Informix-1
    }

    Write-LogMessage -Message "Building new container"
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

    Write-LogMessage -Message "Creating application"
    $output = docker exec -ti PowerShell-B pwsh -c @'
$ProgressPreference = 'SilentlyContinue'
Set-Location -Path /GitHub/PowerShell-for-DBAs/Informix
../PowerShell/SetEnvironment.ps1 -Client Docker -Server Docker
./Application.ps1
'@
    Write-LogMessage -Message "Output: $output"

    Write-LogMessage -Message "Creating application"
    $output = docker exec -ti PowerShell-B pwsh -c @'
$ProgressPreference = 'SilentlyContinue'
Set-Location -Path /GitHub/PowerShell-for-DBAs/Informix
../PowerShell/SetEnvironment.ps1 -Client Docker -Server Docker
$Env:DB2_DLL = '/NuGet/IBM.Data.DB2.Core-lnx/lib/netstandard2.1/IBM.Data.DB2.Core.dll'
./Application.ps1
# After installing the client SDK:
#$Env:INFORMIX_DLL = '/...Client SDK...'
#$Env:INFORMIX_INSTANCE = 'Informix-1:9088:informix'
#./Application.ps1
'@
    Write-LogMessage -Message "Output: $output"

    if ($stopContainer) {
        Write-LogMessage -Message "Stopping container"
        $null = docker stop Informix-1
    }
}

if ($stopContainer) {
    Write-LogMessage -Message "Stopping PowerShell container"
    $null = docker stop PowerShell-A
    $null = docker stop PowerShell-B
}
