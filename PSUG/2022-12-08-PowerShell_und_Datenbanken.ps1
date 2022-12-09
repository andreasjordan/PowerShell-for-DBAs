# 08.12.2022 / PowerShell und Datenbanken - ein gutes Team
# https://www.meetup.com/de-DE/PowerShell-UserGroup-Inn-Salzach/
# https://www.meetup.com/de-DE/PowerShell-UserGroup-Inn-Salzach/events/289186268
# https://blog.ordix.de/andreas-jordan


# Einfach mal die aktuelle Zeit holen, ganz klassisch mit PowerShell-Syntax:
$now = Get-Date

# Was kommt denn da zurück?
$now.GetType().FullName  # System.DateTime

# Alternative, mit .NET-Syntax:
[System.DateTime]::Now

# Und genau so können wir jetzt auch andere .NET-Klassen nutzen, um eine Verbindung zu einer SQL Server Instanz herzustellen:
$csb = [System.Data.SqlClient.SqlConnectionStringBuilder]::new()
$csb.DataSource = 'win-db'       # geht nicht
$csb['Data Source'] = 'win-db'   # geht
$csb.'Data Source'  = 'win-db'   # geht auch

$csb.DataSource                  # geht


$csb['Data Source'] = 'win-db\sqlexpress'
$csb['Integrated Security'] = $true

$csb.ConnectionString

$connection = [System.Data.SqlClient.SqlConnection]::new($csb.ConnectionString)
$connection.Open()

# Das klappt. Aber jetzt mit SQL Login...

$credential = Get-Credential -Message 'Zugang zum SQL Server' -UserName sa

$csb = [System.Data.SqlClient.SqlConnectionStringBuilder]::new()
$csb['Data Source'] = 'win-db\sqlexpress'
$csb['User ID'] = $credential.UserName
$csb['Password'] = $credential.GetNetworkCredential().Password
$connection = [System.Data.SqlClient.SqlConnection]::new($csb.ConnectionString)
$connection.Open()
$connection | Format-Table -Property State, DataSource, Database, ServerVersion, ConnectionString

# Verbindung wieder schließen:
$connection.Dispose()


### Jetzt Oracle

# Auf meinem System habe ich einen Oracle-Client in der Version 19c (ältere Clients gehen auch):
Add-Type -Path C:\oracle\product\19.0.0\client_1\odp.net\managed\common\Oracle.ManagedDataAccess.dll

$credential = Get-Credential -Message 'Zugang zu Oracle' -UserName sys
$csb = [Oracle.ManagedDataAccess.Client.OracleConnectionStringBuilder]::new()
$csb['Data Source'] = 'win-db/xepdb1'
$csb['User ID'] = $credential.UserName
$csb['Password'] = $credential.GetNetworkCredential().Password
$csb['DBA Privilege'] = 'SYSDBA'
$connection = [Oracle.ManagedDataAccess.Client.OracleConnection]::new($csb.ConnectionString)
$connection.Open()
$connection | Format-Table -Property State, DataSource, ServerVersion, PDBName, HostName, DatabaseName, InstanceName, ServiceName, ConnectionString
$connection | Format-Table -Property State, DataSource, ConnectionString


### Jetzt mit Nuget (https://www.nuget.org/packages/Oracle.ManagedDataAccess - herunterladen und auspacken, denn es ist ein ZIP-Archiv):

try { 
    Add-Type -Path C:\ITTage\NuGet\Oracle.ManagedDataAccess\lib\net462\Oracle.ManagedDataAccess.dll
} catch {
    $ex = $_
}

$ex.Exception.LoaderExceptions

# Ja, angeblich fehlt System.Text.Json, aber nur in der angegebenen Version 4.0.1.1
# Details: https://community.oracle.com/tech/developers/discussion/4502297

$credential = Get-Credential -Message 'Zugang zu Oracle' -UserName sys
$csb = [Oracle.ManagedDataAccess.Client.OracleConnectionStringBuilder]::new()
$csb['Data Source'] = 'win-db/xepdb1'
$csb['User ID'] = $credential.UserName
$csb['Password'] = $credential.GetNetworkCredential().Password
$csb['DBA Privilege'] = 'SYSDBA'
$connection = [Oracle.ManagedDataAccess.Client.OracleConnection]::new($csb.ConnectionString)
$connection.Open()
$connection | Format-Table -Property State, DataSource, ServerVersion, PDBName, HostName, DatabaseName, InstanceName, ServiceName, ConnectionString
$connection | Format-Table -Property State, DataSource, ConnectionString

. C:\ITTage\PowerShell-for-DBAs\Oracle\Connect-OraInstance.ps1
$connection = Connect-OraInstance -Instance win-db/xepdb1 -Credential $credential -AsSysdba


# Jetzt aber mal eine Abfrage ausführen:

. C:\ITTage\PowerShell-for-DBAs\Oracle\Invoke-OraQuery.ps1

$data = Invoke-OraQuery -Connection $connection -Query 'SELECT * FROM dba_users'
$data | ogv

# Mit Bind-Parmetern:
$param = @{
    Connection      = $connection
    Query           = 'SELECT * FROM dba_users WHERE account_status = :status'
    ParameterValues = @{ status = 'OPEN' }
}
$data = Invoke-OraQuery @param 
$data | Format-Table -Property username, created


# Was kommt denn da eigentlich?
$data[0].GetType().FullName

# Bei mir kommen da ganz "klassische" PSCustomObject zurück - siehe Code.

# Mehr Infos und Beispiele:
# https://github.com/andreasjordan/PowerShell-for-DBAs/blob/main/DOAG2022/demo.ps1
# https://github.com/andreasjordan/PowerShell-for-DBAs
