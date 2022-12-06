$Password = 'Passw0rd!'
$PasswordSecure = ConvertTo-SecureString -String $Password -AsPlainText -Force

# SQL Server

$sqlAdminCredential = [PSCredential]::new('sa', $PasswordSecure)
. C:\ITTage\PowerShell-for-DBAs\SQLServer\Connect-SqlInstance.ps1
$sqlAdminConnection1 = Connect-SqlInstance -Instance doc-db -Credential $sqlAdminCredential
$sqlAdminConnection2 = Connect-SqlInstance -Instance win-db\sqlexpress -Credential $sqlAdminCredential
$sqlAdminConnection1, $sqlAdminConnection2 | Format-Table -Property State, DataSource, Database, ServerVersion, ConnectionString

. C:\ITTage\PowerShell-for-DBAs\SQLServer\Invoke-SqlQuery.ps1
$sqlAdminQueries = @(
    "CREATE LOGIN StackOverflow WITH PASSWORD = '$Password', CHECK_POLICY = OFF"
    'CREATE DATABASE StackOverflow'
    'ALTER AUTHORIZATION ON DATABASE::StackOverflow TO StackOverflow'
)
foreach ($query in $sqlAdminQueries) {
    Invoke-SqlQuery -Connection $sqlAdminConnection1 -Query $query
    Invoke-SqlQuery -Connection $sqlAdminConnection2 -Query $query
}
$sqlCredential = [PSCredential]::new('StackOverflow', $PasswordSecure)
$sqlConnection1 = Connect-SqlInstance -Instance doc-db -Credential $sqlCredential -Database StackOverflow
$sqlConnection2 = Connect-SqlInstance -Instance win-db\sqlexpress -Credential $sqlCredential -Database StackOverflow

. C:\ITTage\PowerShell-for-DBAs\PowerShell\Import-Schema.ps1
Import-Schema -Path C:\ITTage\PowerShell-for-DBAs\PowerShell\SampleSchema.psd1 -DBMS SQLServer -Connection $sqlConnection1 
Import-Schema -Path C:\ITTage\PowerShell-for-DBAs\PowerShell\SampleSchema.psd1 -DBMS SQLServer -Connection $sqlConnection2

. C:\ITTage\PowerShell-for-DBAs\PowerShell\Import-Data.ps1
Import-Data -Path C:\ITTage\PowerShell-for-DBAs\PowerShell\SampleData.json -DBMS SQLServer -Connection $sqlConnection1
Import-Data -Path C:\ITTage\PowerShell-for-DBAs\PowerShell\SampleData.json -DBMS SQLServer -Connection $sqlConnection2


# Oracle

$oraAdminCredential = [PSCredential]::new('sys', $PasswordSecure)
Add-Type -Path C:\ITTage\NuGet\Oracle.ManagedDataAccess.Core\lib\netstandard2.1\Oracle.ManagedDataAccess.dll
. C:\ITTage\PowerShell-for-DBAs\Oracle\Connect-OraInstance.ps1
$oraAdminConnection1 = Connect-OraInstance -Instance doc-db/xepdb1 -Credential $oraAdminCredential -AsSysdba
$oraAdminConnection2 = Connect-OraInstance -Instance win-db/xepdb1 -Credential $oraAdminCredential -AsSysdba
$oraAdminConnection1, $oraAdminConnection2 | Format-Table -Property State, DataSource, ServerVersion, PDBName, HostName, DatabaseName, InstanceName, ServiceName, ConnectionString

. C:\ITTage\PowerShell-for-DBAs\Oracle\Invoke-OraQuery.ps1
$oraAdminQueries = @(
    "CREATE USER stackoverflow IDENTIFIED BY ""$Password"" DEFAULT TABLESPACE users QUOTA UNLIMITED ON users TEMPORARY TABLESPACE temp"
    'GRANT CREATE SESSION TO stackoverflow'
    'GRANT ALL PRIVILEGES TO stackoverflow'
)
foreach ($query in $oraAdminQueries) {
    Invoke-OraQuery -Connection $oraAdminConnection1 -Query $query
    Invoke-OraQuery -Connection $oraAdminConnection2 -Query $query
}
$oraCredential = [PSCredential]::new('stackoverflow', $PasswordSecure)
$oraConnection1 = Connect-OraInstance -Instance doc-db/xepdb1 -Credential $oraCredential
$oraConnection2 = Connect-OraInstance -Instance win-db/xepdb1 -Credential $oraCredential

. C:\ITTage\PowerShell-for-DBAs\PowerShell\Import-Schema.ps1
Import-Schema -Path C:\ITTage\PowerShell-for-DBAs\PowerShell\SampleSchema.psd1 -DBMS Oracle -Connection $oraConnection1
Import-Schema -Path C:\ITTage\PowerShell-for-DBAs\PowerShell\SampleSchema.psd1 -DBMS Oracle -Connection $oraConnection2

. C:\ITTage\PowerShell-for-DBAs\PowerShell\Import-Data.ps1
Import-Data -Path C:\ITTage\PowerShell-for-DBAs\PowerShell\SampleData.json -DBMS Oracle -Connection $oraConnection1
Import-Data -Path C:\ITTage\PowerShell-for-DBAs\PowerShell\SampleData.json -DBMS Oracle -Connection $oraConnection2


# MySQL

$myAdminCredential = [PSCredential]::new('root', $PasswordSecure)
Add-Type -Path C:\ITTage\NuGet\MySql.Data\lib\net7.0\MySql.Data.dll
. C:\ITTage\PowerShell-for-DBAs\MySQL\Connect-MyInstance.ps1
$myAdminConnection = Connect-MyInstance -Instance doc-db -Credential $myAdminCredential
$myAdminConnection | Format-Table -Property State, DataSource, ServerVersion, ConnectionString

. C:\ITTage\PowerShell-for-DBAs\MySQL\Invoke-MyQuery.ps1
$myAdminQueries = @(
    "CREATE USER 'stackoverflow'@'%' IDENTIFIED BY '$Password'"
    "CREATE DATABASE stackoverflow"
    "GRANT ALL PRIVILEGES ON stackoverflow.* TO 'stackoverflow'@'%'"
)
foreach ($query in $myAdminQueries) {
    Invoke-MyQuery -Connection $myAdminConnection -Query $query
}
$myCredential = [PSCredential]::new('stackoverflow', $PasswordSecure)
$myConnection = Connect-MyInstance -Instance doc-db -Credential $myCredential -Database stackoverflow

. C:\ITTage\PowerShell-for-DBAs\PowerShell\Import-Schema.ps1
Import-Schema -Path C:\ITTage\PowerShell-for-DBAs\PowerShell\SampleSchema.psd1 -DBMS MySQL -Connection $myConnection

. C:\ITTage\PowerShell-for-DBAs\PowerShell\Import-Data.ps1
Import-Data -Path C:\ITTage\PowerShell-for-DBAs\PowerShell\SampleData.json -DBMS MySQL -Connection $myConnection


# PostgreSQL

$pgAdminCredential = [PSCredential]::new('postgres', $PasswordSecure)
Add-Type -Path C:\ITTage\NuGet\Microsoft.Extensions.Logging.Abstractions\lib\net7.0\Microsoft.Extensions.Logging.Abstractions.dll
Add-Type -Path C:\ITTage\NuGet\Npgsql\lib\net7.0\Npgsql.dll
. C:\ITTage\PowerShell-for-DBAs\PostgreSQL\Connect-PgInstance.ps1
$pgAdminConnection = Connect-PgInstance -Instance doc-db -Credential $pgAdminCredential
$pgAdminConnection | Format-Table -Property State, Host, Port, Database, UserName, PostgreSqlVersion, ServerVersion, ConnectionString

. C:\ITTage\PowerShell-for-DBAs\PostgreSQL\Invoke-PgQuery.ps1
$pgAdminQueries = @(
    "CREATE USER stackoverflow WITH PASSWORD '$Password'"
    'CREATE DATABASE stackoverflow WITH OWNER stackoverflow'
)
foreach ($query in $pgAdminQueries) {
    Invoke-PgQuery -Connection $pgAdminConnection -Query $query
}
$pgCredential = [PSCredential]::new('stackoverflow', $PasswordSecure)
$pgConnection = Connect-PgInstance -Instance doc-db -Credential $pgCredential -Database stackoverflow

. C:\ITTage\PowerShell-for-DBAs\PowerShell\Import-Schema.ps1
Import-Schema -Path C:\ITTage\PowerShell-for-DBAs\PowerShell\SampleSchema.psd1 -DBMS PostgreSQL -Connection $pgConnection

. C:\ITTage\PowerShell-for-DBAs\PowerShell\Import-Data.ps1
Import-Data -Path C:\ITTage\PowerShell-for-DBAs\PowerShell\SampleData.json -DBMS PostgreSQL -Connection $pgConnection
