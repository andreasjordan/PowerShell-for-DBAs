param(
    [int]$MaxRowsPerTable
)
$ErrorActionPreference = 'Stop'

Import-Module -Name dbatools  # Install-Module -Name dbatools -Scope CurrentUser
if (-not $Env:SQLSERVER_INSTANCE) {
    throw 'Environment variable SQLSERVER_INSTANCE not set'
}
if (-not $Env:SQLSERVER_DATABASE) {
    throw 'Environment variable SQLSERVER_DATABASE not set'
}
if (-not $Env:SQLSERVER_USERNAME) {
    throw 'Environment variable SQLSERVER_USERNAME not set'
}
if (-not $Env:SQLSERVER_PASSWORD) {
    $credential = Get-Credential -Message $Env:SQLSERVER_INSTANCE -UserName $Env:SQLSERVER_USERNAME
} else {
    $credential = [PSCredential]::new($Env:SQLSERVER_USERNAME, (ConvertTo-SecureString -String $Env:SQLSERVER_PASSWORD -AsPlainText -Force))
}

. ..\PowerShell\Import-Schema.ps1
. ..\PowerShell\Import-Data.ps1

try {
    $connection = Connect-DbaInstance -SqlInstance $Env:SQLSERVER_INSTANCE -SqlCredential $credential -Database $Env:SQLSERVER_DATABASE -NonPooledConnection

    $tables = Invoke-DbaQuery -SqlInstance $connection -Query "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'" -As SingleValue -EnableException
    foreach ($table in $tables) {
        Invoke-DbaQuery -SqlInstance $connection -Query ("DROP TABLE $table") -EnableException
    }

    Import-Schema -Path ..\PowerShell\SampleSchema.psd1 -DBMS SQLServer -Connection $connection -EnableException
    $start = Get-Date
    Import-Data -Path ..\PowerShell\SampleData.json -DBMS SQLServer -Connection $connection -MaxRowsPerTable $MaxRowsPerTable -EnableException
    $duration = (Get-Date) - $start

    $null = $connection | Disconnect-DbaInstance

    Write-Host "Data import to $Env:SQLSERVER_INSTANCE finished in $($duration.TotalSeconds) seconds"
} catch {
    Write-Host "Data import to $Env:SQLSERVER_INSTANCE failed: $_"
}
