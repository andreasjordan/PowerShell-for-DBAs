param(
    [int]$MaxRowsPerTable
)
$ErrorActionPreference = 'Stop'

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
if (-not $Env:POSTGRESQL_INSTANCE) {
    throw 'Environment variable POSTGRESQL_INSTANCE not set'
}
if (-not $Env:POSTGRESQL_DATABASE) {
    throw 'Environment variable POSTGRESQL_DATABASE not set'
}
if (-not $Env:POSTGRESQL_USERNAME) {
    throw 'Environment variable POSTGRESQL_USERNAME not set'
}
if (-not $Env:POSTGRESQL_PASSWORD) {
    $credential = Get-Credential -Message $Env:POSTGRESQL_INSTANCE -UserName $Env:POSTGRESQL_USERNAME
} else {
    $credential = [PSCredential]::new($Env:POSTGRESQL_USERNAME, (ConvertTo-SecureString -String $Env:POSTGRESQL_PASSWORD -AsPlainText -Force))
}

. ..\PowerShell\Import-Schema.ps1
. ..\PowerShell\Import-Data.ps1

try {
    $connection = Connect-PgInstance -Instance $Env:POSTGRESQL_INSTANCE -Credential $credential -Database $Env:POSTGRESQL_DATABASE -EnableException

    $tables = Invoke-PgQuery -Connection $connection -Query "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_SCHEMA = 'public'" -As SingleValue -EnableException
    foreach ($table in $tables) {
        Invoke-PgQuery -Connection $connection -Query ("DROP TABLE $table") -EnableException
    }

    Import-Schema -Path ..\PowerShell\SampleSchema.psd1 -DBMS PostgreSQL -Connection $connection -EnableException
    $start = Get-Date
    Import-Data -Path ..\PowerShell\SampleData.json -DBMS PostgreSQL -Connection $connection -MaxRowsPerTable $MaxRowsPerTable -EnableException
    $duration = (Get-Date) - $start

    $connection.Dispose()

    Write-Host "Data import to $Env:POSTGRESQL_INSTANCE finished in $($duration.TotalSeconds) seconds"
} catch {
    Write-Host "Data import to $Env:POSTGRESQL_INSTANCE failed: $_"
}
