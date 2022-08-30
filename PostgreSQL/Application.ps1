$ErrorActionPreference = 'Stop'

# This script uses the variable $serverComputerName that was set in Environment.ps1.
# This script uses Connect-PgInstance.ps1, Invoke-PgQuery.ps1 and Import-Schema.ps1.

try {
    Add-Type -Path 'C:\Program Files (x86)\Devart\dotConnect\PostgreSQL\Devart.Data.PostgreSql.dll'
} catch {
    $ex = $_
    $ex.Exception.Message
    $ex.Exception.LoaderExceptions
}

$instance = $serverComputerName

$credentialAdmin = Get-Credential -Message $instance -UserName postgres       # start123
$credentialUser  = Get-Credential -Message $instance -UserName stackoverflow  # start456


$connectionAdmin = Connect-PgInstance -Instance $instance -Credential $credentialAdmin

Invoke-PgQuery -Connection $connectionAdmin -Query "DROP DATABASE IF EXISTS stackoverflow WITH (FORCE)"
Invoke-PgQuery -Connection $connectionAdmin -Query "DROP USER IF EXISTS stackoverflow"

Invoke-PgQuery -Connection $connectionAdmin -Query "CREATE USER stackoverflow WITH PASSWORD '$($credentialUser.GetNetworkCredential().Password)'"
Invoke-PgQuery -Connection $connectionAdmin -Query "CREATE DATABASE stackoverflow WITH OWNER stackoverflow"

$connectionAdmin.Close()
$connectionAdmin.Dispose()


$connectionUser = Connect-PgInstance -Instance $instance -Credential $credentialUser -Database stackoverflow

$schema = Import-Schema -Path \\fs\Skripte\PowerShell-for-DBAs\PowerShell\Schema.psd1 -DBMS PostgreSQL
foreach ($query in $schema) {
    Invoke-PgQuery -Connection $connectionUser -Query $query
}

$connectionUser.Close()
$connectionUser.Dispose()
