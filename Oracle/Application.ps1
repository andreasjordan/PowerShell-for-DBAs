$ErrorActionPreference = 'Stop'

. ..\PowerShell\Environment.ps1
. ..\PowerShell\Import-Schema.ps1
. ..\PowerShell\Import-Data.ps1
. .\Connect-OraInstance.ps1
. .\Invoke-OraQuery.ps1

try {
    Add-Type -Path 'D:\oracle\product\19.0.0\client_1\odp.net\managed\common\Oracle.ManagedDataAccess.dll'
} catch {
    $ex = $_
    $ex.Exception.Message
    $ex.Exception.LoaderExceptions
    throw "Adding type failed"
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