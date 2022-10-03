param(
    [int]$MaxRowsPerTable
)
$ErrorActionPreference = 'Stop'

. ..\PowerShell\Environment.ps1
. ..\PowerShell\Import-Schema.ps1
. ..\PowerShell\Import-Data.ps1

if (-not $Env:MYSQL_DLL) {
    throw 'Environment variable MYSQL_DLL not set'
}
if (-not (Test-Path -Path $Env:MYSQL_DLL)) {
    throw "Environment variable MYSQL_DLL not set correctly, file [$Env:MYSQL_DLL] not found"
}
# Ignore the following errors: Could not load file or assembly
# For details see: https://community.oracle.com/tech/developers/discussion/4502297
try { Add-Type -Path $Env:MYSQL_DLL } catch { }
if ($Env:MYSQL_DLL -match 'Devart') {
    . .\Connect-MyInstance_Devart.ps1
    . .\Invoke-MyQuery_Devart.ps1
} else {
    . .\Connect-MyInstance.ps1
    . .\Invoke-MyQuery.ps1
}

$instance = $EnvironmentServerComputerName
$database = 'stackoverflow'

try {
    # $credential = Get-Credential -Message $instance -UserName $EnvironmentDatabaseUserName
    $credential = [PSCredential]::new($EnvironmentDatabaseUserName, (ConvertTo-SecureString -String $EnvironmentDatabaseUserPassword -AsPlainText -Force))
    $connection = Connect-MyInstance -Instance $instance -Credential $credential -Database $database

    #$tables = Invoke-MyQuery -Connection $connection -Query "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'" -As SingleValue
    #foreach ($table in $tables) {
    #    Invoke-MyQuery -Connection $connection -Query ("DROP TABLE $table")
    #}

    Import-Schema -Path ..\PowerShell\SampleSchema.psd1 -DBMS MySQL -Connection $connection -EnableException
    $start = Get-Date
    Import-Data -Path ..\PowerShell\SampleData.json -DBMS MySQL -Connection $connection -MaxRowsPerTable $MaxRowsPerTable -EnableException
    $duration = (Get-Date) - $start

    $connection.Dispose()
    
    Write-Host "Data import to $EnvironmentServerComputerName finished in $($duration.TotalSeconds) seconds"
} catch {
    Write-Host "Data import to $EnvironmentServerComputerName failed: $_"
}
