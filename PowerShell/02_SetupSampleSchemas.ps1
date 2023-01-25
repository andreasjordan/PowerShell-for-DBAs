[CmdletBinding()]
param (
    [String]$DatabaseDefinitionFile = '/tmp/tmp_DatabaseDefinition.json'
)

$ErrorActionPreference = 'Stop'

Import-Module -Name PSFramework
. $PSScriptRoot\Import-Schema.ps1

$DatabaseDefinition = Get-Content -Path $DatabaseDefinitionFile | ConvertFrom-Json

$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'SQLServer'
if ($dbDef) {
    try {
        . $PSScriptRoot\..\SQLServer\Connect-SqlInstance.ps1
        . $PSScriptRoot\..\SQLServer\Invoke-SqlQuery.ps1
        $credential = [PSCredential]::new('StackOverflow', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
        $connection = Connect-SqlInstance -Instance $dbDef.Instance -Credential $credential -Database 'StackOverflow' -EnableException
        Import-Schema -Path $PSScriptRoot\SampleSchema.psd1 -DBMS SQLServer -Connection $connection -EnableException
        Write-PSFMessage -Level Host -Message "Creating sample schema on SQL Server finished"
    } catch {
        Write-PSFMessage -Level Warning -Message "Creating sample schema on SQL Server failed: $_"
    }
}

$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'Oracle'
if ($dbDef) {
    try {
        . $PSScriptRoot\..\Oracle\Import-OraLibrary.ps1
        . $PSScriptRoot\..\Oracle\Connect-OraInstance.ps1
        . $PSScriptRoot\..\Oracle\Invoke-OraQuery.ps1
        Import-OraLibrary -EnableException
        $credential = [PSCredential]::new('stackoverflow', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
        $connection = Connect-OraInstance -Instance $dbDef.Instance -Credential $credential -EnableException
        Import-Schema -Path $PSScriptRoot\SampleSchema.psd1 -DBMS Oracle -Connection $connection -EnableException
        $credential = [PSCredential]::new('geodemo', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
        $connection = Connect-OraInstance -Instance $dbDef.Instance -Credential $credential -EnableException
        Invoke-OraQuery -Connection $connection -Query 'CREATE TABLE countries (name VARCHAR2(50), iso CHAR(3), geometry SDO_GEOMETRY)'
        Write-PSFMessage -Level Host -Message "Creating sample schema on Oracle finished"
    } catch {
        Write-PSFMessage -Level Warning -Message "Creating sample schema on Oracle failed: $_"
    }
}

$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'MySQL'
if ($dbDef) {
    try {
        . $PSScriptRoot\..\MySQL\Import-MyLibrary.ps1
        . $PSScriptRoot\..\MySQL\Connect-MyInstance.ps1
        . $PSScriptRoot\..\MySQL\Invoke-MyQuery.ps1
        Import-MyLibrary -EnableException
        $credential = [PSCredential]::new('stackoverflow', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
        $connection = Connect-MyInstance -Instance $dbDef.Instance -Credential $credential -Database 'stackoverflow' -AllowLoadLocalInfile -EnableException
        Import-Schema -Path $PSScriptRoot\SampleSchema.psd1 -DBMS MySQL -Connection $connection -EnableException
        Write-PSFMessage -Level Host -Message "Creating sample schema on MySQL finished"
    } catch {
        Write-PSFMessage -Level Warning -Message "Creating sample schema on MySQL failed: $_"
    }
}

$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'MariaDB'
if ($dbDef) {
    try {
        . $PSScriptRoot\..\MySQL\Import-MyLibrary.ps1
        . $PSScriptRoot\..\MySQL\Connect-MyInstance.ps1
        . $PSScriptRoot\..\MySQL\Invoke-MyQuery.ps1
        Import-MyLibrary -EnableException
        $credential = [PSCredential]::new('stackoverflow', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
        $connection = Connect-MyInstance -Instance $dbDef.Instance -Credential $credential -Database 'stackoverflow' -AllowLoadLocalInfile -EnableException
        Import-Schema -Path $PSScriptRoot\SampleSchema.psd1 -DBMS MySQL -Connection $connection -EnableException
        Write-PSFMessage -Level Host -Message "Creating sample schema on MariaDB finished"
    } catch {
        Write-PSFMessage -Level Warning -Message "Creating sample schema on MariaDB failed: $_"
    }
}

$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'PostgreSQL'
if ($dbDef) {
    try {
        . $PSScriptRoot\..\PostgreSQL\Import-PgLibrary.ps1
        . $PSScriptRoot\..\PostgreSQL\Connect-PgInstance.ps1
        . $PSScriptRoot\..\PostgreSQL\Invoke-PgQuery.ps1
        Import-PgLibrary -EnableException
        $credential = [PSCredential]::new('stackoverflow', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
        $connection = Connect-PgInstance -Instance $dbDef.Instance -Credential $credential -Database 'stackoverflow' -EnableException
        Import-Schema -Path $PSScriptRoot\SampleSchema.psd1 -DBMS PostgreSQL -Connection $connection -EnableException
        Write-PSFMessage -Level Host -Message "Creating sample schema on PostgreSQL finished"
    } catch {
        Write-PSFMessage -Level Warning -Message "Creating sample schema on PostgreSQL failed: $_"
    }
}

$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'PostGIS'
if ($dbDef) {
    try {
        . $PSScriptRoot\..\PostgreSQL\Import-PgLibrary.ps1
        . $PSScriptRoot\..\PostgreSQL\Connect-PgInstance.ps1
        . $PSScriptRoot\..\PostgreSQL\Invoke-PgQuery.ps1
        Import-PgLibrary -EnableException
        $credential = [PSCredential]::new('geodemo', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
        $connection = Connect-PgInstance -Instance $dbDef.Instance -Credential $credential -Database geodemo
        Invoke-PgQuery -Connection $connection -Query 'CREATE TABLE countries (name VARCHAR(50), iso CHAR(3), geometry GEOMETRY)' 
        Write-PSFMessage -Level Host -Message "Creating sample schema on PostGIS finished"
    } catch {
        Write-PSFMessage -Level Warning -Message "Creating sample schema on PostGIS failed: $_"
    }
}
