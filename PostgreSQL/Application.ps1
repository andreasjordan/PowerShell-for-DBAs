$ErrorActionPreference = 'Stop'

. ..\PowerShell\Environment.ps1
. ..\PowerShell\Import-Schema.ps1
. ..\PowerShell\Import-Data.ps1

if (-not $Env:POSTGRESQL_DLL) {
    throw 'Environment variable MYSQL_DLL not set'
}
if (-not (Test-Path -Path $Env:POSTGRESQL_DLL)) {
    throw "Environment variable MYSQL_DLL not set correctly, file [$Env:POSTGRESQL_DLL] not found"
}
Add-Type -Path $Env:POSTGRESQL_DLL
if ($Env:POSTGRESQL_DLL -match 'Devart') {
    . .\Connect-PgInstance_Devart.ps1
    . .\Invoke-PgQuery_Devart.ps1
} else {
    . .\Connect-PgInstance.ps1
    . .\Invoke-PgQuery.ps1
}

$instance = $EnvironmentServerComputerName

# $credentialAdmin = Get-Credential -Message $instance -UserName postgres
$credentialAdmin = [PSCredential]::new('postgres', (ConvertTo-SecureString -String $EnvironmentDatabaseAdminPassword -AsPlainText -Force))

# $credentialUser  = Get-Credential -Message $instance -UserName stackoverflow
$credentialUser = [PSCredential]::new('stackoverflow', (ConvertTo-SecureString -String $EnvironmentDatabaseUserPassword -AsPlainText -Force))


$connectionAdmin = Connect-PgInstance -Instance $instance -Credential $credentialAdmin

Invoke-PgQuery -Connection $connectionAdmin -Query "DROP DATABASE IF EXISTS stackoverflow WITH (FORCE)"
Invoke-PgQuery -Connection $connectionAdmin -Query "DROP USER IF EXISTS stackoverflow"

Invoke-PgQuery -Connection $connectionAdmin -Query "CREATE USER stackoverflow WITH PASSWORD '$($credentialUser.GetNetworkCredential().Password)'"
Invoke-PgQuery -Connection $connectionAdmin -Query "CREATE DATABASE stackoverflow WITH OWNER stackoverflow"

$connectionAdmin.Close()
$connectionAdmin.Dispose()


$connectionUser = Connect-PgInstance -Instance $instance -Credential $credentialUser -Database stackoverflow
Import-Schema -Path ..\PowerShell\SampleSchema.psd1 -DBMS PostgreSQL -Connection $connectionUser
$start = Get-Date
Import-Data -Path ..\PowerShell\SampleData.json -DBMS PostgreSQL -Connection $connectionUser
$duration = (Get-Date) - $start
Write-Host "Data import finished in $($duration.TotalSeconds) seconds"

$connectionUser.Close()
$connectionUser.Dispose()

