# Einführung in das PowerShell-Modul dbatools
# https://dbatools.io/

Import-Module -Name dbatools

$credential = Get-Credential -Message 'Verbindung zum SQL Server' -UserName sa
$server1 = Connect-DbaInstance -SqlInstance doc-db -SqlCredential $credential 
$server2 = Connect-DbaInstance -SqlInstance win-db\sqlexpress

$server1, $server2 | Format-Table

$server1.GetType().FullName  # Microsoft.SqlServer.Management.Smo.Server
$server1 | Get-Member | Out-GridView

$logins = $server1.Logins
$logins.Count
$logins | Format-Table
$logins | Get-Member | Out-GridView
$propertiesToShow = $logins | Get-Member -MemberType Property | Out-GridView -Title "Welche Eigenschaften sollen für alle Logins gezeigt werden" -OutputMode Multiple
$logins | Format-Table -Property $propertiesToShow.Name
$oneLogin = $logins | Where-Object Name -eq 'StackOverflow'
$oneLogin.IsDisabled  # False

$oneLogin.IsDisabled = $true  # 'IsDisabled' is a ReadOnly property.
$oneLogin.Disable()
Connect-DbaInstance -SqlInstance doc-db -SqlCredential StackOverflow  # geht nicht
$oneLogin.Enable()
Connect-DbaInstance -SqlInstance doc-db -SqlCredential StackOverflow  # geht wieder

Set-DbaLogin -SqlInstance $server1 -Login StackOverflow -Disable
Connect-DbaInstance -SqlInstance doc-db -SqlCredential StackOverflow  # geht nicht
Set-DbaLogin -SqlInstance $server1 -Login StackOverflow -Enable
Connect-DbaInstance -SqlInstance doc-db -SqlCredential StackOverflow  # geht wieder

# Alle Indizes:
$db = Get-DbaDatabase -SqlInstance win-db\sqlexpress -Database StackOverflow
$info = foreach ($table in $db.Tables) {
    # $table = $db.Tables[0]
    foreach ($index in $table.Indexes) {
        [PSCustomObject]@{
            TableName = $table.Name
            IndexName = $index.Name
            SpaceUsed = $index.SpaceUsed
            DataSpaceUsed = $table.DataSpaceUsed
            IndexSpaceUsed = $table.IndexSpaceUsed
        }
    }
}
$info | Format-Table

Invoke-DbaQuery -SqlInstance win-db\sqlexpress -Database StackOverflow -Query "CREATE TABLE HeapTest (Text CHAR(500))"
1..100 | % { Invoke-DbaQuery -SqlInstance win-db\sqlexpress -Database StackOverflow -Query "INSERT INTO HeapTest VALUES ('Text')" }



# Beispiel: Neuaufbau aller Indizes, um Prüfsummen anzulegen:
$instance = 'win-db\sqlexpress'
$database = 'StackOverflow'

$logfile = "C:\ITTage\IndexRebuild_$($instance.Replace('\','_'))_$database.txt"

"$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))  Starte Verarbeitung für Datenbank $database auf Instanz $instance" | Set-Content -Path $logfile

# Verbindung zur Datenbank herstellen
$db = Get-DbaDatabase -SqlInstance $instance -Database $database

# Seitenprüfsumme einschalten
$db.PageVerify = 'Checksum'
$db.Alter()

$db.Tables.ClearAndInitialize('', [string[]]('Schema', 'Name', 'HasClusteredIndex', 'DataSpaceUsed', 'IndexSpaceUsed'))

$countTarget = 0
$spaceUsedTarget = 0
foreach ($table in $db.Tables) {
    $countTarget++
    $spaceUsedTarget += $table.DataSpaceUsed + $table.IndexSpaceUsed
}

$count = 1
$spaceUsed = 0
# Alle Indizes neu aufbauen
foreach ($table in $db.Tables) {
    # $table = $tables | Select-Object -First 1

    Write-Progress -Activity "Neuaufbau aller Indizes in Datenbank $database" -Status "Tabelle [$($table.Schema)].[$($table.Name)] ($count von $countTarget)" -PercentComplete ($spaceUsed * 100 / $spaceUsedTarget)
    $count++
    $spaceUsed += $table.DataSpaceUsed + $table.IndexSpaceUsed

    "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))  Starte Verarbeitung für Tabelle [$($table.Schema)].[$($table.Name)] ($(($table.DataSpaceUsed + $table.IndexSpaceUsed)/1024) MB)" | Add-Content -Path $logfile
    
    # Alle Indizes werden ermittelt, aber der Clustered Index wird zuerst verarbeitet
    $indexes = $table.Indexes
    $indexes.ClearAndInitialize('', [string[]]('Name', 'IsClustered', 'SpaceUsed'))
    $clusteredIndex = $indexes | Where-Object IsClustered
    $indexes = $indexes | Where-Object IsClustered -eq $false

    if ($clusteredIndex) {
        "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))  Starte Rebuild für Clustered Index [$($clusteredIndex.Name)] ($(($clusteredIndex.SpaceUsed + $table.DataSpaceUsed)/1024) MB)" | Add-Content -Path $logfile
        $clusteredIndex.Rebuild()
    } else {
        # Wenn es keinen Clustered Index gibt, dann muss temporär einer erstellt werden. 
        # Dazu wird immer die erste Spalte genutzt.
        "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))  Erstelle Clustered Index" | Add-Content -Path $logfile
        $db | Invoke-DbaQuery -Query "CREATE CLUSTERED INDEX JustForRebuildOfTable ON [$($table.Schema)].[$($table.Name)] ($($table.Columns[0].Name))" -QueryTimeout 0
        "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))  Entferne Clustered Index" | Add-Content -Path $logfile
        $db | Invoke-DbaQuery -Query "DROP INDEX JustForRebuildOfTable ON [$($table.Schema)].[$($table.Name)]" -QueryTimeout 0
    }

    foreach ($index in $indexes) {
        # $index = $indexes | Select-Object -First 1
        "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))  Starte Rebuild für Index [$($index.Name)] ($($index.SpaceUsed/1024) MB)" | Add-Content -Path $logfile
        $index.Rebuild()
    }
}

"$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))  Rebuilds abgeschlossen" | Add-Content -Path $logfile


