param(
    [int]$MaxRowsPerTable
)
$ErrorActionPreference = 'Stop'

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

. $PSScriptRoot\Import-OraLibrary.ps1
. $PSScriptRoot\Connect-OraInstance.ps1
. $PSScriptRoot\Invoke-OraQuery.ps1
. $PSScriptRoot\..\PowerShell\Import-Schema.ps1
. $PSScriptRoot\..\PowerShell\Import-Data.ps1

try {
    Import-OraLibrary -EnableException
    
    $connection = Connect-OraInstance -Instance $Env:ORACLE_INSTANCE -Credential $credential -EnableException

    $tables = Invoke-OraQuery -Connection $connection -Query "SELECT table_name FROM user_tables" -As SingleValue -EnableException
    foreach ($table in $tables) {
        Invoke-OraQuery -Connection $connection -Query ("DROP TABLE $table") -EnableException
    }

    Import-Schema -Path $PSScriptRoot\..\PowerShell\SampleSchema.psd1 -DBMS Oracle -Connection $connection -EnableException
    $start = Get-Date
    Import-Data -Path $PSScriptRoot\..\PowerShell\SampleData.json -DBMS Oracle -Connection $connection -MaxRowsPerTable $MaxRowsPerTable -EnableException
    $duration = (Get-Date) - $start

    $connection.Dispose()

    Write-Host "Data import to $Env:ORACLE_INSTANCE finished in $($duration.TotalSeconds) seconds"
} catch {
    Write-Host "Data import to $Env:ORACLE_INSTANCE failed: $_"
}
