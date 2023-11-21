$ErrorActionPreference = 'Stop'
Set-Location -Path C:\demo

Get-ChildItem -Path . -Filter *-*.ps1 | ForEach-Object -Process { . .\$_ }

$credential = Get-Credential -Message 'Datenbank-Benutzer' -UserName stackoverflow

$sqlConnection = Connect-SqlInstance -Instance 192.168.101.30 -Database stackoverflow -Credential $credential
"Connected to SQL Server. Version: $($sqlConnection.ServerVersion)"

Import-OraLibrary
$oracleConnection = Connect-OraInstance -Instance DEMO -Credential $credential
"Connected to Oracle. Version: $($oracleConnection.ServerVersion)"

Get-SqlTableInformation -Connection $sqlConnection



# Version 1: Invoke-SqlQuery / Invoke-OraQuery
##############################################

$data = Invoke-SqlQuery -Connection $sqlConnection -Query "SELECT * FROM Badges"

Invoke-OraQuery -Connection $oracleConnection -Query "TRUNCATE TABLE badges"

$rowsTotal = $data.Count
$rowsCompleted = 0
$progressParam = @{ 
    Id               = Get-Random
    Activity         = "Transferting table badges"
}
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

foreach ($row in $data) {
    if ($rowsCompleted % 100 -eq 0) {
        $progressParam.Status = "$rowsCompleted of $rowsTotal rows transfered"
        $progressParam.PercentComplete = $rowsCompleted * 100 / $rowsTotal
        if ($stopwatch.Elapsed.TotalSeconds -gt 1) {
            $progressParam.SecondsRemaining = $stopwatch.Elapsed.TotalSeconds * ($rowsTotal - $rowsCompleted) / $rowsCompleted
            $progressParam.CurrentOperation = "$([int]($rowsCompleted / $stopwatch.Elapsed.TotalSeconds)) rows per second"
        }
        Write-Progress @progressParam
    }

    $invokeQueryParams = @{
        Connection      = $oracleConnection
        Query           = "INSERT INTO badges VALUES (:Id, :Name, :UserId, :CreationDate)"
        ParameterValues = @{
            Id           = $row.Id
            Name         = $row.Name
            UserId       = $row.UserId
            CreationDate = $row.CreationDate
        }
    }
    Invoke-OraQuery @invokeQueryParams

    $rowsCompleted++
}



# Version 2: Invoke-SqlQuery / Write-OraTable
#############################################

$data = Invoke-SqlQuery -Connection $sqlConnection -Query "SELECT * FROM Badges"

Write-OraTable -Connection $oracleConnection -Table badges -Data $data -TruncateTable



# Version 3: Get-SqlTableInformation + Get-SqlTableReader / Write-OraTable
##########################################################################

$tableInformation = Get-SqlTableInformation -Connection $sqlConnection -Table Badges
$dataReader = Get-SqlTableReader -Connection $sqlConnection -Table Badges

$invokeWriteTableParams = @{
    Connection         = $oracleConnection
    Table              = 'badges'
    DataReader         = $dataReader
    DataReaderRowCount = $tableInformation.Rows
    TruncateTable      = $true
}
Write-OraTable @invokeWriteTableParams





# Zusatz 1: Übertragung mehrerer Tabellen
#########################################

Clear-Host
$tables = Get-SqlTableInformation -Connection $sqlConnection -Table Badges, Comments, Posts, Users
$tablesTotal = $tables.Count
$tablesCompleted = 0
$rowsTotal = ($tables | Measure-Object -Property Rows -Sum).Sum
$rowsCompleted = 0
$pagesTotal = ($tables | Measure-Object -Property Pages -Sum).Sum
$pagesCompleted = 0
$progressParam = @{ 
    Id               = Get-Random
    Activity         = "Transfering table data"
}
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
foreach ($table in $tables) {
    $progressParam.Status = "$tablesCompleted of $tablesTotal tables transfered"
    $progressParam.PercentComplete = $rowsCompleted * 100 / $rowsTotal
    #$progressParam.PercentComplete = $pagesCompleted * 100 / $pagesTotal
    if ($stopwatch.Elapsed.TotalSeconds -gt 1) {
        $progressParam.SecondsRemaining = $stopwatch.Elapsed.TotalSeconds * ($rowsTotal - $rowsCompleted) / $rowsCompleted
        # $progressParam.SecondsRemaining = $stopwatch.Elapsed.TotalSeconds * ($pagesTotal - $pagesCompleted) / $pagesCompleted
        $progressParam.CurrentOperation = "$([int]($pagesCompleted * 8 / $stopwatch.Elapsed.TotalSeconds)) kByte per second"
    }
    Write-Progress @progressParam

    $tableStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $reader = Get-SqlTableReader -Connection $sqlConnection -Table $table.Table
    Write-OraTable -Connection $oracleConnection -Table $table.Table -DataReader $reader -DataReaderRowCount $table.Rows -TruncateTable
    $tableStopwatch.Stop()

    '{0,-12} {1,6} rows  {2,7} kBytes  {3,7} ms  {4,6} rows/sec  {5,6} kBytes/sec' -f $table.Table, $table.Rows, ($table.Pages * 8), $tableStopwatch.ElapsedMilliseconds, [int]($table.Rows * 1000 / $tableStopwatch.ElapsedMilliseconds), [int]($table.Pages * 8000 / $tableStopwatch.ElapsedMilliseconds)

    $tablesCompleted++
    $rowsCompleted += $table.Rows
    $pagesCompleted += $table.Pages
}
Write-Progress @progressParam -Completed
$stopwatch.Stop()
"Finished transfer in $($stopwatch.ElapsedMilliseconds) Milliseconds"




# Zusatz 2: Aktualisierung einer Tabelle
########################################

Invoke-SqlQuery -Connection $sqlConnection -Query "CREATE TABLE demo (object_id int IDENTITY, value1 int, value2 int, last_updated datetime2)"
Invoke-OraQuery -Connection $oracleConnection -Query "CREATE TABLE demo (object_id NUMBER(10), value1 NUMBER(10), value2 NUMBER(10), last_updated TIMESTAMP(3))"

Invoke-SqlQuery -Connection $sqlConnection -Query "INSERT INTO demo (value1, value2) VALUES (@value1, @value2)" -ParameterValues @{ value1 = 1 ; value2 = 1 }
Invoke-SqlQuery -Connection $sqlConnection -Query "INSERT INTO demo (value1, value2) VALUES (@value1, @value2)" -ParameterValues @{ value1 = 1 ; value2 = 1 }
Invoke-SqlQuery -Connection $sqlConnection -Query "INSERT INTO demo (value1, value2) VALUES (@value1, @value2)" -ParameterValues @{ value1 = 1 ; value2 = 1 }
Invoke-SqlQuery -Connection $sqlConnection -Query "UPDATE demo SET value2 = @value2, last_updated = @last_updated WHERE object_id = @object_id" -ParameterValues @{ value2 = 2 ; object_id = 2 ; last_updated = [datetime]::Now }

Invoke-SqlQuery -Connection $sqlConnection -Query "SELECT * FROM demo ORDER BY 1"

## Hier Transfer starten (0 rows changed, 3 rows added)

Invoke-SqlQuery -Connection $sqlConnection -Query "UPDATE demo SET value2 = @value2, last_updated = @last_updated WHERE object_id = @object_id" -ParameterValues @{ value2 = 3 ; object_id = 2 ; last_updated = [datetime]::Now }
Invoke-SqlQuery -Connection $sqlConnection -Query "INSERT INTO demo (value1, value2) VALUES (@value1, @value2)" -ParameterValues @{ value1 = 1 ; value2 = 1 }

## Hier Transfer starten (1 rows changed, 1 rows added)

Invoke-OraQuery -Connection $oracleConnection -Query "SELECT * FROM demo ORDER BY 1"

Invoke-SqlQuery -Connection $sqlConnection -Query "DROP TABLE demo"
Invoke-OraQuery -Connection $oracleConnection -Query "DROP TABLE demo"




#### Transfer
Clear-Host
$maxIdTarget = Invoke-OraQuery -Connection $oracleConnection -Query "SELECT NVL(MAX(object_id), 0) FROM demo" -As SingleValue
$maxChangeTimeTarget = Invoke-OraQuery -Connection $oracleConnection -Query "SELECT NVL(MAX(last_updated), SYSDATE) FROM demo" -As SingleValue
$changedRows = @( )
$changedRows += Invoke-SqlQuery -Connection $sqlConnection -Query "SELECT * FROM demo WHERE object_id <= @object_id AND last_updated >= @last_updated" -ParameterValues @{ object_id = $maxIdTarget ; last_updated = $maxChangeTimeTarget }
$newRows = @( )
$newRows += Invoke-SqlQuery -Connection $sqlConnection -Query "SELECT * FROM demo WHERE object_id > @object_id" -ParameterValues @{ object_id = $maxIdTarget }

$transaction = $oracleConnection.BeginTransaction()
foreach ($row in $changedRows) {
    Invoke-OraQuery -Connection $oracleConnection -Query "DELETE demo WHERE object_id = :object_id" -ParameterValues @{ object_id = $row.object_id }
}
Write-OraTable -Connection $oracleConnection -Table demo -Data ($changedRows + $newRows) -NoCommit
$transaction.Commit()

"$($changedRows.Count) rows changed, $($newRows.Count) rows added"
#### Transfer



# Bei der mehrmaligen Ausführung von Write-OraTable innerhalb einer Transaktion kommt es zu diesem Fehler:
# WARNING: [18:33:45][Write-OraTable] Bulk copy failed: ORA-39822: Ein neuer Direct Path-Vorgang ist in der aktuellen Transaktion nicht zulässig.
# Weiter Informationen:
# https://forums.oracle.com/ords/apexds/post/ora-39822-under-19c-but-not-under-12c-0482
