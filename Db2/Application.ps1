param(
    [int]$MaxRowsPerTable
)
$ErrorActionPreference = 'Stop'

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
if (-not $Env:DB2_INSTANCE) {
    throw 'Environment variable DB2_INSTANCE not set'
}
if (-not $Env:DB2_DATABASE) {
    throw 'Environment variable DB2_DATABASE not set'
}
if (-not $Env:DB2_USERNAME) {
    throw 'Environment variable DB2_USERNAME not set'
}
if (-not $Env:DB2_PASSWORD) {
    $credential = Get-Credential -Message $Env:DB2_INSTANCE -UserName $Env:DB2_USERNAME
} else {
    $credential = [PSCredential]::new($Env:DB2_USERNAME, (ConvertTo-SecureString -String $Env:DB2_PASSWORD -AsPlainText -Force))
}

. ..\PowerShell\Import-Schema.ps1
. ..\PowerShell\Import-Data.ps1

try {
    $connection = Connect-Db2Instance -Instance $Env:DB2_INSTANCE -Credential $credential -Database $Env:DB2_DATABASE -EnableException

    $tables = Invoke-Db2Query -Connection $connection -Query "SELECT name FROM sysibm.systables WHERE creator = '$($credential.UserName.ToUpper())'" -As SingleValue -EnableException
    foreach ($table in $tables) {
        Invoke-Db2Query -Connection $connection -Query "DROP TABLE $table" -EnableException
    }

    Import-Schema -Path ..\PowerShell\SampleSchema.psd1 -DBMS Db2 -Connection $connection -EnableException
    $start = Get-Date
    Import-Data -Path ..\PowerShell\SampleData.json -DBMS Db2 -Connection $connection -MaxRowsPerTable $MaxRowsPerTable -EnableException
    $duration = (Get-Date) - $start

    $connection.Dispose()
    
    Write-Host "Data import to $Env:DB2_INSTANCE finished in $($duration.TotalSeconds) seconds"
} catch {
    Write-Host "Data import to $Env:DB2_INSTANCE failed: $_"
}
