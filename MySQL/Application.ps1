$ErrorActionPreference = 'Stop'

. ..\PowerShell\Environment.ps1
. ..\PowerShell\Import-Schema.ps1
. ..\PowerShell\Import-Data.ps1
. .\Connect-MyInstance.ps1
. .\Invoke-MyQuery.ps1

try {
    Add-Type -Path 'C:\Program Files (x86)\Devart\dotConnect\MySQL\Devart.Data.MySql.dll'
} catch {
    $ex = $_
    $ex.Exception.Message
    $ex.Exception.LoaderExceptions
    throw "Adding type failed"
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
Import-Data -Path ..\PowerShell\SampleData.json -DBMS MySQL -Connection $connectionUser

$connectionUser.Close()
$connectionUser.Dispose()