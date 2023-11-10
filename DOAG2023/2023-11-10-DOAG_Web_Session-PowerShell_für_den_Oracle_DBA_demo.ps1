throw "Dies ist kein komplettes Skript und darf daher nicht mit F5 aufgeführt werden. Bitte F8 verwenden."


#region *** Einrichtung der PowerShell Session *** 

# Der Pfad zum Oracle Client muss entsprechend angepasst werden.
# Die Dateien Connect-OraInstance.ps1 und Invoke-OraQuery.ps1 sind hier abgelegt:
# https://github.com/andreasjordan/PowerShell-for-DBAs/tree/main/Oracle

Add-Type -Path C:\oracle\product\19.0.0\client_1\odp.net\managed\common\Oracle.ManagedDataAccess.dll
Set-Location -Path C:\oraPwsh
. .\Connect-OraInstance.ps1
. .\Invoke-OraQuery.ps1


#endregion





#region *** Einrichtung der Verbindung zur Instanz mit Connect-OraInstance *** 


$instance = 'DEMO'  # Alternative ohne TNS: $instance = '192.168.101.30/xepdb1'
$credential = Get-Credential -Message $instance -UserName sys

$connection = Connect-OraInstance -Instance $instance -Credential $credential -AsSysdba


#endregion





#region *** Abfrage von Daten mit Invoke-OraQuery *** 


$query = 'SELECT * FROM v$parameter'

$data = Invoke-OraQuery -Connection $connection -Query $query

$data | Out-GridView -Title $query

# Zeigen: Filter auf "optimi" wirkt auf alle Spalten


#endregion





#region *** Abgleich von Daten aus verschiedenen Quellen mit lokalen Referenzwerten *** 


Clear-Host
$target = Get-Content -Path .\target_parameter.json.txt | ConvertFrom-Json
$parameter = @{ }
foreach ($instance in 'Test01', 'Test02', 'Prod') {
    $connection = Connect-OraInstance -Instance $instance -Credential $credential -AsSysdba
    $parameter[$instance] = Invoke-OraQuery -Connection $connection -Query 'SELECT * FROM v$parameter'
    $connection.Dispose()
}

$comparison = foreach ($param in $target) {
    $output = [PSCustomObject]@{
        ParameterName = $param.NAME
        TargetValue   = $param.VALUE
        Status        = $null
    }
    foreach ($instance in $parameter.Keys) {
        $value = ($parameter[$instance] | Where-Object NAME -eq $param.NAME).VALUE
        Add-Member -InputObject $output -NotePropertyName $instance -NotePropertyValue $value
        if ($value -ne $param.VALUE) { $output.Status = 'Abweichung' }
    }
    $output
}

$comparison | Where-Object Status -eq 'Abweichung' | Format-Table
$comparison | Out-GridView -Title 'Abgleich'


#endregion





# Hier geht es erstmal wieder zu den Folien ...




#region *** Schleifen *** 


# Beispiel: Aktualisierung der Statistiken. Iterative Abfrage der zu bearbeitenden Objekte und Verlaufsanzeige.

# Ermittlung der benötigten Daten:

$connection = Connect-OraInstance -Instance DEMO -Credential $credential -AsSysdba
$dbaTables = Invoke-OraQuery -Connection $connection -Query 'SELECT * FROM dba_tables'
$dbaTables | Where-Object OWNER -eq STACKOVERFLOW | Format-Table -Property OWNER, TABLE_NAME, LAST_ANALYZED

# Zweistufige Auswahl der zu bearbeitenden Tabellen:

$owners = $dbaTables | Select-Object -ExpandProperty OWNER -Unique | Sort-Object
$selectedOwners = $owners | Out-GridView -OutputMode Multiple

$tables = $dbaTables | Where-Object OWNER -in $selectedOwners
$selectedTables = $tables | Select-Object -Property OWNER, TABLE_NAME, LAST_ANALYZED | Out-GridView -OutputMode Multiple

# Einrichtung des Fortschrittsbalkens

Clear-Host
$progressParameter = @{ Activity = 'Updating statistics for selected tables' }
$progressTotal = $selectedTables.Count
$progressCompleted = 0 
$progressStart = Get-Date

# Start der Schleife

foreach ($table in $selectedTables) {
    # $table = $selectedTables[0]

    # Aktualisierung des Fortschrittsbalkens

    $progressParameter.Status = "$progressCompleted of $progressTotal tables completed"
    $progressParameter.CurrentOperation = "processing owner $($table.OWNER), processing table $($table.TABLE_NAME)"
    $progressParameter.PercentComplete = $progressCompleted * 100 / $progressTotal
    if ($progressParameter.PercentComplete -gt 0) {
        $progressParameter.SecondsRemaining = ((Get-Date) - $progressStart).TotalSeconds / $progressParameter.PercentComplete * (100 - $progressParameter.PercentComplete)
    }
    Write-Progress @progressParameter
    $progressCompleted++

    # Durchführung der Aktion

    $query = "begin dbms_stats.gather_table_stats('$($table.OWNER)', '$($table.TABLE_NAME)'); end;"
    Invoke-OraQuery -Connection $connection -Query $query
    
    # Nur damit die Demo nicht so schnell läuft: Unnötig warten

    Start-Sleep -Seconds 5

}

# Wichtig, falls das Skript weiteren Code enthält: Fortschrittsbalken entfernen

Write-Progress @progressParameter -Completed


#endregion





#region *** Fehlerbehandlung *** 


# Beispiel: Aus allen Tabellen den Zeitpunkt des letzten Datensatzes anhand des CreationDate ermitteln.

# Ermittlung der Tabellen:

$connection = Connect-OraInstance -Instance DEMO -Credential $credential -AsSysdba
$tableNames = Invoke-OraQuery -Connection $connection -Query "SELECT table_name FROM dba_tables WHERE owner = 'STACKOVERFLOW'" -As SingleValue

# Einmal den Fehler und die Wirkung von EnableException zeigen
$query = "SELECT MAX(CreationDate) FROM stackoverflow.LINKTYPES"
Invoke-OraQuery -Connection $connection -Query $query -As SingleValue
Invoke-OraQuery -Connection $connection -Query $query -As SingleValue -EnableException

# Start der Schleife

Clear-Host
$maxCreationDate = @{ }
$currentErrorCount = 0
$maxErrorCount = 5  # später auf 2 setzen, um Verarbeitung abzubrechen
foreach ($tableName in $tableNames) {
    # $tableName = $tableNames[0]

    $query = "SELECT MAX(CreationDate) FROM stackoverflow.$tableName"
    try {
        $maxCreationDate.$tableName = Invoke-OraQuery -Connection $connection -Query $query -As SingleValue -EnableException
    } catch {
        $ex = $_
        $currentErrorCount++
        Write-Warning -Message "Failure for table $($tableName): $ex"
        
        if ($currentErrorCount -gt $maxErrorCount) {
            throw "Too many errors"
        }
    }
}
$maxCreationDate


#endregion





#region *** Logging *** 


# Beispiel: Aus allen Tabellen den Zeitpunkt des letzten Datensatzes anhand des CreationDate ermitteln.

# Install-Module –Name PSFramework -Scope CurrentUser
Import-Module -Name PSFramework

Write-PSFMessage -Level Verbose -Message "Ermittlung der Tabellen"
$connection = Connect-OraInstance -Instance DEMO -Credential $credential -AsSysdba
$tableNames = Invoke-OraQuery -Connection $connection -Query "SELECT table_name FROM dba_tables WHERE owner = 'STACKOVERFLOW'" -As SingleValue

# Start der Schleife

Clear-Host
$maxCreationDate = @{ }
$currentErrorCount = 0
$maxErrorCount = 5  # später auf 2 setzen, um Verarbeitung abzubrechen
Write-PSFMessage -Level Debug -Message "maxErrorCount = $maxErrorCount"

Write-PSFMessage -Level Verbose -Message "Verarbeite $($tableNames.Count) Tabellen"
foreach ($tableName in $tableNames) {
    # $tableName = $tableNames[0]

    # Durchführung der Aktion

    $query = "SELECT MAX(CreationDate) FROM stackoverflow.$tableName"
    try {
        Write-PSFMessage -Level Debug -Message "Running query: $query"
        $maxCreationDate.$tableName = Invoke-OraQuery -Connection $connection -Query $query -As SingleValue -EnableException
    } catch {
        $ex = $_
        $currentErrorCount++
        Write-PSFMessage -Level Warning -Message "Failure for table $($tableName): $ex"

        if ($currentErrorCount -gt $maxErrorCount) {
            Stop-PSFFunction -Level Error -Message "Too many errors" -EnableException $true
        }
    }
}
$maxCreationDate

# Anzeige der Meldungen

Get-PSFMessage | Out-GridView
Get-PSFConfigValue -FullName psframework.logging.filesystem.logpath | Invoke-Item


#endregion





# Hier geht es erstmal wieder zu den Folien um den Export von Daten nach Excel mit ImportExcel zu zeigen ...





#region *** Export von Daten nach Excel mit ImportExcel *** 


# Install-Module -Name ImportExcel -Scope CurrentUser
Import-Module -Name ImportExcel

$connection = Connect-OraInstance -Instance DEMO -Credential $credential -AsSysdba
$data = Invoke-OraQuery -Connection $connection -Query 'SELECT * FROM v$parameter'

$excelParams = @{
    Path          = 'parameter.xlsx'
    WorksheetName = 'v$parameter'
    TableStyle    = 'Light18'
    AutoSize      = $true
    FreezeTopRow  = $true
}
$data | Export-Excel @excelParams


#endregion





#region *** Export von Daten nach JSON mit ConvertTo-Json *** 


$folder = "$env:TEMP\json"
$null = New-Item -Path $folder -ItemType Directory

$filename = "$folder\parameter_json.txt"

$data = Invoke-OraQuery -Connection $connection -Query 'SELECT * FROM v$parameter'

$data | ConvertTo-Json | Set-Content -Path $filename
& $filename

$readData = Get-Content -Path $filename | ConvertFrom-Json
$readData | Out-GridView

Remove-Item -Path $folder -Recurse -Force


#endregion






#region *** Verarbeitung von CLOBs (Teil 1: body_of_a_post) *** 


$folder = "$env:TEMP\clob_html"
$null = New-Item -Path $folder -ItemType Directory

$filename = "$folder\body_of_a_post.htm"

$data = Invoke-OraQuery -Connection $connection -Query "SELECT * FROM stackoverflow.posts WHERE id = 3049"

$data.BODY.Length  # 14163 Zeichen
$data.BODY | Set-Content -Path $filename -Encoding UTF8
& $filename

Remove-Item -Path $folder -Recurse -Force


#endregion





#region *** Verarbeitung von CLOBs (Teil 2: Daten aus v$sql abfragen) *** 


$folder = "$env:TEMP\sql"
$null = New-Item -Path $folder -ItemType Directory

$data = Invoke-OraQuery -Connection $connection -Query 'SELECT * FROM v$sql'
$data | Select-Object -Property SQL_ID, LAST_ACTIVE_TIME, ELAPSED_TIME, CPU_TIME, SQL_FULLTEXT | Out-GridView

$exportData = $data | Where-Object SQL_FULLTEXT -Match 'stackoverflow' | Sort-Object -Property CPU_TIME -Descending | Select-Object -First 10
foreach ($sql in $exportData) {
    # $sql = $exportData[0]

    $filename = "$folder\$($sql.CPU_TIME.ToString('0000000000'))_$($sql.SQL_ID).txt"
    $sql.SQL_FULLTEXT | Set-Content -Path $filename
}
Invoke-Item $folder

Remove-Item -Path $folder -Recurse -Force


#endregion





#region *** Verarbeitung von CLOBs (Teil 3: Daten aus v$sql in Tabelle speichern mit Bind-Variablen) *** 


$createTableSql = "CREATE TABLE exportsql ( sql_id VARCHAR2(13), last_active_time DATE, elapsed_time NUMBER, cpu_time NUMBER, sql_fulltext CLOB)"
$insertIntoSql  = "INSERT INTO  exportsql ( sql_id,              last_active_time,      elapsed_time,        cpu_time,        sql_fulltext     ) "
$insertIntoSql += "VALUES                 (:sql_id,             :last_active_time,     :elapsed_time,       :cpu_time,       :sql_fulltext     )"

Invoke-OraQuery -Connection $connection -Query $createTableSql

$data = Invoke-OraQuery -Connection $connection -Query 'SELECT sql_id, last_active_time, elapsed_time, cpu_time, sql_fulltext FROM v$sql'

foreach ($sql in $data) {
    # $sql = $data[0]

    $insertParameter = @{
        sql_id           = $sql.SQL_ID
        last_active_time = $sql.LAST_ACTIVE_TIME
        elapsed_time     = $sql.ELAPSED_TIME
        cpu_time         = $sql.CPU_TIME
        sql_fulltext     = $sql.SQL_FULLTEXT
    }
    Invoke-OraQuery -Connection $connection -Query $insertIntoSql -ParameterValues $insertParameter
}

Invoke-OraQuery -Connection $connection -Query "SELECT * FROM exportsql" | Out-GridView

Invoke-OraQuery -Connection $connection -Query "DROP TABLE exportsql" 


#endregion





#region *** Verarbeitung von BLOBs *** 


$createTableSql = "CREATE TABLE jpg ( filename VARCHAR2(500), jpg BLOB)"
$insertIntoSql  = "INSERT INTO  jpg ( filename,               jpg     ) "
$insertIntoSql += "VALUES           (:filename,              :jpg     )"

Invoke-OraQuery -Connection $connection -Query $createTableSql

$jpgs = Get-ChildItem -Path C:\oracle -Filter *.jpg -Recurse

foreach ($jpg in $jpgs) {
    # $jpg = $jpgs[0]

    $insertParameter = @{
        filename = $jpg.FullName
        jpg      = Get-Content -Path $jpg.FullName -Raw -Encoding Byte
    }
    $insertParameterTypes = @{
        jpg      = 'BLOB'
    }
    Invoke-OraQuery -Connection $connection -Query $insertIntoSql -ParameterValues $insertParameter -ParameterTypes $insertParameterTypes
}

$export = Invoke-OraQuery -Connection $connection -Query "SELECT * FROM jpg" | Out-GridView -OutputMode Single
$export.JPG | Set-Content -Path export.jpg -Encoding Byte
Invoke-Item -Path export.jpg

Invoke-OraQuery -Connection $connection -Query "DROP TABLE jpg" 


#endregion


