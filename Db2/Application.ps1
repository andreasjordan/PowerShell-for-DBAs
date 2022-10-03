param(
    [int]$MaxRowsPerTable
)
$ErrorActionPreference = 'Stop'

. ..\PowerShell\Environment.ps1
. ..\PowerShell\Import-Schema.ps1
. ..\PowerShell\Import-Data.ps1

if (-not $Env:DB2_DLL) {
    throw 'Environment variable DB2_DLL not set'
}
if (-not (Test-Path -Path $Env:DB2_DLL)) {
    throw "Environment variable DB2_DLL not set correctly, file [$Env:DB2_DLL] not found"
}
# For NuGet package on Windows: Change $Env:PATH
if ($Env:DB2_DLL -match 'lib\\[^\\]+\\IBM\.Data\.Db2(\.Core)?\.dll') {
    $path = $Env:INFORMIX_DLL -replace 'lib\\[^\\]+\\IBM\.Data\.Db2(\.Core)?\.dll', 'buildTransitive\clidriver\bin'
    $Env:PATH = "$Env:PATH;$path"
}
# Ignore the following error: Could not load file or assembly 'Microsoft.ReportingServices.Interfaces, Version=10.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91' or one of its dependencies
# For details see: https://community.oracle.com/tech/developers/discussion/4502297
try { Add-Type -Path $Env:DB2_DLL } catch { }
if ($Env:DB2_DLL -match 'Core') {
    . .\Connect-Db2Instance_Core.ps1
    . .\Invoke-Db2Query_Core.ps1
} else {
    . .\Connect-Db2Instance.ps1
    . .\Invoke-Db2Query.ps1
}

if ($EnvironmentServerComputerName -in 'localhost', 'Db2-1') {
    $instance = "$($EnvironmentServerComputerName):50000"
    $database = 'DEMO'
} else {
    $instance = "$($EnvironmentServerComputerName):25000"
    $database = 'SAMPLE'
}

try {
    # $credential = Get-Credential -Message $instance -UserName $EnvironmentDatabaseUserName
    $credential = [PSCredential]::new($EnvironmentDatabaseUserName, (ConvertTo-SecureString -String $EnvironmentDatabaseUserPassword -AsPlainText -Force))
    $connection = Connect-Db2Instance -Instance $instance -Credential $credential -Database $database

    $tables = Invoke-Db2Query -Connection $connection -Query "SELECT name FROM sysibm.systables WHERE creator = '$($credential.UserName.ToUpper())'" -As SingleValue
    foreach ($table in $tables) {
        Invoke-Db2Query -Connection $connection -Query "DROP TABLE $table"
    }

    Import-Schema -Path ..\PowerShell\SampleSchema.psd1 -DBMS Db2 -Connection $connection -EnableException
    $start = Get-Date
    Import-Data -Path ..\PowerShell\SampleData.json -DBMS Db2 -Connection $connection -MaxRowsPerTable $MaxRowsPerTable -EnableException
    $duration = (Get-Date) - $start

    $connection.Dispose()
    
    Write-Host "Data import to $EnvironmentServerComputerName finished in $($duration.TotalSeconds) seconds"
} catch {
    Write-Host "Data import to $EnvironmentServerComputerName failed: $_"
}
