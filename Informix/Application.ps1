# Caution: This is still work in progress!

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
Add-Type -Path $Env:INFORMIX_DLL
. .\Connect-IfxInstance.ps1
. .\Invoke-IfxQuery.ps1

# $instance = "$($EnvironmentServerComputerName):9088:ol_informix1410"
$instance = "192.168.131.208:9088:ol_informix1410"
$database = 'sysmaster'

# $credentialAdmin = Get-Credential -Message $instance -UserName informix
$credentialAdmin = [PSCredential]::new('informix', (ConvertTo-SecureString -String $EnvironmentDatabaseAdminPassword -AsPlainText -Force))

# $credentialUser  = Get-Credential -Message $instance -UserName stackoverflow
$credentialUser = [PSCredential]::new('stackoverflow', (ConvertTo-SecureString -String $EnvironmentDatabaseUserPassword -AsPlainText -Force))


$connectionAdmin = Connect-IfxInstance -Instance $instance -Credential $credentialAdmin -Database $database



# $connectionUser = Connect-IfxInstance -Instance $instance -Credential $credentialUser -Database $database
$connectionUser = $connectionAdmin

#$tables = Invoke-IfxQuery -Connection $connectionUser -Query "SELECT name FROM sysibm.systables WHERE creator = '$($credentialUser.UserName.ToUpper())'" -As SingleValue
$tables = 'Badges', 'Comments', 'LinkTypes', 'PostLinks', 'Posts', 'PostTypes', 'Users', 'Votes', 'VoteTypes'
foreach ($table in $tables) {
    Invoke-IfxQuery -Connection $connectionUser -Query "DROP TABLE $table"
}

Import-Schema -Path ..\PowerShell\SampleSchema.psd1 -DBMS Informix -Connection $connectionUser
$start = Get-Date
Import-Data -Path ..\PowerShell\SampleData.json -DBMS Informix -Connection $connectionUser -Verbose
$duration = (Get-Date) - $start
Write-Host "Data import finished in $($duration.TotalSeconds) seconds"

$connectionUser.Close()
$connectionUser.Dispose()
