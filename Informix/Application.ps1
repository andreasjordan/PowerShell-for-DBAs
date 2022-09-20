$ErrorActionPreference = 'Stop'

. ..\PowerShell\Environment.ps1
. ..\PowerShell\Import-Schema.ps1
. ..\PowerShell\Import-Data.ps1

if (-not $Env:INFORMIX_DLL) {
    throw 'Environment variable INFORMIX_DLL not set'
}
if (-not (Test-Path -Path $Env:INFORMIX_DLL)) {
    throw "Environment variable INFORMIX_DLL not set correctly, file [$Env:INFORMIX_DLL] not found"
}
if ($Env:INFORMIX_DLL -match 'IBM.Data.DB2') {
    try { Add-Type -Path $Env:INFORMIX_DLL } catch { }

    . .\Connect-IfxInstance_Db2.ps1
    . .\Invoke-IfxQuery_Db2.ps1
    
    $instance = "$($EnvironmentServerComputerName):9089"
} else {
    Add-Type -Path $Env:INFORMIX_DLL

    . .\Connect-IfxInstance.ps1
    . .\Invoke-IfxQuery.ps1

    $instance = "$($EnvironmentServerComputerName):9088:ol_informix1410"
}

$database = 'stackoverflow'

# $credentialUser  = Get-Credential -Message $instance -UserName ORDIX\stackoverflow
$credentialUser = [PSCredential]::new('ORDIX\stackoverflow', (ConvertTo-SecureString -String $EnvironmentDatabaseUserPassword -AsPlainText -Force))

$connectionUser = Connect-IfxInstance -Instance $instance -Credential $credentialUser -Database $database

$tables = Invoke-IfxQuery -Connection $connectionUser -Query "SELECT tabname FROM systables WHERE owner = 'stackoverflow'" -As SingleValue
foreach ($table in $tables) {
    Invoke-IfxQuery -Connection $connectionUser -Query "DROP TABLE $table"
}

Import-Schema -Path ..\PowerShell\SampleSchema.psd1 -DBMS Informix -Connection $connectionUser
$start = Get-Date
Import-Data -Path ..\PowerShell\SampleData.json -DBMS Informix -Connection $connectionUser
$duration = (Get-Date) - $start
Write-Host "Data import finished in $($duration.TotalSeconds) seconds"

$connectionUser.Close()
$connectionUser.Dispose()
