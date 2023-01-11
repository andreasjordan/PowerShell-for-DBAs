[CmdletBinding()]
param (
    [String]$DatabaseDefinitionFile = '/tmp/tmp_DatabaseDefinition.json'
)

# New version, work in progress.
# * No support for Db2, Informix and Cassandra
# * No additional PowerShell container
# * Target environment is my lab based on AutomatedLab
# * Only works with PowerShell 7.3 (mainly to also support PostgreSQL)
# * Only works from within the docker host

$ErrorActionPreference = 'Stop'

$DatabaseDefinition = Get-Content -Path $DatabaseDefinitionFile | ConvertFrom-Json

# Load all needed DLLs
$dllDefinition = @(
    @{
        Package = 'Oracle.ManagedDataAccess.Core'
        LibPath = 'netstandard2.1\Oracle.ManagedDataAccess.dll'
        DBMS    = 'Oracle'
    }
    @{
        Package = 'MySql.Data'
        LibPath = 'net7.0\MySql.Data.dll'
        DBMS    = 'MySQL'
    }
    @{
        Package = 'Npgsql'
        LibPath = 'net7.0\Npgsql.dll'
        DBMS    = 'PostgreSQL'
    }
    @{
        # Needed for Npgsql:
        Package = 'Microsoft.Extensions.Logging.Abstractions'
        LibPath = 'net7.0\Microsoft.Extensions.Logging.Abstractions.dll'
    }
)
$dllBasePath = '..\_Local'
if (-not (Test-Path -Path $dllBasePath)) {
    $null = New-Item -Path $dllBasePath -ItemType Directory
}
foreach ($dll in $dllDefinition) {
    Push-Location -Path $dllBasePath

    if (-not (Test-Path -Path $dll.Package)) {
        Invoke-WebRequest -Uri "https://www.nuget.org/api/v2/package/$($dll.Package)" -OutFile package.zip -UseBasicParsing
        Expand-Archive -Path package.zip -DestinationPath $dll.Package
        Remove-Item -Path package.zip
    }
    
    $fullLibPath = (Resolve-Path -Path ".\$($dll.Package)\lib\$($dll.LibPath)").Path
    Add-Type -Path $fullLibPath
    if ($dll.DBMS) {
        Set-Item -Path "Env:$($dll.DBMS.ToUpper())_DLL" -Value $fullLibPath
    }

    Pop-Location
}

# Load all wrapper scripts
. ..\SQLServer\Connect-SqlInstance.ps1
. ..\SQLServer\Invoke-SqlQuery.ps1
. ..\Oracle\Connect-OraInstance.ps1
. ..\Oracle\Invoke-OraQuery.ps1
. ..\MySQL\Connect-MyInstance.ps1
. ..\MySQL\Invoke-MyQuery.ps1
. ..\PostgreSQL\Connect-PgInstance.ps1
. ..\PostgreSQL\Invoke-PgQuery.ps1


# SQL Server

$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'SQLServer'
if ($dbDef) {
    $sqlSaCredential = [PSCredential]::new('sa', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
    while ($true) {
        try {
            $sqlSaConnection = Connect-SqlInstance -Instance $dbDef.Instance -Credential $sqlSaCredential -EnableException
            break
        } catch {
            Start-Sleep -Seconds 30
        }
    }
    foreach ($query in $dbDef.SqlQueries) {
        Invoke-SqlQuery -Connection $sqlSaConnection -Query $query
    }
    
    Push-Location -Path ..\SQLServer
    $Env:SQLSERVER_INSTANCE = $dbDef.Instance
    $Env:SQLSERVER_USERNAME = 'StackOverflow'
    $Env:SQLSERVER_PASSWORD = $dbDef.AdminPassword
    $Env:SQLSERVER_DATABASE = 'StackOverflow'
    ./Application.ps1
    Pop-Location
}


# Oracle

$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'Oracle'
if ($dbDef) {
    $oraSysCredential = [PSCredential]::new('sys', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
    while ($true) {
        try {
            $oraSysConnection = Connect-OraInstance -Instance $dbDef.Instance -Credential $oraSysCredential -AsSysdba -EnableException
            break
        } catch {
            Start-Sleep -Seconds 30
        }
    }
    foreach ($query in $dbDef.SqlQueries) {
        Invoke-OraQuery -Connection $oraSysConnection -Query $query
    }

    Push-Location -Path ..\Oracle
    $Env:ORACLE_INSTANCE = $dbDef.Instance
    $Env:ORACLE_USERNAME = 'stackoverflow'
    $Env:ORACLE_PASSWORD = $dbDef.AdminPassword
    ./Application.ps1
    Pop-Location

    $credential = [PSCredential]::new('geodemo', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
    $connection = Connect-OraInstance -Instance $dbDef.Instance -Credential $credential
    Invoke-OraQuery -Connection $connection -Query 'CREATE TABLE countries (name VARCHAR2(50), iso CHAR(3), geometry SDO_GEOMETRY)'
    $geoJSON = Invoke-RestMethod -Method Get -Uri https://datahub.io/core/geo-countries/r/0.geojson
    foreach ($feature in $geoJSON.features) {
        $invokeParams = @{
            Connection      = $connection
            Query           = 'INSERT INTO countries VALUES (:name, :iso, sdo_util.from_geojson(:geometry))'
            ParameterValues = @{
                name     = $feature.properties.ADMIN
                iso      = $feature.properties.ISO_A3
                geometry = ($feature.geometry | ConvertTo-Json -Depth 4 -Compress) -replace '\.(\d{10})\d+', '.$1'
            }
            EnableException = $true
        }
        try {
            Invoke-OraQuery @invokeParams
        } catch {
            Write-Warning -Message "Failed to import $($feature.properties.ADMIN): $_"
        }
    }
}


# MySQL

$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'MySQL'
if ($dbDef) {
    $myRootCredential = [PSCredential]::new('root', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
    while ($true) {
        try {
            $myRootConnection = Connect-MyInstance -Instance $dbDef.Instance -Credential $myRootCredential -EnableException
            break
        } catch {
            Start-Sleep -Seconds 30
        }
    }
    foreach ($query in $dbDef.SqlQueries) {
        Invoke-MyQuery -Connection $myRootConnection -Query $query
    }

    Push-Location -Path ..\MySQL
    $Env:MYSQL_INSTANCE = $dbDef.Instance
    $Env:MYSQL_USERNAME = 'stackoverflow'
    $Env:MYSQL_PASSWORD = $dbDef.AdminPassword
    $Env:MYSQL_DATABASE = 'stackoverflow'
    ./Application.ps1
    Pop-Location
}


# MariaDB
# https://stackoverflow.com/questions/74060289/mysqlconnection-open-system-invalidcastexception-object-cannot-be-cast-from-d

$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'MariaDB'
if ($dbDef) {
    $myRootCredential = [PSCredential]::new('root', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
    while ($true) {
        try {
            $myRootConnection = Connect-MyInstance -Instance $dbDef.Instance -Credential $myRootCredential -EnableException
            break
        } catch {
            Start-Sleep -Seconds 30
        }
    }
    foreach ($query in $dbDef.SqlQueries) {
        Invoke-MyQuery -Connection $myRootConnection -Query $query
    }

    Push-Location -Path ..\MySQL
    $Env:MYSQL_INSTANCE = $dbDef.Instance
    $Env:MYSQL_USERNAME = 'stackoverflow'
    $Env:MYSQL_PASSWORD = $dbDef.AdminPassword
    $Env:MYSQL_DATABASE = 'stackoverflow'
    ./Application.ps1
    Pop-Location
}


# PostgreSQL

$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'PostgreSQL'
if ($dbDef) {
    $pgPostgresCredential = [PSCredential]::new('postgres', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
    while ($true) {
        try {
            $pgPostgresConnection = Connect-PgInstance -Instance $dbDef.Instance -Credential $pgPostgresCredential -EnableException
            break
        } catch {
            Start-Sleep -Seconds 30
        }
    }
    foreach ($query in $dbDef.SqlQueries) {
        if ($query -match '^\\connect (.+)$') {
            $pgPostgresConnection = Connect-PgInstance -Instance $dbDef.Instance -Credential $pgPostgresCredential -Database $Matches[1]
        } else {
            Invoke-PgQuery -Connection $pgPostgresConnection -Query $query
        }
    }

    Push-Location -Path ..\PostgreSQL
    $Env:POSTGRESQL_INSTANCE = $dbDef.Instance
    $Env:POSTGRESQL_USERNAME = 'stackoverflow'
    $Env:POSTGRESQL_PASSWORD = $dbDef.AdminPassword
    $Env:POSTGRESQL_DATABASE = 'stackoverflow'
    ./Application.ps1
    Pop-Location
}


# PostGIS

$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'PostGIS'
if ($dbDef) {
    $pgPostgresCredential = [PSCredential]::new('postgres', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
    while ($true) {
        try {
            $pgPostgresConnection = Connect-PgInstance -Instance $dbDef.Instance -Credential $pgPostgresCredential -EnableException
            break
        } catch {
            Start-Sleep -Seconds 30
        }
    }
    foreach ($query in $dbDef.SqlQueries) {
        if ($query -match '^\\connect (.+)$') {
            $pgPostgresConnection = Connect-PgInstance -Instance $dbDef.Instance -Credential $pgPostgresCredential -Database $Matches[1]
        } else {
            Invoke-PgQuery -Connection $pgPostgresConnection -Query $query
        }
    }

    $credential = [PSCredential]::new('geodemo', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
    $connection = Connect-PgInstance -Instance $dbDef.Instance -Credential $credential -Database geodemo
    Invoke-PgQuery -Connection $connection -Query 'CREATE TABLE countries (name VARCHAR(50), iso CHAR(3), geometry GEOMETRY)' 
    $geoJSON = Invoke-RestMethod -Method Get -Uri https://datahub.io/core/geo-countries/r/0.geojson
    foreach ($feature in $geoJSON.features) {
        $invokeParams = @{
            Connection      = $connection
            Query           = 'INSERT INTO countries VALUES (:name, :iso, ST_GeomFromGeoJSON(:geometry))'
            ParameterValues = @{
                name     = $feature.properties.ADMIN
                iso      = $feature.properties.ISO_A3
                geometry = $feature.geometry | ConvertTo-Json -Depth 4 -Compress 
            }
            EnableException = $true
        }
        try {
            Invoke-PgQuery @invokeParams
        } catch {
            Write-Warning -Message "Failed to import $($feature.properties.ADMIN): $_"
        }
    }
}
