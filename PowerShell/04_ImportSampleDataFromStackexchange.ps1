[CmdletBinding()]
param (
    [String]$DatabaseDefinitionFile = '/tmp/tmp_DatabaseDefinition.json',
    [String]$SampleDataPath = '/tmp/stackexchange',
    [String]$StackexchangeSite = 'dba.meta',
    [switch]$UseExistingData
)

$ErrorActionPreference = 'Stop'

Import-Module -Name PSFramework

$DatabaseDefinition = Get-Content -Path $DatabaseDefinitionFile | ConvertFrom-Json

# Load sample data
if (-not $UseExistingData) {
    try {
        $start = Get-Date
        if (Test-Path -Path $SampleDataPath) {
            Remove-Item -Path $SampleDataPath -Recurse -Force
        }
        $null = New-Item -Path $SampleDataPath -ItemType Directory
        Push-Location -Path $SampleDataPath
        Invoke-WebRequest -Uri https://archive.org/download/stackexchange/$StackexchangeSite.stackexchange.com.7z -OutFile tmp.7z -UseBasicParsing
        $null = 7za e tmp.7z
        Remove-Item -Path tmp.7z
        Pop-Location
        $duration = (Get-Date) - $start
        Write-PSFMessage -Level Host -Message "Dowload sample data finished in $($duration.TotalSeconds) seconds"
    } catch {
        Write-PSFMessage -Level Warning -Message "Dowload sample data failed: $_"
        exit 1
    }
}

$tableNames = 'Badges', 'Comments', 'PostLinks', 'Posts', 'Users', 'Votes'

$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'SQLServer'
if ($dbDef) {
    try {
        $start = Get-Date
        . $PSScriptRoot\..\SQLServer\Connect-SqlInstance.ps1
        . $PSScriptRoot\..\SQLServer\Import-SqlTable.ps1
        $credential = [PSCredential]::new('StackOverflow', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
        $connection = Connect-SqlInstance -Instance $dbDef.Instance -Credential $credential -Database 'StackOverflow' -EnableException
        foreach ($tableName in $tableNames) {
            $columnMap = $null
            if ($tableName -eq 'Badges') {
                $columnMap = @{ CreationDate = 'Date' }
            }
            Import-SqlTable -Path $SampleDataPath/$tableName.xml -Connection $connection -Table $tableName -TruncateTable -ColumnMap $columnMap -EnableException
        }
        $duration = (Get-Date) - $start
        Write-PSFMessage -Level Host -Message "Importing sample data to SQL Server finished in $($duration.TotalSeconds) seconds"
    } catch {
        Write-PSFMessage -Level Warning -Message "Importing sample data to SQL Server failed: $_"
    }
}

$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'Oracle'
if ($dbDef) {
    try {
        $start = Get-Date
        . $PSScriptRoot\..\Oracle\Import-OraLibrary.ps1
        . $PSScriptRoot\..\Oracle\Connect-OraInstance.ps1
        . $PSScriptRoot\..\Oracle\Import-OraTable.ps1
        Import-OraLibrary -EnableException
        $credential = [PSCredential]::new('stackoverflow', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
        $connection = Connect-OraInstance -Instance $dbDef.Instance -Credential $credential -EnableException
        foreach ($tableName in $tableNames) {
            $columnMap = $null
            if ($tableName -eq 'Badges') {
                $columnMap = @{ CreationDate = 'Date' }
            }
            Import-OraTable -Path $SampleDataPath/$tableName.xml -Connection $connection -Table $tableName -TruncateTable -ColumnMap $columnMap -EnableException
        }
        $duration = (Get-Date) - $start
        Write-PSFMessage -Level Host -Message "Importing sample data to Oracle finished in $($duration.TotalSeconds) seconds"
    } catch {
        Write-PSFMessage -Level Warning -Message "Importing sample data to Oracle failed: $_"
    }
}

$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'MySQL'
if ($dbDef) {
    try {
        $start = Get-Date
        . $PSScriptRoot\..\MySQL\Import-MyLibrary.ps1
        . $PSScriptRoot\..\MySQL\Connect-MyInstance.ps1
        . $PSScriptRoot\..\MySQL\Import-MyTable.ps1
        Import-MyLibrary -EnableException
        $credential = [PSCredential]::new('stackoverflow', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
        $connection = Connect-MyInstance -Instance $dbDef.Instance -Credential $credential -Database 'stackoverflow' -AllowLoadLocalInfile -EnableException
        foreach ($tableName in $tableNames) {
            $columnMap = $null
            if ($tableName -eq 'Badges') {
                $columnMap = @{ CreationDate = 'Date' }
            }
            Import-MyTable -Path $SampleDataPath/$tableName.xml -Connection $connection -Table $tableName -TruncateTable -ColumnMap $columnMap -EnableException
        }
        $duration = (Get-Date) - $start
        Write-PSFMessage -Level Host -Message "Importing sample data to MySQL finished in $($duration.TotalSeconds) seconds"
    } catch {
        Write-PSFMessage -Level Warning -Message "Importing sample data to MySQL failed: $_"
    }
}

$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'MariaDB'
if ($dbDef) {
    try {
        $start = Get-Date
        . $PSScriptRoot\..\MySQL\Import-MyLibrary.ps1
        . $PSScriptRoot\..\MySQL\Connect-MyInstance.ps1
        . $PSScriptRoot\..\MySQL\Import-MyTable.ps1
        Import-MyLibrary -EnableException
        $credential = [PSCredential]::new('stackoverflow', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
        $connection = Connect-MyInstance -Instance $dbDef.Instance -Credential $credential -Database 'stackoverflow' -AllowLoadLocalInfile -EnableException
        foreach ($tableName in $tableNames) {
            $columnMap = $null
            if ($tableName -eq 'Badges') {
                $columnMap = @{ CreationDate = 'Date' }
            }
            Import-MyTable -Path $SampleDataPath/$tableName.xml -Connection $connection -Table $tableName -TruncateTable -ColumnMap $columnMap -EnableException
        }
        $duration = (Get-Date) - $start
        Write-PSFMessage -Level Host -Message "Importing sample data to MariaDB finished in $($duration.TotalSeconds) seconds"
    } catch {
        Write-PSFMessage -Level Warning -Message "Importing sample data to MariaDB failed: $_"
    }
}

$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'PostgreSQL'
if ($dbDef) {
    try {
        $start = Get-Date
        . $PSScriptRoot\..\PostgreSQL\Import-PgLibrary.ps1
        . $PSScriptRoot\..\PostgreSQL\Connect-PgInstance.ps1
        . $PSScriptRoot\..\PostgreSQL\Import-PgTable.ps1
        Import-PgLibrary -EnableException
        $credential = [PSCredential]::new('stackoverflow', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
        $connection = Connect-PgInstance -Instance $dbDef.Instance -Credential $credential -Database 'stackoverflow' -EnableException
        foreach ($tableName in $tableNames) {
            $columnMap = $null
            if ($tableName -eq 'Badges') {
                $columnMap = @{ CreationDate = 'Date' }
            }
            Import-PgTable -Path $SampleDataPath/$tableName.xml -Connection $connection -Table $tableName -TruncateTable -ColumnMap $columnMap -EnableException
        }
        $duration = (Get-Date) - $start
        Write-PSFMessage -Level Host -Message "Importing sample data to PostgreSQL finished in $($duration.TotalSeconds) seconds"
    } catch {
        Write-PSFMessage -Level Warning -Message "Importing sample data to PostgreSQL failed: $_"
    }
}
