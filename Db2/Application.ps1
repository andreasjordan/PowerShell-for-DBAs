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
if ($Env:MSREP_DLL) {
    if (-not (Test-Path -Path $Env:MSREP_DLL)) {
        throw "Environment variable MSREP_DLL not set correctly, file [$Env:MSREP_DLL] not found"
    }
    Add-Type -Path $Env:MSREP_DLL
}
Add-Type -Path $Env:DB2_DLL
if ($Env:DB2_DLL -match 'Core') {
    . .\Connect-Db2Instance_Core.ps1
    . .\Invoke-Db2Query_Core.ps1
} else {
    . .\Connect-Db2Instance.ps1
    . .\Invoke-Db2Query.ps1
}

$instance = "$($EnvironmentServerComputerName):50000"
$database = 'stack'

# $credentialAdmin = Get-Credential -Message $instance -UserName db2admin
# $credentialAdmin = [PSCredential]::new('db2admin', (ConvertTo-SecureString -String $EnvironmentDatabaseAdminPassword -AsPlainText -Force))

# $credentialUser  = Get-Credential -Message $instance -UserName stackoverflow
$credentialUser = [PSCredential]::new('stackoverflow', (ConvertTo-SecureString -String $EnvironmentDatabaseUserPassword -AsPlainText -Force))

try {
    Invoke-Command -ComputerName $EnvironmentServerComputerName -ScriptBlock { Remove-LocalUser -Name $using:credentialUser.UserName -Confirm:$false -ErrorAction Ignore }
    Invoke-Command -ComputerName $EnvironmentServerComputerName -ScriptBlock { $null = New-LocalUser -Name $using:credentialUser.UserName -Password $using:credentialUser.Password }
} catch {
    Write-Warning -Message "Could not recreate the user, maybe we are on Linux."
}

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
