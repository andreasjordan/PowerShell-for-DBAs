# Verbindung zu einer Datenbank mit PowerShell

# [System.Data.SqlClient.SqlConnection]::new()

$csb = [System.Data.SqlClient.SqlConnectionStringBuilder]::new()
$csb | gm
$csb.DataSource = 'win-db'      # Keyword not supported: 'DataSource'.
$csb.'Data Source' = 'win-db'   # Alternative 1
$csb['Data Source'] = 'win-db'  # Alternative 2
$csb.DataSource                 # Ausgeben des Wertes funktioniert aber

# Das ist dann der komplette ConnectionString:
$csb.ConnectionString

# Jetzt eine Verbindung erstellen:
$connection = [System.Data.SqlClient.SqlConnection]::new($csb.ConnectionString)
$connection.Open()

# Fehler: Falsche Instanz
$csb['Data Source'] = 'win-db\sqlexpress'
$connection = [System.Data.SqlClient.SqlConnection]::new($csb.ConnectionString)
$connection.Open()

# Fehler: Kein User
# Zur Windows-Instanz sollte es mit Windows-Authentifizierung klappen:
$csb['Integrated Security'] = $true
$connection = [System.Data.SqlClient.SqlConnection]::new($csb.ConnectionString)
$connection.Open()


# Und wie geht das mit SQL Logins?
$credential = Get-Credential -Message 'Zugang zum SQL Server' -UserName sa
$credential.UserName
$credential.Password
$credential.GetNetworkCredential().Password

$csb = [System.Data.SqlClient.SqlConnectionStringBuilder]::new()
$csb['Data Source'] = 'doc-db'
$csb['User ID'] = $credential.UserName
$csb['Password'] = $credential.GetNetworkCredential().Password
$connection = [System.Data.SqlClient.SqlConnection]::new($csb.ConnectionString)
$connection.Open()
$connection | Format-Table -Property State, DataSource, Database, ServerVersion, ConnectionString

### Bis hierhin hat alles ohne zusätzliche Komponenten funktioniert. Alles ist in .NET enthalten.
### Aber wir sind auch nur beim SQL Server, was ist denn mit Oracle?

# Situation: Wir haben hier schon einen Oracle Client in der Version 19c oder älter

Add-Type -Path C:\oracle\product\19.0.0\client_1\odp.net\managed\common\Oracle.ManagedDataAccess.dll

# [Oracle.ManagedDataAccess.
$csb = [Oracle.ManagedDataAccess.Client.OracleConnectionStringBuilder]::new()

#  System.Data.              SqlClient.    SqlConnectionStringBuilder
#  Oracle.ManagedDataAccess.    Client. OracleConnectionStringBuilder


$credential = Get-Credential -Message 'Zugang zu Oracle' -UserName sys
$credential.UserName
$credential.Password
$credential.GetNetworkCredential().Password

# Kann auch gesichert werden:
$credential | Export-Clixml -Path C:\ITTage\oracleSysCredential.xml

# Und wieder eingelsen werden:
$credential = Import-Clixml -Path C:\ITTage\oracleSysCredential.xml

$csb = [Oracle.ManagedDataAccess.Client.OracleConnectionStringBuilder]::new()
$csb['Data Source'] = 'doc-db/xepdb1'
$csb['User ID'] = $credential.UserName
$csb['Password'] = $credential.GetNetworkCredential().Password
$csb['DBA Privilege'] = 'SYSDBA'
$connection = [Oracle.ManagedDataAccess.Client.OracleConnection]::new($csb.ConnectionString)
$connection.Open()
$connection | Format-Table -Property State, DataSource, ServerVersion, PDBName, HostName, DatabaseName, InstanceName, ServiceName, ConnectionString




# Situation: Wir haben keinen Oracle Client, aber Internet-Zugang

# Browser: nuget.org / Suche nach "oracle"

Add-Type -Path C:\ITTage\NuGet\Oracle.ManagedDataAccess\lib\net462\Oracle.ManagedDataAccess.dll

try { Add-Type -Path C:\ITTage\NuGet\Oracle.ManagedDataAccess\lib\net462\Oracle.ManagedDataAccess.dll } catch { $ex = $_ }
$ex.Exception.LoaderExceptions

# Ja, angeblich fehlt System.Text.Json, aber nur in der angegebenen Version 4.0.1.1
# Details: https://community.oracle.com/tech/developers/discussion/4502297

# Die benötigten Teile wurden aber geladen, wir können weitermachen wie bisher:

$credential = Import-Clixml -Path C:\ITTage\oracleSysCredential.xml
$csb = [Oracle.ManagedDataAccess.Client.OracleConnectionStringBuilder]::new()
$csb['Data Source'] = 'doc-db/xepdb1'
$csb['User ID'] = $credential.UserName
$csb['Password'] = $credential.GetNetworkCredential().Password
$csb['DBA Privilege'] = 'SYSDBA'
$connection = [Oracle.ManagedDataAccess.Client.OracleConnection]::new($csb.ConnectionString)
$connection.Open()
$connection | Format-Table -Property State, DataSource, ServerVersion, PDBName, HostName, DatabaseName, InstanceName, ServiceName, ConnectionString


# Damit wir das nicht immer tippen müssen, kommt der Code in eine Funktion, die wir dann "laden":
. C:\ITTage\PowerShell-for-DBAs\Oracle\Connect-OraInstance.ps1

$connection = Connect-OraInstance -Instance doc-db/xepdb1 -Credential $credential -AsSysdba
$connection | Format-Table -Property State, DataSource, ServerVersion, PDBName, HostName, DatabaseName, InstanceName, ServiceName, ConnectionString


# Das Abfragen von Daten benötigt noch etwas mehr Code, daher laden wir gleich die passende Funktion:
. C:\ITTage\PowerShell-for-DBAs\Oracle\Invoke-OraQuery.ps1

$data = Invoke-OraQuery -Connection $connection -Query 'SELECT * FROM dba_users'
$data | ogv

# Mit Bind-Parmetern:
$data = Invoke-OraQuery -Connection $connection -Query 'SELECT * FROM dba_users WHERE account_status = :status' -ParameterValues @{ status = 'OPEN' }
$data | Format-Table -Property username, created


# Was kommt denn da eigentlich?
$data[0].GetType().FullName

# Alternative:
$dataSet = Invoke-OraQuery -Connection $connection -Query 'SELECT * FROM dba_users' -As DataSet
$dataSet.GetType().FullName  # System.Data.DataSet

$dataSet.Tables.Count
$dataSet.Tables[0].GetType().FullName  # System.Data.DataTable

$dataSet.Tables[0].Rows.Count
$dataSet.Tables[0].Rows[0].GetType().FullName  # System.Data.DataRow

$dataSet.Tables[0].Rows[0] | fl *  # So werden die zusätzlichen Attribute angezeigt: RowError, RowState, Table, ItemArray, HasErrors


# Und wenn es nur eine Spalte gibt:
$username = Invoke-OraQuery -Connection $connection -Query 'SELECT username FROM dba_users' -As SingleValue
$username.GetType().FullName
$username[0].GetType().FullName


# Damit gehen auch DML und sogar PL/SQL-Blöcke bzw. Transact-SQL-Blöcke
