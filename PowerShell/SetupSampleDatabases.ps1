[CmdletBinding()]
param (
    [String]$DatabaseDefinitionFile = '/tmp/tmp_DatabaseDefinition.json'
)

$ErrorActionPreference = 'Stop'

Import-Module -Name PSFramework

$DatabaseDefinition = Get-Content -Path $DatabaseDefinitionFile | ConvertFrom-Json

$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'SQLServer'
if ($dbDef) {
    . $PSScriptRoot\..\SQLServer\Connect-SqlInstance.ps1
    . $PSScriptRoot\..\SQLServer\Invoke-SqlQuery.ps1
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
        Invoke-SqlQuery -Connection $sqlSaConnection -Query $query -EnableException
    }
}

$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'Oracle'
if ($dbDef) {
    . $PSScriptRoot\..\Oracle\Import-OraLibrary.ps1
    . $PSScriptRoot\..\Oracle\Connect-OraInstance.ps1
    . $PSScriptRoot\..\Oracle\Invoke-OraQuery.ps1
    Import-OraLibrary -EnableException
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
        Invoke-OraQuery -Connection $oraSysConnection -Query $query -EnableException
    }
}

$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'MySQL'
if ($dbDef) {
    . $PSScriptRoot\..\MySQL\Import-MyLibrary.ps1
    . $PSScriptRoot\..\MySQL\Connect-MyInstance.ps1
    . $PSScriptRoot\..\MySQL\Invoke-MyQuery.ps1
    Import-MyLibrary -EnableException
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
        Invoke-MyQuery -Connection $myRootConnection -Query $query -EnableException
    }
}

$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'MariaDB'
if ($dbDef) {
    . $PSScriptRoot\..\MySQL\Import-MyLibrary.ps1
    . $PSScriptRoot\..\MySQL\Connect-MyInstance.ps1
    . $PSScriptRoot\..\MySQL\Invoke-MyQuery.ps1
    Import-MyLibrary -EnableException
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
        Invoke-MyQuery -Connection $myRootConnection -Query $query -EnableException
    }
}

$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'PostgreSQL'
if ($dbDef) {
    . $PSScriptRoot\..\PostgreSQL\Import-PgLibrary.ps1
    . $PSScriptRoot\..\PostgreSQL\Connect-PgInstance.ps1
    . $PSScriptRoot\..\PostgreSQL\Invoke-PgQuery.ps1
    Import-PgLibrary -EnableException
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
            Invoke-PgQuery -Connection $pgPostgresConnection -Query $query -EnableException
        }
    }
}


$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'PostGIS'
if ($dbDef) {
    . $PSScriptRoot\..\PostgreSQL\Import-PgLibrary.ps1
    . $PSScriptRoot\..\PostgreSQL\Connect-PgInstance.ps1
    . $PSScriptRoot\..\PostgreSQL\Invoke-PgQuery.ps1
    Import-PgLibrary -EnableException
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
            Invoke-PgQuery -Connection $pgPostgresConnection -Query $query -EnableException
        }
    }
}
