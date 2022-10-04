param(
    [int]$MaxRowsPerTable
)
$ErrorActionPreference = 'Stop'

if (-not $Env:ORACLE_DLL) {
    throw 'Environment variable ORACLE_DLL not set'
}
if (-not (Test-Path -Path $Env:ORACLE_DLL)) {
    throw "Environment variable ORACLE_DLL not set correctly, file [$Env:ORACLE_DLL] not found"
}
# Ignore the following error: Could not load file or assembly 'System.Text.Json, Version=4.0.1.1, Culture=neutral, PublicKeyToken=cc7b13ffcd2ddd51' or one of its dependencies
# For details see: https://community.oracle.com/tech/developers/discussion/4502297
try { Add-Type -Path $Env:ORACLE_DLL } catch { }
if ($Env:ORACLE_DLL -match 'Devart') {
    . .\Connect-OraInstance_Devart.ps1
    . .\Invoke-OraQuery_Devart.ps1
} else {
    . .\Connect-OraInstance.ps1
    . .\Invoke-OraQuery.ps1
}
if (-not $Env:ORACLE_INSTANCE) {
    throw 'Environment variable ORACLE_INSTANCE not set'
}
if (-not $Env:ORACLE_USERNAME) {
    throw 'Environment variable ORACLE_USERNAME not set'
}
if (-not $Env:ORACLE_PASSWORD) {
    $credential = Get-Credential -Message $Env:ORACLE_INSTANCE -UserName $Env:ORACLE_USERNAME
} else {
    $credential = [PSCredential]::new($Env:ORACLE_USERNAME, (ConvertTo-SecureString -String $Env:ORACLE_PASSWORD -AsPlainText -Force))
}

. ..\PowerShell\Import-Schema.ps1
. ..\PowerShell\Import-Data.ps1

try {
    $connection = Connect-OraInstance -Instance $Env:ORACLE_INSTANCE -Credential $credential -EnableException

    $tables = Invoke-OraQuery -Connection $connection -Query "SELECT table_name FROM user_tables" -As SingleValue -EnableException
    foreach ($table in $tables) {
        Invoke-OraQuery -Connection $connection -Query ("DROP TABLE $table") -EnableException
    }

    Import-Schema -Path ..\PowerShell\SampleSchema.psd1 -DBMS Oracle -Connection $connection -EnableException
    $start = Get-Date
    Import-Data -Path ..\PowerShell\SampleData.json -DBMS Oracle -Connection $connection -MaxRowsPerTable $MaxRowsPerTable -EnableException
    $duration = (Get-Date) - $start

    $connection.Dispose()

    Write-Host "Data import to $Env:ORACLE_INSTANCE finished in $($duration.TotalSeconds) seconds"
} catch {
    Write-Host "Data import to $Env:ORACLE_INSTANCE failed: $_"
}
