[CmdletBinding()]
param (
    [String]$DatabaseDefinitionFile = '/tmp/tmp_DatabaseDefinition.json'
)

# Add more sample data from the internet, work in progress.

$ErrorActionPreference = 'Stop'

Import-Module -Name PSFramework

$DatabaseDefinition = Get-Content -Path $DatabaseDefinitionFile | ConvertFrom-Json

# Load all wrapper scripts
. $PSScriptRoot\..\SQLServer\Connect-SqlInstance.ps1
. $PSScriptRoot\..\SQLServer\Import-SqlTable.ps1
. $PSScriptRoot\..\Oracle\Import-OraLibrary.ps1
. $PSScriptRoot\..\Oracle\Connect-OraInstance.ps1
. $PSScriptRoot\..\Oracle\Import-OraTable.ps1
. $PSScriptRoot\..\MySQL\Import-MyLibrary.ps1
. $PSScriptRoot\..\MySQL\Connect-MyInstance.ps1
. $PSScriptRoot\..\MySQL\Import-MyTable.ps1
. $PSScriptRoot\..\PostgreSQL\Import-PgLibrary.ps1
. $PSScriptRoot\..\PostgreSQL\Connect-PgInstance.ps1
. $PSScriptRoot\..\PostgreSQL\Import-PgTable.ps1

# Load sample data
$dataPath = '/tmp/stackexchange'
try {
    $start = Get-Date
    if (Test-Path -Path $dataPath) {
        Remove-Item -Path $dataPath -Recurse -Force
    }
    $null = New-Item -Path $dataPath -ItemType Directory
    Push-Location -Path $dataPath
    #Invoke-WebRequest -Uri https://archive.org/download/stackexchange/dba.stackexchange.com.7z -OutFile tmp.7z -UseBasicParsing
    Invoke-WebRequest -Uri https://archive.org/download/stackexchange/dba.meta.stackexchange.com.7z -OutFile tmp.7z -UseBasicParsing
    $null = 7za e tmp.7z
    Remove-Item -Path tmp.7z
    Pop-Location
    Write-Host "Dowload sample data finished in $($duration.TotalSeconds) seconds"
} catch {
    Write-Host "Dowload sample data failed: $_"
    return
}


$tables = 'Badges', 'Comments', 'PostLinks', 'Posts', 'Users', 'Votes'

$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'SQLServer'
if ($dbDef) {
    try {
        $start = Get-Date
        $credential = [PSCredential]::new('StackOverflow', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
        $connection = Connect-SqlInstance -Instance $dbDef.Instance -Credential $credential -Database 'StackOverflow' -EnableException
        foreach ($table in $tables) {
            $columnMap = $null
            if ($table -eq 'Badges') {
                $columnMap = @{ CreationDate = 'Date' }
            }
            Import-SqlTable -Path $dataPath/$table.xml -Connection $connection -Table $table -TruncateTable -ColumnMap $columnMap -EnableException
        }
        $duration = (Get-Date) - $start
        Write-Host "Sample data import to SQL Server finished in $($duration.TotalSeconds) seconds"
    } catch {
        Write-Host "Sample data import to SQL Server failed: $_"
    }
}


$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'Oracle'
if ($dbDef) {
    try {
        $start = Get-Date
        $credential = [PSCredential]::new('stackoverflow', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
        Import-OraLibrary -EnableException
        $connection = Connect-OraInstance -Instance $dbDef.Instance -Credential $credential -EnableException
        foreach ($table in $tables) {
            $columnMap = $null
            if ($table -eq 'Badges') {
                $columnMap = @{ CreationDate = 'Date' }
            }
            Import-OraTable -Path $dataPath/$table.xml -Connection $connection -Table $table -TruncateTable -ColumnMap $columnMap -EnableException
        }
        $duration = (Get-Date) - $start
        Write-Host "Sample data import to Oracle finished in $($duration.TotalSeconds) seconds"
    } catch {
        Write-Host "Sample data import to Oracle failed: $_"
    }
}


$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'MySQL'
if ($dbDef) {
    try {
        $start = Get-Date
        $credential = [PSCredential]::new('stackoverflow', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
        Import-MyLibrary -EnableException
        $connection = Connect-MyInstance -Instance $dbDef.Instance -Credential $credential -Database 'stackoverflow' -EnableException
        foreach ($table in $tables) {
            $columnMap = $null
            if ($table -eq 'Badges') {
                $columnMap = @{ CreationDate = 'Date' }
            }
            Import-MyTable -Path $dataPath/$table.xml -Connection $connection -Table $table -TruncateTable -ColumnMap $columnMap -EnableException
        }
        $duration = (Get-Date) - $start
        Write-Host "Sample data import to MySQL finished in $($duration.TotalSeconds) seconds"
    } catch {
        Write-Host "Sample data import to MySQL failed: $_"
    }
}


$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'MariaDB'
if ($dbDef) {
    try {
        $start = Get-Date
        $credential = [PSCredential]::new('stackoverflow', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
        Import-MyLibrary -EnableException
        $connection = Connect-MyInstance -Instance $dbDef.Instance -Credential $credential -Database 'stackoverflow' -EnableException
        foreach ($table in $tables) {
            $columnMap = $null
            if ($table -eq 'Badges') {
                $columnMap = @{ CreationDate = 'Date' }
            }
            Import-MyTable -Path $dataPath/$table.xml -Connection $connection -Table $table -TruncateTable -ColumnMap $columnMap -EnableException
        }
        $duration = (Get-Date) - $start
        Write-Host "Sample data import to MariaDB finished in $($duration.TotalSeconds) seconds"
    } catch {
        Write-Host "Sample data import to MariaDB failed: $_"
    }
}


$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'PostgreSQL'
if ($dbDef) {
    try {
        $start = Get-Date
        $credential = [PSCredential]::new('stackoverflow', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
        Import-PgLibrary -EnableException
        $connection = Connect-PgInstance -Instance $dbDef.Instance -Credential $credential -Database 'stackoverflow' -EnableException
        foreach ($table in $tables) {
            $columnMap = $null
            if ($table -eq 'Badges') {
                $columnMap = @{ CreationDate = 'Date' }
            }
            Import-PgTable -Path $dataPath/$table.xml -Connection $connection -Table $table -TruncateTable -ColumnMap $columnMap -EnableException
        }
        $duration = (Get-Date) - $start
        Write-Host "Sample data import to PostgreSQL finished in $($duration.TotalSeconds) seconds"
    } catch {
        Write-Host "Sample data import to PostgreSQL failed: $_"
    }
}

