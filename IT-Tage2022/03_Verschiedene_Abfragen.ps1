# Erste echte Abfragen am Beispiel vom SQL Server

# Das First Responder Kit
# https://github.com/BrentOzarULTD/SQL-Server-First-Responder-Kit
# https://raw.githubusercontent.com/BrentOzarULTD/SQL-Server-First-Responder-Kit/dev/Install-Core-Blitz-No-Query-Store.sql

. C:\ITTage\PowerShell-for-DBAs\SQLServer\Connect-SqlInstance.ps1
. C:\ITTage\PowerShell-for-DBAs\SQLServer\Invoke-SqlQuery.ps1

$sqlCredential = Get-Credential -Message 'Zugang zum SQL Server' -UserName sa
$sqlConnection = Connect-SqlInstance -Instance doc-db -Credential $sqlCredential

$frkInstall = Invoke-WebRequest -Uri https://raw.githubusercontent.com/BrentOzarULTD/SQL-Server-First-Responder-Kit/dev/Install-Core-Blitz-No-Query-Store.sql -UseBasicParsing
$frkQueries = ([regex]'(?smi)^[\s]*GO[\s]*$').Split($frkInstall.Content) | Where-Object { $_.Trim().Length -gt 0 }
foreach ($query in $frkQueries) {
    Invoke-SqlQuery -Connection $sqlConnection -Query $query
}

$blitzOutput = Invoke-SqlQuery -Connection $sqlConnection -Query 'sp_Blitz @CheckServerInfo = 1'
$blitzOutput | ogv

$report = $blitzOutput | 
    Where-Object Priority -notin 0, 254, 255 | 
    Select-Object -Property Priority, FindingsGroup, Finding, DatabaseName, Details |
    Out-GridView -Title 'sp_Blitz - Bitte die zu besprechenden Zeilen auswählen' -OutputMode Multiple

$report | Format-Table

# Invoke-SqlQuery kann auch Skripte ausführen, aber nur einen Batch auf einmal. Unterteilung des Skriptes in Batches mit Code aus dbatools.
# Out-GridView kann mit OutputMode zur Benutzerinteraktion genutzt werden.

$blitzFirstOutput = Invoke-SqlQuery -Connection $sqlConnection -Query 'sp_BlitzFirst @ExpertMode = 1'
# Keine Ausgabe...

$blitzFirstOutput = Invoke-SqlQuery -Connection $sqlConnection -Query 'sp_BlitzFirst @ExpertMode = 1' -As DataSet
$blitzFirstOutput.Tables.Count  # Es kommen 7 Tabellen zurück

$blitzFirstOutput.Tables[0] # Zu Beginn laufende Statements
$blitzFirstOutput.Tables[1] | Where-Object Priority -eq 250 | Select-Object -Property Finding, DetailsInt
$blitzFirstOutput.Tables[2] | ogv  # WAIT STATS
$blitzFirstOutput.Tables[3] | ogv  # PHYSICAL WRITES / PHYSICAL READS
$blitzFirstOutput.Tables[4] | ogv  # PERFMON
$blitzFirstOutput.Tables[5]        # Plan Cache
$blitzFirstOutput.Tables[6] # An Ende laufende Statements


Add-Type -Path C:\oracle\product\19.0.0\client_1\odp.net\managed\common\Oracle.ManagedDataAccess.dll
. C:\ITTage\PowerShell-for-DBAs\Oracle\Connect-OraInstance.ps1
. C:\ITTage\PowerShell-for-DBAs\Oracle\Invoke-OraQuery.ps1

$oraCredential = Get-Credential -Message 'Zugang zu Oracle' -UserName sys
$oraConnection = Connect-OraInstance -Instance doc-db/xepdb1 -Credential $oraCredential -AsSysdba

Invoke-OraQuery -Connection $oraConnection -Query "CREATE TABLE perf (instance VARCHAR2(20), timestamp DATE, counter VARCHAR2(100), value NUMBER)"
$insertQuery = "INSERT INTO perf VALUES (:instance, :timestamp, :counter, :value)"

foreach ($perf in ($blitzFirstOutput.Tables[1] | Where-Object Priority -eq 250)) {
    # $perf = $blitzFirstOutput.Tables[1] | Where-Object Priority -eq 250 | Select-Object -First 1
    $parameterValues = @{
        instance  = 'doc-db'
        timestamp = Get-Date
        counter   = $perf.Finding
        value     = $perf.DetailsInt
    }
    Invoke-OraQuery -Connection $oraConnection -Query $insertQuery -ParameterValues $parameterValues
}

# Kontrolle:
Invoke-OraQuery -Connection $oraConnection -Query "SELECT * FROM perf" 

# So können Daten aus dem SQL Server auch in Oracle gespeichert werden.



# Nutzen wir jetzt mal Oracle nicht nur als Datenspeicher, sondern schauen uns die dortige Konfiguration an.

$oraConnection1 = Connect-OraInstance -Instance doc-db/xepdb1 -Credential $oraCredential -AsSysdba
$oraConnection2 = Connect-OraInstance -Instance win-db/xepdb1 -Credential $oraCredential -AsSysdba

$param1 = Invoke-OraQuery -Connection $oraConnection1 -Query 'SELECT * FROM v$parameter'
$param2 = Invoke-OraQuery -Connection $oraConnection2 -Query 'SELECT * FROM v$parameter'

$param1.Count
$param2.Count

$paramNames = $param1.NAME + $param2.NAME | Select-Object -Unique
$paramNames.Count

$paramCompare = foreach ($name in $paramNames) {
    $output = [PSCustomObject]@{
        Name   = $name
        Value1 = $param1 | Where-Object Name -eq $name | Select-Object -ExpandProperty VALUE
        Value2 = $param2 | Where-Object Name -eq $name | Select-Object -ExpandProperty VALUE
        Diff   = $null
    }
    if ($output.Value1 -ne $output.Value2) {
        $output.Diff = $true
    }
    $output
}

$paramCompare | ogv


# Performance steigern mit Hashtables
$p1hash = @{ }
foreach ($p in $param1) {
    $p1hash[$p.NAME] = $p.VALUE
}
$p2hash = @{ }
foreach ($p in $param2) {
    $p2hash[$p.NAME] = $p.VALUE
}
$paramCompare = foreach ($name in $paramNames) {
    [PSCustomObject]@{
        Name   = $name
        Value1 = $p1hash[$name]
        Value2 = $p2hash[$name]
        Diff   = if ($p1hash[$name] -ne $p2hash[$name]) { $true }
    }
}

$paramCompare | ogv



# Index-Monitoring

# Vorab: Statistiken aktualisieren
Invoke-OraQuery -Connection $oraConnection -Query "BEGIN DBMS_STATS.GATHER_SCHEMA_STATS('STACKOVERFLOW'); END;"

# Welche Indizes haben wir denn?
$query = "SELECT * FROM dba_indexes WHERE owner = 'STACKOVERFLOW' and uniqueness = 'NONUNIQUE'"
$indexes = Invoke-OraQuery -Connection $oraConnection -Query $query
$indexes | 
    Sort-Object -Property TABLE_NAME, INDEX_NAME |
    Format-Table -Property TABLE_NAME, INDEX_NAME, LAST_ANALYZED, NUM_ROWS, VISIBILITY

# Aktivieren wir für den ersten Index mal das Monitoring:
$query = "ALTER INDEX STACKOVERFLOW.BADGES_NAME MONITORING USAGE"
Invoke-OraQuery -Connection $oraConnection -Query $query

# Wo sehen wir das?
$query = "SELECT * FROM dba_object_usage WHERE owner = 'STACKOVERFLOW'"
Invoke-OraQuery -Connection $oraConnection -Query $query

# Hier ist jetzt mal meine Empfehlung, eine komplexere Query zu erstellen, die schon in der Datenbank die benötigten Ergebnisse bereitstellt:
$query = @'
SELECT i.table_name
     , i.index_name
     , i.index_type
     , i.status
     , i.last_analyzed
     , i.visibility
     , ou.monitoring
     , ou.used
     , ou.start_monitoring
     , ou.end_monitoring
  FROM dba_indexes i
     , dba_object_usage ou
 WHERE i.owner = ou.owner (+)
   AND i.table_name = ou.table_name (+)
   AND i.index_name = ou.index_name (+)
   AND i.owner = 'STACKOVERFLOW'
   AND i.uniqueness = 'NONUNIQUE'
'@
$indexInfo = Invoke-OraQuery -Connection $oraConnection -Query $query
$indexInfo | ft

$enableMonitoring = $indexInfo | Where-Object MONITORING -in $null, 'NO' | Out-GridView -Title 'Bei welchen Indizes soll das Monitoring aktiviert werden?' -OutputMode Multiple
foreach ($index in $enableMonitoring) {
    Write-Host "Aktiviere Monitoring für Index $($index.INDEX_NAME) auf Tabelle $($index.TABLE_NAME)"
    Invoke-OraQuery -Connection $oraConnection -Query "ALTER INDEX STACKOVERFLOW.$($index.INDEX_NAME) MONITORING USAGE"
}

$disableMonitoring = $indexInfo | Where-Object MONITORING -eq 'YES' | Out-GridView -Title 'Bei welchen Indizes soll das Monitoring deaktiviert werden?' -OutputMode Multiple
foreach ($index in $disableMonitoring) {
    Write-Host "Deaktiviere Monitoring für Index $($index.INDEX_NAME) auf Tabelle $($index.TABLE_NAME)"
    Invoke-OraQuery -Connection $oraConnection -Query "ALTER INDEX STACKOVERFLOW.$($index.INDEX_NAME) NOMONITORING USAGE"
}

# Index nutzen
$null = Invoke-OraQuery -Connection $oraConnection -Query "SELECT COUNT(*) FROM stackoverflow.comments WHERE score < 100"

# Status abfragen
$indexInfo = Invoke-OraQuery -Connection $oraConnection -Query $query
$indexInfo | ft
$filter = { $_.MONITORING -eq 'YES' -and $_.USED -eq 'NO' -and $_.START_MONITORING -lt [datetime]::UtcNow.AddMinutes(-1) }
$indexInfo | Where-Object $filter  | ft

# Jetzt könnte diese Information genutzt werden, um bestimmte Indizes "auf den Prüfstand zu stellen"...


# Gehen wir mal wieder zurück zum SQL Server und schauen und das Thema Index-Wartung an.


# Wichtig: Verbindung zur Zieldatenbank
$sqlConnection = Connect-SqlInstance -Instance doc-db -Credential $sqlCredential -Database StackOverflow

$fragmentQuery1 = @'
SELECT object_name(ips.object_id) AS table_name
     , ips.index_id 
	 , i.name AS index_name
	 , ips.index_type_desc
	 , ips.alloc_unit_type_desc
	 , ips.page_count
	 , ips.record_count
	 , CAST(ips.avg_page_space_used_in_percent AS INT) AS avg_page_space_used_in_percent
	 , CAST((1 - ips.avg_page_space_used_in_percent/100) * 8096 AS INT) AS avg_free_space_in_bytes
	 , CAST(ips.avg_fragmentation_in_percent AS INT) AS avg_fragmentation_in_percent
  FROM sys.dm_db_index_physical_stats(db_id(), NULL, NULL, NULL, 'SAMPLED') ips
  JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
 WHERE ips.page_count > 10 /* eigentlich: 1000 */
'@

$fragmentQuery2 = @'
SELECT object_name(p.object_id) AS table_name
     , p.index_id
	 , i.name AS index_name
	 , bd.page_type
	 , COUNT(*) AS pages
	 , SUM(bd.row_count) AS rows
	 , CAST(AVG(bd.free_space_in_bytes) AS INT) AS avg_free_space_in_bytes
	 , CAST((8096 - AVG(bd.free_space_in_bytes)) * 100 / 8096 AS INT) AS avg_page_space_used_in_percent
  FROM sys.dm_os_buffer_descriptors bd
  JOIN sys.allocation_units au ON bd.allocation_unit_id = au.allocation_unit_id
  JOIN sys.partitions p ON au.container_id = p.hobt_id
  JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id
 WHERE bd.database_id = db_id('StackOverflow') 
 GROUP BY p.object_id
        , p.index_id
	    , i.name
		, bd.page_type
HAVING COUNT(*) > 10 /* eigentlich: 1000 */
'@

$fragmentInfo1 = Invoke-SqlQuery -Connection $sqlConnection -Query $fragmentQuery1
$fragmentInfo2 = Invoke-SqlQuery -Connection $sqlConnection -Query $fragmentQuery2

$fragmentInfo1 | ogv
$fragmentInfo2 | ogv


$defragment = $fragmentInfo1 | Out-GridView -Title 'Bitte die zu reorganisierenden Indizes wählen' -OutputMode Multiple

# Jetzt wollen wir alle ausgewählten Indizes neu aufbauen und dabei einen Fortschrittsbalken anzeigen

# Activity ist Pflichtfeld
# Status hat den Default "Processing"
Write-Progress -Activity Activity -Status Status -Id 1 -PercentComplete 30 -SecondsRemaining 20 -CurrentOperation CurrentOperation
Start-Sleep -Seconds 30
Write-Progress -Activity Activity -Status Status -Id 1 -PercentComplete 30 -SecondsRemaining 20
Start-Sleep -Seconds 30
Write-Progress -Activity Activity 
Start-Sleep -Seconds 30

# Für die Prozentangabe brauchen wir die 100% und den aktuellen Fortschritt.
# Für die Restzeit brauchen wir die Anfangszeit, die aktuelle Zeit und den aktuellen Fortschritt.
# Der Status sollte uns sagen, welches Objekt gerade verarbeitet wird.

$defragment = $defragment | Sort-Object -Property page_count -Descending

$progressParameter = @{ Id = 1 ; Activity = 'Reorganisiere ausgewählte Indizes' }
$progressIndexTotal = $defragment.Count
$progressIndexCompleted = 0 
$progressPagesTotal = ($defragment | Measure-Object -Property page_count -Sum).Sum
$progressPagesCompleted = 0 
$progressStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

foreach ($index in $defragment) {
    # $index = $defragment[0]
    
    $progressParameter.PercentComplete = [int]($progressPagesCompleted * 100 / $progressPagesTotal)
    $progressParameter.Status = "$($progressIndexCompleted) von $($progressIndexTotal) Indizes wurden reorganisiert ($($progressParameter.PercentComplete)%)"
    $progressParameter.CurrentOperation = "Reorganisiere Index $($index.index_name)"
    if ($progressParameter.PercentComplete -gt 10) {
        $progressParameter.SecondsRemaining = $progressStopwatch.Elapsed.TotalSeconds * ($progressPagesTotal - $progressPagesCompleted) / $progressPagesCompleted
    }

    Write-Progress @progressParameter
    $progressIndexCompleted++
    $progressPagesCompleted += $index.page_count

    Start-Sleep -Seconds (($index.page_count / $progressPagesTotal) * 10)
}
Write-Progress @progressParameter -Completed
Start-Sleep -Seconds 10


# Um auch mal was mit MySQL zu machen:
# Welche .NET-Version haben wir denn?
[System.Runtime.InteropServices.RuntimeInformation]::FrameworkDescription

try { Add-Type -Path C:\ITTage\NuGet\MySql.Data\lib\net48\MySql.Data.dll } catch { $ex = $_ }
$ex.Exception.LoaderExceptions
# Could not load file or assembly 'Google.Protobuf, Version=3.19.4.0

. C:\ITTage\PowerShell-for-DBAs\MySQL\Connect-MyInstance.ps1
. C:\ITTage\PowerShell-for-DBAs\MySQL\Invoke-MyQuery.ps1

$myCredential = Get-Credential -Message 'Zugang zu MySQL' -UserName stackoverflow
$myConnection = Connect-MyInstance -Instance doc-db -Credential $myCredential -Database stackoverflow

# Liste der Tabellen:
$tableNames = Invoke-MyQuery -Connection $myConnection -Query "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_SCHEMA = 'stackoverflow'" -As SingleValue

foreach ($tableName in $tableNames) {
    # $tableName = $tableNames[1]
    Invoke-MyQuery -Connection $myConnection -Query "SELECT MAX(creationdate) FROM $tableName" -As SingleValue
}

# Alle Tabellen werden verarbeitet, die Tabewllen ohne Spalte "creationdate" erzeugen eine Warnung.


foreach ($tableName in $tableNames) {
    # $tableName = $tableNames[1]
    Invoke-MyQuery -Connection $myConnection -Query "SELECT MAX(creationdate) FROM $tableName" -As SingleValue -EnableException
}

# Jetzt wird sofort abgebrochen.
# Der Fehler steht auch im Fehler-Array $Error
$Error.Count
$Error[0]
$Error[1].TargetObject
$Error[1].TargetObject.GetType().FullName # MySql.Data.MySqlClient.MySqlCommand
# Hiermit können die Abfrage und auch die verwendeten Parameter engezeigt werden.
# Voraussetzung: PowerShell-Session ist noch da.


Import-Module -Name PSFramework

foreach ($tableName in $tableNames) {
    # $tableName = $tableNames[1]
    try {
        $query = "SELECT MAX(creationdate) FROM $tableName"
        Invoke-MyQuery -Connection $myConnection -Query $query -As SingleValue -EnableException
    } catch {
        #Write-PSFMessage -Level Warning -Message "Abfrage auf Tabelle '$tableName' konnte nicht ausgeführt werden: $_" -Target $tableName
        Write-PSFMessage -Level Warning -Message "Abfrage auf Tabelle '$tableName' konnte nicht ausgeführt werden: $_" -Data @{ Query = $query ; TableName = $tableName }
    }
}

Get-PSFMessage | Select-Object -Last 1 | Format-List *

Get-PSFConfig | Where-Object Value -like C:\* | Format-List -Property FullName, Value, Description

# Hier liegen die Logging-Daten, bleibt auch beim Schließen der PowerShell-Session erhalten:
Invoke-Item -Path (Get-PSFConfigValue -FullName PSFramework.Logging.FileSystem.LogPath)

# Aber Achtung: Es wird nicht alles gespeichert. So fehlt der "Data"-Teil.


foreach ($tableName in $tableNames) {
    # $tableName = $tableNames[1]
    try {
        $query = "SELECT MAX(creationdate) FROM $tableName"
        Invoke-MyQuery -Connection $myConnection -Query $query -As SingleValue -EnableException
    } catch {
        #Write-PSFMessage -Level Error -Message "Abfrage auf Tabelle '$tableName' konnte nicht ausgeführt werden: $_" -Data @{ Query = $query ; TableName = $tableName } -ErrorRecord $_
        Write-PSFMessage -Level Warning -Message "Abfrage auf Tabelle '$tableName' konnte nicht ausgeführt werden" -ErrorRecord $_
    }
}

# Die vom Framework gesicherten Fehler können auch wieder eingelesen werden:
$savedEx = Import-PSFClixml -Path C:\Users\User\AppData\Roaming\WindowsPowerShell\PSFramework\Logs\WIN-CL_4496_error_20.xml
$savedEx.TargetObject

