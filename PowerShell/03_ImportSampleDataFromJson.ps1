[CmdletBinding()]
param (
    [String]$DatabaseDefinitionFile = '/tmp/tmp_DatabaseDefinition.json'
)

$ErrorActionPreference = 'Stop'

Import-Module -Name PSFramework

$DatabaseDefinition = Get-Content -Path $DatabaseDefinitionFile | ConvertFrom-Json

$data = Get-Content -Path $PSScriptRoot\SampleData.json -Encoding UTF8 | ConvertFrom-Json
$tableNames = $data.PSObject.Properties.Name | Sort-Object

$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'SQLServer'
if ($dbDef) {
    try {
        $start = Get-Date
        . $PSScriptRoot\..\SQLServer\Connect-SqlInstance.ps1
        . $PSScriptRoot\..\SQLServer\Write-SqlTable.ps1
        $credential = [PSCredential]::new('StackOverflow', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
        $connection = Connect-SqlInstance -Instance $dbDef.Instance -Credential $credential -Database 'StackOverflow' -EnableException
        foreach ($tableName in $tableNames) {
            Write-SqlTable -Connection $connection -Table $tableName -Data $data.$tableName -EnableException
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
        . $PSScriptRoot\..\Oracle\Write-OraTable.ps1
        Import-OraLibrary -EnableException
        $credential = [PSCredential]::new('stackoverflow', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
        $connection = Connect-OraInstance -Instance $dbDef.Instance -Credential $credential -EnableException
        foreach ($tableName in $tableNames) {
            Write-OraTable -Connection $connection -Table $tableName -Data $data.$tableName -EnableException
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
        . $PSScriptRoot\..\MySQL\Write-MyTable.ps1
        Import-MyLibrary -EnableException
        $credential = [PSCredential]::new('stackoverflow', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
        $connection = Connect-MyInstance -Instance $dbDef.Instance -Credential $credential -Database 'stackoverflow' -AllowLoadLocalInfile -EnableException
        foreach ($tableName in $tableNames) {
            Write-MyTable -Connection $connection -Table $tableName -Data $data.$tableName -EnableException
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
        . $PSScriptRoot\..\MySQL\Write-MyTable.ps1
        Import-MyLibrary -EnableException
        $credential = [PSCredential]::new('stackoverflow', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
        $connection = Connect-MyInstance -Instance $dbDef.Instance -Credential $credential -Database 'stackoverflow' -AllowLoadLocalInfile -EnableException
        foreach ($tableName in $tableNames) {
            Write-MyTable -Connection $connection -Table $tableName -Data $data.$tableName -EnableException
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
        . $PSScriptRoot\..\PostgreSQL\Write-PgTable.ps1
        Import-PgLibrary -EnableException
        $credential = [PSCredential]::new('stackoverflow', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
        $connection = Connect-PgInstance -Instance $dbDef.Instance -Credential $credential -Database 'stackoverflow' -EnableException
        foreach ($tableName in $tableNames) {
            Write-PgTable -Connection $connection -Table $tableName -Data $data.$tableName -EnableException
        }        
        $duration = (Get-Date) - $start
        Write-PSFMessage -Level Host -Message "Importing sample data to PostgreSQL finished in $($duration.TotalSeconds) seconds"
    } catch {
        Write-PSFMessage -Level Warning -Message "Importing sample data to PostgreSQL failed: $_"
    }
}
