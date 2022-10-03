param(
    [int]$MaxRowsPerTable
)
$ErrorActionPreference = 'Stop'

. ..\PowerShell\Environment.ps1
. ..\PowerShell\Import-Schema.ps1
. ..\PowerShell\Import-Data.ps1

if (-not $Env:POSTGRESQL_DLL) {
    throw 'Environment variable POSTGRESQL_DLL not set'
}
if (-not (Test-Path -Path $Env:POSTGRESQL_DLL)) {
    throw "Environment variable POSTGRESQL_DLL not set correctly, file [$Env:POSTGRESQL_DLL] not found"
}
Add-Type -Path $Env:POSTGRESQL_DLL
if ($Env:POSTGRESQL_DLL -match 'Devart') {
    . .\Connect-PgInstance_Devart.ps1
    . .\Invoke-PgQuery_Devart.ps1
} else {
    . .\Connect-PgInstance.ps1
    . .\Invoke-PgQuery.ps1
}

$instance = $EnvironmentServerComputerName
$database = 'stackoverflow'

try {
    # $credential = Get-Credential -Message $instance -UserName $EnvironmentDatabaseUserName
    $credential = [PSCredential]::new($EnvironmentDatabaseUserName, (ConvertTo-SecureString -String $EnvironmentDatabaseUserPassword -AsPlainText -Force))
    $connection = Connect-PgInstance -Instance $instance -Credential $credential -Database $database

    #$tables = Invoke-PgQuery -Connection $connection -Query "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'" -As SingleValue
    #foreach ($table in $tables) {
    #    Invoke-PgQuery -Connection $connection -Query ("DROP TABLE $table")
    #}

    Import-Schema -Path ..\PowerShell\SampleSchema.psd1 -DBMS PostgreSQL -Connection $connection -EnableException
    $start = Get-Date
    Import-Data -Path ..\PowerShell\SampleData.json -DBMS PostgreSQL -Connection $connection -MaxRowsPerTable $MaxRowsPerTable -EnableException
    $duration = (Get-Date) - $start

    $connection.Dispose()

    Write-Host "Data import to $EnvironmentServerComputerName finished in $($duration.TotalSeconds) seconds"
} catch {
    Write-Host "Data import to $EnvironmentServerComputerName failed: $_"
}
