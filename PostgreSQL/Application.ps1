$ErrorActionPreference = 'Stop'

. ..\PowerShell\Environment.ps1
. ..\PowerShell\Import-Schema.ps1
. ..\PowerShell\Import-Data.ps1
. .\Connect-PgInstance.ps1
. .\Invoke-PgQuery.ps1

try {
    Add-Type -Path 'C:\Program Files (x86)\Devart\dotConnect\PostgreSQL\Devart.Data.PostgreSql.dll'
} catch {
    $ex = $_
    $ex.Exception.Message
    $ex.Exception.LoaderExceptions
    throw "Adding type failed"
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
Import-Data -Path ..\PowerShell\SampleData.json -DBMS PostgreSQL -Connection $connectionUser

$connectionUser.Close()
$connectionUser.Dispose()
