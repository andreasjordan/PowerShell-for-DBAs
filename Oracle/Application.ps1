param(
    [int]$MaxRowsPerTable
)
$ErrorActionPreference = 'Stop'

. ..\PowerShell\Environment.ps1
. ..\PowerShell\Import-Schema.ps1
. ..\PowerShell\Import-Data.ps1

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

try {
    $instance = "$EnvironmentServerComputerName/XEPDB1"

    # $credentialUser = Get-Credential -Message $instance -UserName $EnvironmentDatabaseUserName
    $credential = [PSCredential]::new($EnvironmentDatabaseUserName, (ConvertTo-SecureString -String $EnvironmentDatabaseUserPassword -AsPlainText -Force))
    $connection = Connect-OraInstance -Instance $instance -Credential $credential -EnableException

    $tables = Invoke-OraQuery -Connection $connection -Query "SELECT table_name FROM user_tables" -As SingleValue
    foreach ($table in $tables) {
        Invoke-OraQuery -Connection $connection -Query ("DROP TABLE $table")
    }

    Import-Schema -Path ..\PowerShell\SampleSchema.psd1 -DBMS Oracle -Connection $connection -EnableException
    $start = Get-Date
    Import-Data -Path ..\PowerShell\SampleData.json -DBMS Oracle -Connection $connection -MaxRowsPerTable $MaxRowsPerTable -EnableException
    $duration = (Get-Date) - $start

    $connection.Dispose()

    Write-Host "Data import to $EnvironmentServerComputerName finished in $($duration.TotalSeconds) seconds"
} catch {
    Write-Host "Data import to $EnvironmentServerComputerName failed: $_"
}
