$ErrorActionPreference = 'Stop'

. ..\PowerShell\Environment.ps1
. ..\PowerShell\Import-Schema.ps1
. ..\PowerShell\Import-Data.ps1

if (-not $Env:ORACLE_DLL) {
    throw 'Environment variable ORACLE_DLL not set'
}
try {
    Add-Type -Path $Env:ORACLE_DLL
} catch {
    $ex = $_
    $ex.Exception.Message
    $ex.Exception.LoaderExceptions
    throw 'Adding type failed'
}
if ($Env:ORACLE_DLL -match 'Devart') {
    . .\Connect-OraInstance_Devart.ps1
    . .\Invoke-OraQuery_Devart.ps1
} else {
    . .\Connect-OraInstance.ps1
    . .\Invoke-OraQuery.ps1
}

$instance = "$EnvironmentServerComputerName/XEPDB1"

# $credentialAdmin = Get-Credential -Message $instance -UserName sys
$credentialAdmin = [PSCredential]::new('sys', (ConvertTo-SecureString -String $EnvironmentDatabaseAdminPassword -AsPlainText -Force))

# $credentialUser  = Get-Credential -Message $instance -UserName stackoverflow
$credentialUser = [PSCredential]::new('stackoverflow', (ConvertTo-SecureString -String $EnvironmentDatabaseUserPassword -AsPlainText -Force))


$connectionAdmin = Connect-OraInstance -Instance $instance -Credential $credentialAdmin -AsSysdba

Invoke-OraQuery -Connection $connectionAdmin -Query "DROP USER stackoverflow CASCADE"

Invoke-OraQuery -Connection $connectionAdmin -Query "CREATE USER stackoverflow IDENTIFIED BY $($credentialUser.GetNetworkCredential().Password) DEFAULT TABLESPACE users QUOTA UNLIMITED ON users TEMPORARY TABLESPACE temp"
Invoke-OraQuery -Connection $connectionAdmin -Query "GRANT CREATE SESSION TO stackoverflow"
Invoke-OraQuery -Connection $connectionAdmin -Query "GRANT ALL PRIVILEGES TO stackoverflow"

$connectionAdmin.Close()
$connectionAdmin.Dispose()


$connectionUser = Connect-OraInstance -Instance $instance -Credential $credentialUser

Import-Schema -Path ..\PowerShell\SampleSchema.psd1 -DBMS Oracle -Connection $connectionUser
Import-Data -Path ..\PowerShell\SampleData.json -DBMS Oracle -Connection $connectionUser

$connectionUser.Close()
$connectionUser.Dispose()
