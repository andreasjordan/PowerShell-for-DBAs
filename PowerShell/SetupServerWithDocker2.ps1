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

# Load all wrapper scripts
. $PSScriptRoot\..\SQLServer\Connect-SqlInstance.ps1
. $PSScriptRoot\..\SQLServer\Invoke-SqlQuery.ps1
. $PSScriptRoot\..\Oracle\Import-OraLibrary.ps1
. $PSScriptRoot\..\Oracle\Connect-OraInstance.ps1
. $PSScriptRoot\..\Oracle\Invoke-OraQuery.ps1
. $PSScriptRoot\..\MySQL\Import-MyLibrary.ps1
. $PSScriptRoot\..\MySQL\Connect-MyInstance.ps1
. $PSScriptRoot\..\MySQL\Invoke-MyQuery.ps1
. $PSScriptRoot\..\PostgreSQL\Import-PgLibrary.ps1
. $PSScriptRoot\..\PostgreSQL\Connect-PgInstance.ps1
. $PSScriptRoot\..\PostgreSQL\Invoke-PgQuery.ps1


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
    
    $Env:SQLSERVER_INSTANCE = $dbDef.Instance
    $Env:SQLSERVER_USERNAME = 'StackOverflow'
    $Env:SQLSERVER_PASSWORD = $dbDef.AdminPassword
    $Env:SQLSERVER_DATABASE = 'StackOverflow'
    Push-Location -Path $PSScriptRoot\..\SQLServer
    .\Application.ps1
    Pop-Location
}


# Oracle

$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'Oracle'
if ($dbDef) {
    $oraSysCredential = [PSCredential]::new('sys', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
    while ($true) {
        try {
            Import-OraLibrary -EnableException
            $oraSysConnection = Connect-OraInstance -Instance $dbDef.Instance -Credential $oraSysCredential -AsSysdba -EnableException
            break
        } catch {
            Start-Sleep -Seconds 30
        }
    }
    foreach ($query in $dbDef.SqlQueries) {
        Invoke-OraQuery -Connection $oraSysConnection -Query $query
    }

    $Env:ORACLE_INSTANCE = $dbDef.Instance
    $Env:ORACLE_USERNAME = 'stackoverflow'
    $Env:ORACLE_PASSWORD = $dbDef.AdminPassword
    Push-Location -Path $PSScriptRoot\..\Oracle
    .\Application.ps1
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
            Import-MyLibrary -EnableException
            $myRootConnection = Connect-MyInstance -Instance $dbDef.Instance -Credential $myRootCredential -EnableException
            break
        } catch {
            Start-Sleep -Seconds 30
        }
    }
    foreach ($query in $dbDef.SqlQueries) {
        Invoke-MyQuery -Connection $myRootConnection -Query $query
    }

    $Env:MYSQL_INSTANCE = $dbDef.Instance
    $Env:MYSQL_USERNAME = 'stackoverflow'
    $Env:MYSQL_PASSWORD = $dbDef.AdminPassword
    $Env:MYSQL_DATABASE = 'stackoverflow'
    Push-Location -Path $PSScriptRoot\..\MySQL
    .\Application.ps1
    Pop-Location
}


# MariaDB
# https://stackoverflow.com/questions/74060289/mysqlconnection-open-system-invalidcastexception-object-cannot-be-cast-from-d

$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'MariaDB'
if ($dbDef) {
    $myRootCredential = [PSCredential]::new('root', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
    while ($true) {
        try {
            Import-MyLibrary -EnableException
            $myRootConnection = Connect-MyInstance -Instance $dbDef.Instance -Credential $myRootCredential -EnableException
            break
        } catch {
            Start-Sleep -Seconds 30
        }
    }
    foreach ($query in $dbDef.SqlQueries) {
        Invoke-MyQuery -Connection $myRootConnection -Query $query
    }

    $Env:MYSQL_INSTANCE = $dbDef.Instance
    $Env:MYSQL_USERNAME = 'stackoverflow'
    $Env:MYSQL_PASSWORD = $dbDef.AdminPassword
    $Env:MYSQL_DATABASE = 'stackoverflow'
    Push-Location -Path $PSScriptRoot\..\MySQL
    .\Application.ps1
    Pop-Location
}


# PostgreSQL

$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'PostgreSQL'
if ($dbDef) {
    $pgPostgresCredential = [PSCredential]::new('postgres', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
    while ($true) {
        try {
            Import-PgLibrary -EnableException
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

    $Env:POSTGRESQL_INSTANCE = $dbDef.Instance
    $Env:POSTGRESQL_USERNAME = 'stackoverflow'
    $Env:POSTGRESQL_PASSWORD = $dbDef.AdminPassword
    $Env:POSTGRESQL_DATABASE = 'stackoverflow'
    Push-Location -Path $PSScriptRoot\..\PostgreSQL
    .\Application.ps1
    Pop-Location
}


# PostGIS

$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'PostGIS'
if ($dbDef) {
    $pgPostgresCredential = [PSCredential]::new('postgres', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
    while ($true) {
        try {
            Import-PgLibrary -EnableException
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
