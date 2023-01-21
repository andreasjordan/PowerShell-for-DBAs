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

Import-Module -Name PSFramework

$DatabaseDefinition = Get-Content -Path $DatabaseDefinitionFile | ConvertFrom-Json

# Load all wrapper scripts
. $PSScriptRoot\..\SQLServer\Connect-SqlInstance.ps1
. $PSScriptRoot\..\SQLServer\Invoke-SqlQuery.ps1
. $PSScriptRoot\..\SQLServer\Write-SqlTable.ps1
. $PSScriptRoot\..\Oracle\Import-OraLibrary.ps1
. $PSScriptRoot\..\Oracle\Connect-OraInstance.ps1
. $PSScriptRoot\..\Oracle\Invoke-OraQuery.ps1
. $PSScriptRoot\..\Oracle\Write-OraTable.ps1
. $PSScriptRoot\..\MySQL\Import-MyLibrary.ps1
. $PSScriptRoot\..\MySQL\Connect-MyInstance.ps1
. $PSScriptRoot\..\MySQL\Invoke-MyQuery.ps1
. $PSScriptRoot\..\MySQL\Write-MyTable.ps1
. $PSScriptRoot\..\PostgreSQL\Import-PgLibrary.ps1
. $PSScriptRoot\..\PostgreSQL\Connect-PgInstance.ps1
. $PSScriptRoot\..\PostgreSQL\Invoke-PgQuery.ps1
. $PSScriptRoot\..\PostgreSQL\Write-PgTable.ps1
. $PSScriptRoot\Import-Schema.ps1
. $PSScriptRoot\Import-Data.ps1

# Load geographic data
$geoJSON = Invoke-RestMethod -Method Get -Uri https://datahub.io/core/geo-countries/r/0.geojson


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

    try {
        $start = Get-Date
        $credential = [PSCredential]::new('StackOverflow', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
        $connection = Connect-SqlInstance -Instance $dbDef.Instance -Credential $credential -Database 'StackOverflow' -EnableException
        Import-Schema -Path $PSScriptRoot\SampleSchema.psd1 -DBMS SQLServer -Connection $connection -EnableException
        Import-Data -Path $PSScriptRoot\SampleData.json -DBMS SQLServer -Connection $connection -EnableException
        $duration = (Get-Date) - $start
        Write-Host "Sample data import to SQL Server finished in $($duration.TotalSeconds) seconds"
    } catch {
        Write-Host "Sample data import to SQL Server failed: $_"
    }
}


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

    try {
        $start = Get-Date
        $credential = [PSCredential]::new('stackoverflow', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
        $connection = Connect-OraInstance -Instance $dbDef.Instance -Credential $credential -EnableException
        Import-Schema -Path $PSScriptRoot\SampleSchema.psd1 -DBMS Oracle -Connection $connection -EnableException
        Import-Data -Path $PSScriptRoot\SampleData.json -DBMS Oracle -Connection $connection -EnableException
        $duration = (Get-Date) - $start
        Write-Host "Sample data import to Oracle finished in $($duration.TotalSeconds) seconds"
    } catch {
        Write-Host "Sample data import to Oracle failed: $_"
    }

    try {
        $start = Get-Date
        $credential = [PSCredential]::new('geodemo', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
        $connection = Connect-OraInstance -Instance $dbDef.Instance -Credential $credential -EnableException
        Invoke-OraQuery -Connection $connection -Query 'CREATE TABLE countries (name VARCHAR2(50), iso CHAR(3), geometry SDO_GEOMETRY)'
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
        $duration = (Get-Date) - $start
        Write-Host "Geographic data import to Oracle finished in $($duration.TotalSeconds) seconds"
    } catch {
        Write-Host "Geographic data import to Oracle failed: $_"
    }
}


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

    try {
        $start = Get-Date
        $credential = [PSCredential]::new('stackoverflow', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
        $connection = Connect-MyInstance -Instance $dbDef.Instance -Credential $credential -Database 'stackoverflow' -AllowLoadLocalInfile -EnableException
        Import-Schema -Path $PSScriptRoot\SampleSchema.psd1 -DBMS MySQL -Connection $connection -EnableException
        Import-Data -Path $PSScriptRoot\SampleData.json -DBMS MySQL -Connection $connection -EnableException
        $duration = (Get-Date) - $start
        Write-Host "Sample data import to MySQL finished in $($duration.TotalSeconds) seconds"
    } catch {
        Write-Host "Sample data import to MySQL failed: $_"
    }
}


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

    try {
        $start = Get-Date
        $credential = [PSCredential]::new('stackoverflow', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
        $connection = Connect-MyInstance -Instance $dbDef.Instance -Credential $credential -Database 'stackoverflow' -EnableException
        Import-Schema -Path $PSScriptRoot\SampleSchema.psd1 -DBMS MySQL -Connection $connection -EnableException
        Import-Data -Path $PSScriptRoot\SampleData.json -DBMS MySQL -Connection $connection -EnableException
        $duration = (Get-Date) - $start
        Write-Host "Sample data import to MariaDB finished in $($duration.TotalSeconds) seconds"
    } catch {
        Write-Host "Sample data import to MariaDB failed: $_"
    }
}


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

    try {
        $start = Get-Date
        $credential = [PSCredential]::new('stackoverflow', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
        $connection = Connect-PgInstance -Instance $dbDef.Instance -Credential $credential -Database 'stackoverflow' -EnableException
        Import-Schema -Path $PSScriptRoot\SampleSchema.psd1 -DBMS PostgreSQL -Connection $connection -EnableException
        Import-Data -Path $PSScriptRoot\SampleData.json -DBMS PostgreSQL -Connection $connection -EnableException
        $duration = (Get-Date) - $start
        Write-Host "Sample data import to PostgreSQL finished in $($duration.TotalSeconds) seconds"
    } catch {
        Write-Host "Sample data import to PostgreSQL failed: $_"
    }
}


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

    try {
        $start = Get-Date
        $credential = [PSCredential]::new('geodemo', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
        $connection = Connect-PgInstance -Instance $dbDef.Instance -Credential $credential -Database geodemo
        Invoke-PgQuery -Connection $connection -Query 'CREATE TABLE countries (name VARCHAR(50), iso CHAR(3), geometry GEOMETRY)' 
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
        $duration = (Get-Date) - $start
        Write-Host "Geographic data import to PostGIS finished in $($duration.TotalSeconds) seconds"
    } catch {
        Write-Host "Geographic data import to PostGIS failed: $_"
    }
}
