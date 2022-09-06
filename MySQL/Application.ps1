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

# $credentialAdmin = Get-Credential -Message $instance -UserName root
$credentialAdmin = [PSCredential]::new('root', (ConvertTo-SecureString -String $EnvironmentDatabaseAdminPassword -AsPlainText -Force))

# $credentialUser  = Get-Credential -Message $instance -UserName stackoverflow
$credentialUser = [PSCredential]::new('stackoverflow', (ConvertTo-SecureString -String $EnvironmentDatabaseUserPassword -AsPlainText -Force))


$connectionAdmin = Connect-MyInstance -Instance $instance -Credential $credentialAdmin

Invoke-MyQuery -Connection $connectionAdmin -Query "DROP DATABASE IF EXISTS stackoverflow"
Invoke-MyQuery -Connection $connectionAdmin -Query "DROP USER IF EXISTS 'stackoverflow'@'%'"

Invoke-MyQuery -Connection $connectionAdmin -Query "CREATE USER 'stackoverflow'@'%' IDENTIFIED BY '$($credentialUser.GetNetworkCredential().Password)'"
Invoke-MyQuery -Connection $connectionAdmin -Query "CREATE DATABASE stackoverflow"
Invoke-MyQuery -Connection $connectionAdmin -Query "GRANT ALL PRIVILEGES ON stackoverflow.* TO 'stackoverflow'@'%'"

$connectionAdmin.Close()
$connectionAdmin.Dispose()


$connectionUser = Connect-MyInstance -Instance $instance -Credential $credentialUser -Database stackoverflow

Import-Schema -Path ..\PowerShell\SampleSchema.psd1 -DBMS MySQL -Connection $connectionUser
$start = Get-Date
Import-Data -Path ..\PowerShell\SampleData.json -DBMS MySQL -Connection $connectionUser
$duration = (Get-Date) - $start
Write-Host "Data import finished in $($duration.TotalSeconds) seconds"

$connectionUser.Close()
$connectionUser.Dispose()
