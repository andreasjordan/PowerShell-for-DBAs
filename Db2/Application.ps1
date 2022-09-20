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

$instance = "$($EnvironmentServerComputerName):25000"
$database = 'SAMPLE'

# $credentialUser  = Get-Credential -Message $instance -UserName stackoverflow
$credentialUser = [PSCredential]::new('stackoverflow', (ConvertTo-SecureString -String $EnvironmentDatabaseUserPassword -AsPlainText -Force))

$connectionUser = Connect-Db2Instance -Instance $instance -Credential $credentialUser -Database $database

$tables = Invoke-Db2Query -Connection $connectionUser -Query "SELECT name FROM sysibm.systables WHERE creator = '$($credentialUser.UserName.ToUpper())'" -As SingleValue
foreach ($table in $tables) {
    Invoke-Db2Query -Connection $connectionUser -Query "DROP TABLE $table"
}

Import-Schema -Path ..\PowerShell\SampleSchema.psd1 -DBMS Db2 -Connection $connectionUser
$start = Get-Date
Import-Data -Path ..\PowerShell\SampleData.json -DBMS Db2 -Connection $connectionUser
$duration = (Get-Date) - $start
Write-Host "Data import finished in $($duration.TotalSeconds) seconds"

$connectionUser.Close()
$connectionUser.Dispose()
