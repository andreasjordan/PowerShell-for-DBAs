$ErrorActionPreference = 'Stop'

$basePath = $Env:DLL_BASE
if (-not $basePath) {
    if ($Env:OS -eq 'Windows_NT') {
        $basePath = $env:HOMEDRIVE + $env:HOMEPATH + '\DLL'
    } else {
        $basePath = $env:HOME + '\DLL'
    }
}

if (-not (Test-Path -Path $basePath)) {
    $null = New-Item -Path $basePath -ItemType Directory
}
Set-Location -Path $basePath


# SQLServer: PowerShell module dbatools
Install-Module -Name dbatools -Scope CurrentUser -Force


# Oracle: NuGet package Oracle.ManagedDataAccess
if ($Env:OS -eq 'Windows_NT') {
    Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/Oracle.ManagedDataAccess -OutFile Oracle.ManagedDataAccess.nupkg.zip -UseBasicParsing
    Expand-Archive -Path Oracle.ManagedDataAccess.nupkg.zip -DestinationPath .\Oracle.ManagedDataAccess
    Remove-Item -Path Oracle.ManagedDataAccess.nupkg.zip
}

# Oracle: NuGet package Oracle.ManagedDataAccess.Core
Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/Oracle.ManagedDataAccess.Core -OutFile Oracle.ManagedDataAccess.Core.nupkg.zip -UseBasicParsing
Expand-Archive -Path Oracle.ManagedDataAccess.Core.nupkg.zip -DestinationPath .\Oracle.ManagedDataAccess.Core
Remove-Item -Path Oracle.ManagedDataAccess.Core.nupkg.zip

# Oracle: Oracle 19c client
# later...

# Oracle: Devart dotConnect for Oracle 10.0 Express
# later...


# MySQL: NuGet package MySql.Data
Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/MySql.Data -OutFile MySql.Data.nupkg.zip -UseBasicParsing
Expand-Archive -Path MySql.Data.nupkg.zip -DestinationPath .\MySql.Data
Remove-Item -Path MySql.Data.nupkg.zip

# MySQL: MySQL Connector/NET 8.0.30
Invoke-WebRequest -Uri https://dev.mysql.com/get/Downloads/Connector-Net/mysql-connector-net-8.0.30-noinstall.zip -OutFile mysql-connector-net-noinstall.zip -UseBasicParsing
Expand-Archive -Path mysql-connector-net-noinstall.zip -DestinationPath .\mysql-connector-net
Remove-Item -Path mysql-connector-net-noinstall.zip

# MySQL: Devart dotConnect for MySQL 9.0 Express
# later...


# PostgreSQL: NuGet package Npgsql
Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/Npgsql -OutFile Npgsql.nupkg.zip -UseBasicParsing
Expand-Archive -Path Npgsql.nupkg.zip -DestinationPath .\Npgsql
Remove-Item -Path Npgsql.nupkg.zip

# PostgreSQL: Devart dotConnect for PostgreSQL 8.0 Express
# later...


<#

# PowerShell 5.1:

Import-Module -Name dbatools
Set-Location -Path D:\GitHub\PowerShell-for-DBAs\SQLServer
.\Application.ps1
# Data import finished in 126.4071942 seconds


$Env:ORACLE_DLL = 'C:\Users\Admin\DLL\Oracle.ManagedDataAccess\lib\net462\Oracle.ManagedDataAccess.dll'
Set-Location -Path D:\GitHub\PowerShell-for-DBAs\Oracle
.\Application.ps1
# Data import finished in 51.7658878 seconds

$Env:ORACLE_DLL = 'D:\oracle\product\19.0.0\client_1\odp.net\managed\common\Oracle.ManagedDataAccess.dll'
Set-Location -Path D:\GitHub\PowerShell-for-DBAs\Oracle
.\Application.ps1
# Data import finished in 51.7327631 seconds

$Env:ORACLE_DLL = 'C:\Program Files (x86)\Devart\dotConnect\Oracle\Devart.Data.Oracle.dll'
Set-Location -Path D:\GitHub\PowerShell-for-DBAs\Oracle
.\Application.ps1
# Data import finished in 72.6728711 seconds


$Env:MYSQL_DLL = 'C:\Users\Admin\DLL\MySql.Data\lib\net452\MySql.Data.dll'
Set-Location -Path D:\GitHub\PowerShell-for-DBAs\MySQL
.\Application.ps1
# Data import finished in 74.37553 seconds

$Env:MYSQL_DLL = 'C:\Users\Admin\DLL\mysql-connector-net\v4.5.2\MySql.Data.dll'
Set-Location -Path D:\GitHub\PowerShell-for-DBAs\MySQL
.\Application.ps1
# Data import finished in 74.016169 seconds

$Env:MYSQL_DLL = 'C:\Program Files (x86)\Devart\dotConnect\MySQL\Devart.Data.MySql.dll'
Set-Location -Path D:\GitHub\PowerShell-for-DBAs\MySQL
.\Application.ps1
# Data import finished in 73.3130471 seconds


$Env:POSTGRESQL_DLL = 'C:\Program Files (x86)\Devart\dotConnect\PostgreSQL\Devart.Data.PostgreSql.dll'
Set-Location -Path D:\GitHub\PowerShell-for-DBAs\PostgreSQL
.\Application.ps1
# Data import finished in 52.3127586 seconds


# PowerShell 7.2 on Windows:

Import-Module -Name dbatools
Set-Location -Path D:\GitHub\PowerShell-for-DBAs\SQLServer
.\Application.ps1
# Data import finished in 107.5198866 seconds


$Env:ORACLE_DLL = 'C:\Users\Admin\DLL\Oracle.ManagedDataAccess.Core\lib\netstandard2.1\Oracle.ManagedDataAccess.dll'
Set-Location -Path D:\GitHub\PowerShell-for-DBAs\Oracle
.\Application.ps1
# Data import finished in 37.0386475 seconds

# Currently problems with Devart.Data.Oracle.dll - need fresh install to retest


$Env:MYSQL_DLL = 'C:\Users\Admin\DLL\MySql.Data\lib\net6.0\MySql.Data.dll'
Set-Location -Path D:\GitHub\PowerShell-for-DBAs\MySQL
.\Application.ps1
# Data import finished in 60.4513448 seconds

$Env:MYSQL_DLL = 'C:\Users\Admin\DLL\mysql-connector-net\net6.0\MySql.Data.dll'
Set-Location -Path D:\GitHub\PowerShell-for-DBAs\MySQL
.\Application.ps1
# Data import finished in 58.8327353 seconds

$Env:MYSQL_DLL = 'C:\Program Files (x86)\Devart\dotConnect\MySQL\Devart.Data.MySql.dll'
Set-Location -Path D:\GitHub\PowerShell-for-DBAs\MySQL
.\Application.ps1
# Data import finished in 58.8821139 seconds


$Env:POSTGRESQL_DLL = 'C:\Users\Admin\DLL\Npgsql\lib\net6.0\Npgsql.dll'
Set-Location -Path D:\GitHub\PowerShell-for-DBAs\PostgreSQL
.\Application.ps1
# Data import finished in 33.8516163 seconds

$Env:POSTGRESQL_DLL = 'C:\Program Files (x86)\Devart\dotConnect\PostgreSQL\Devart.Data.PostgreSql.dll'
Set-Location -Path D:\GitHub\PowerShell-for-DBAs\PostgreSQL
.\Application.ps1
# Data import finished in 38.9124702 seconds


# PowerShell 7.2 on Linux:

Import-Module -Name dbatools
$EnvironmentServerComputerName = '192.168.131.203'
Set-Location -Path /home/anj/GitHub/PowerShell-for-DBAs/SQLServer
./Application.ps1
# Data import finished in 107.5198866 seconds


$Env:ORACLE_DLL = '/home/anj/DLL/Oracle.ManagedDataAccess.Core/lib/netstandard2.1/Oracle.ManagedDataAccess.dll'
$EnvironmentServerComputerName = '192.168.131.203'
Set-Location -Path /home/anj/GitHub/PowerShell-for-DBAs/Oracle
./Application.ps1


$Env:MYSQL_DLL = '/home/anj/DLL/MySql.Data/lib/net6.0/MySql.Data.dll'
$EnvironmentServerComputerName = '192.168.131.203'
Set-Location -Path /home/anj/GitHub/PowerShell-for-DBAs/MySQL
./Application.ps1

$Env:MYSQL_DLL = '/home/anj/DLL/mysql-connector-net/net6.0/MySql.Data.dll'
$EnvironmentServerComputerName = '192.168.131.203'
Set-Location -Path /home/anj/GitHub/PowerShell-for-DBAs/MySQL
./Application.ps1


$Env:POSTGRESQL_DLL = '/home/anj/DLL/Npgsql/lib/net6.0/Npgsql.dll'
$EnvironmentServerComputerName = '192.168.131.203'
Set-Location -Path /home/anj/GitHub/PowerShell-for-DBAs/PostgreSQL
./Application.ps1


#>
