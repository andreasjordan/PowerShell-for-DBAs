$ErrorActionPreference = 'Stop'

# Anpassen, falls ein anderes Verzeichnis verwendet wird:
$basePath =  'C:\DOAG'

Set-Location -Path $basePath
. .\Import-OraLibrary.ps1
. .\Connect-OraInstance.ps1
. .\Invoke-OraQuery.ps1

# Falls die Bibliothek in das Verzeichnis kopiert wurde:
Import-OraLibrary -Path .\Oracle.ManagedDataAccess.dll
# Alternative, falls die Bibliothek automatisch von nuget.org heruntergeladen werden soll:
# Import-OraLibrary

Import-Module -Name ImportExcel


# Hier den Benutzernamen anpassen (es wird mindestens die Rolle SELECT_CATALOG_ROLE benötigt):
$credential = Get-Credential -Message 'Zugang zu Oracle' -UserName '<Benutzername anpassen>'

# Hier die Instanz angeben. Entweder einen TNS-Eintrag verwenden, oder das Schema "hostname:port/service" verwenden
$instance = "myoracleserver:1521/PDB1"

# Bei "normalen" Benutzern:
$connection = Connect-OraInstance -Instance $instance -Credential $credential
# Alternative bei der Verwendung von SYSDBA-Benutzern:
# $connection = Connect-OraInstance -Instance $instance -Credential $credential -AsSysdba



# Wenn der Code bis hierhin Zeile für Zeile ausgeführt werden kann ohne einen Fehler anzuzeigen, dann sind alle Voraussetzungen erfüllt.
# Ab hier sind Anpassungen nicht mehr notwendig aber zur Anpassung der Auswertungen möglich.



$roundingPlaces = 6

$relevantSqlPercent = 5

$excelParams = @{
    Path          = ''
    AutoSize      = $true
    AutoNameRange = $true
    TableStyle    = 'Light18'
}


function Get-MyExcelStyle {
    param(
        [object[]]$Table,
        [hashtable]$Format
    )

    foreach ($column in $Table[0].PSObject.Properties.Name) {
        if ($Format[$column]) {
            @{ Range = $column ; NumberFormat = $Format[$column] }
        }
    }
}


# Get data from database
#########################

$dbaHistSnapshot = Invoke-OraQuery -Connection $connection -Query "SELECT * FROM dba_hist_snapshot ORDER BY snap_id"
# $dbaHistSnapshot | Out-GridView

$dbaHistSqlstat = Invoke-OraQuery -Connection $connection -Query "SELECT * FROM dba_hist_sqlstat"
# $dbaHistSqlstat | Out-GridView

$dbaHistSqltext = Invoke-OraQuery -Connection $connection -Query "SELECT * FROM dba_hist_sqltext"
# $dbaHistSqltext | Out-GridView



# Enrich snapshot objects and prepare snapshot hashtable
#########################################################

$snapInfo = @{ }
foreach ($row in $dbaHistSnapshot) {
    # $row = $dbaHistSnapshot[0]

    $beginIntervalTime = [DateTime]$row.BEGIN_INTERVAL_TIME
    $endIntervalTime = [DateTime]$row.END_INTERVAL_TIME

    # Für Daten eines Tages:
#    $snapDesc = "$($beginIntervalTime.ToString('HH:mm'))-$($endIntervalTime.ToString('HH:mm'))"
    
    # Für Daten mehrerer Tage:
    $snapDesc = "$($beginIntervalTime.ToString('MM-dd-HH:mm'))-$($endIntervalTime.ToString('HH:mm'))"
    
    $snapSec = ($endIntervalTime - $beginIntervalTime).TotalSeconds

    Add-Member -InputObject $row -MemberType NoteProperty -Name SNAP_DESC -Value $snapDesc
    Add-Member -InputObject $row -MemberType NoteProperty -Name SNAP_SEC -Value $snapSec

    $snapId = [int]$row.SNAP_ID
    $snapInfo[$snapId] = [PSCustomObject]@{
        SNAP_ID             = $snapId
        SNAP_DESC           = $snapDesc
        SNAP_SEC            = $snapSec
        BEGIN_INTERVAL_TIME = $beginIntervalTime
        END_INTERVAL_TIME   = $endIntervalTime
    }
}

$allSnapSec = ($dbaHistSnapshot | Measure-Object -Property SNAP_SEC -Sum).Sum


# Process dbaHistSqlstat
#########################

$excelParams.Path = "$basePath\dba_hist_sqlstat.xlsx"
Remove-Item -Path $excelParams.Path -ErrorAction Ignore


# define the names and formats of all metrics

$sqlMetrics = @( )
$sqlMetricsFormat = @{ }

foreach ($baseMetric in 'EXECUTIONS', 'ROWS_PROCESSED', 'ELAPSED_TIME', 'CPU_TIME', 'IOWAIT', 'CCWAIT', 'BUFFER_GETS', 'DISK_READS') {
    $sqlMetrics += $baseMetric
    $sqlMetricsFormat[$baseMetric] = '#,##0'

    $sqlMetrics += "$($baseMetric)_PER_SEC"
    $sqlMetricsFormat["$($baseMetric)_PER_SEC"] = '#,##0.00'

    if ($baseMetric -notin 'EXECUTIONS', 'ROWS_PROCESSED') {
        $sqlMetrics += "$($baseMetric)_PCT"
        $sqlMetricsFormat["$($baseMetric)_PCT"] = '#,##0.00'
    }

    if ($baseMetric -ne 'EXECUTIONS') {
        $sqlMetrics += "$($baseMetric)_PER_EXEC"
        $sqlMetricsFormat["$($baseMetric)_PER_EXEC"] = '#,##0.00'
    }

    if ($baseMetric -ne 'ROWS_PROCESSED') {
        $sqlMetrics += "$($baseMetric)_PER_ROW"
        $sqlMetricsFormat["$($baseMetric)_PER_ROW"] = '#,##0.00'
    }
}


# Step 1: Enrich objects

foreach ($row in $dbaHistSqlstat) {
    # $row = $dbaHistSqlstat[0]

    $snapId = [int]$row.SNAP_ID

    $snapSec = $snapInfo[$snapId].SNAP_SEC

    $metrics = 'EXECUTIONS', 'ROWS_PROCESSED', 'ELAPSED_TIME', 'CPU_TIME', 'IOWAIT', 'CCWAIT', 'BUFFER_GETS', 'DISK_READS'
    foreach ($metric in $metrics) {
        Add-Member -InputObject $row -MemberType NoteProperty -Name $metric -Value $row."$($metric)_DELTA"
    }
    foreach ($metric in $metrics) {
        Add-Member -InputObject $row -MemberType NoteProperty -Name "$($metric)_PER_SEC" -Value ([Math]::Round($row.$metric / $snapSec, $roundingPlaces))
    }
        
    $metrics = $metrics | Where-Object { $_ -ne 'EXECUTIONS' }
    foreach ($metric in $metrics) {
        Add-Member -InputObject $row -MemberType NoteProperty -Name "$($metric)_PER_EXEC" -Value $(if ($row.EXECUTIONS) { [Math]::Round($row.$metric / $row.EXECUTIONS, $roundingPlaces) })
    }

    $metrics = $metrics | Where-Object { $_ -ne 'ROWS_PROCESSED' }
    foreach ($metric in $metrics) {
        Add-Member -InputObject $row -MemberType NoteProperty -Name "$($metric)_PER_ROW" -Value $(if ($row.ROWS_PROCESSED) { [Math]::Round($row.$metric / $row.ROWS_PROCESSED, $roundingPlaces) })
    }
}
# $dbaHistSqlstat | Out-GridView


# Step 2: Sum of all snapshots

$allSnapTable = [PSCustomObject]@{
    SNAP_SEC = $allSnapSec
}

$metrics = 'ELAPSED_TIME', 'CPU_TIME', 'IOWAIT', 'CCWAIT', 'BUFFER_GETS', 'DISK_READS'

$sum = [PSCustomObject]@{ }
foreach ($metric in $metrics) {
    Add-Member -InputObject $sum -MemberType NoteProperty -Name $metric -Value ($dbaHistSqlstat | Measure-Object -Property $metric -Sum).Sum
}

foreach ($metric in $metrics) {
    Add-Member -InputObject $allSnapTable -MemberType NoteProperty -Name $metric -Value $sum.$metric
}
foreach ($metric in $metrics) {
    Add-Member -InputObject $allSnapTable -MemberType NoteProperty -Name "$($metric)_PER_SEC" -Value ([Math]::Round($sum.$metric / $allSnapSec, $roundingPlaces))
}
# $allSnapTable

$allSnapExcel = @{
    WorksheetName = 'All'
    Title         = 'Summe der Metriken über alle Snapshots'
    Style         = Get-MyExcelStyle -Table $allSnapTable -Format $sqlMetricsFormat
}
$allSnapTable | Export-Excel @excelParams @allSnapExcel


# Step 3: Sum per SQL_ID

$sqlIdGroups = $dbaHistSqlstat | Group-Object -Property SQL_ID
$metrics = 'EXECUTIONS', 'ROWS_PROCESSED', 'ELAPSED_TIME', 'CPU_TIME', 'IOWAIT', 'CCWAIT', 'BUFFER_GETS', 'DISK_READS'
$sqlIdTable = foreach ($group in $sqlIdGroups) {
    # $group = $sqlIdGroups[0]

    $sum = [PSCustomObject]@{ }
    foreach ($metric in $metrics) {
        Add-Member -InputObject $sum -MemberType NoteProperty -Name $metric -Value ($group.Group | Measure-Object -Property $metric -Sum).Sum
    }
        
    $output = [PSCustomObject]@{
        SQL_ID                  = $group.Name
        PLAN_HASH_VALUE_COUNT   = ($group.Group | Select-Object -Property PLAN_HASH_VALUE -Unique | Measure-Object).Count
    }

    foreach ($metric in $metrics) {
        Add-Member -InputObject $output -MemberType NoteProperty -Name $metric -Value $sum.$metric
        if ($metric -notin 'EXECUTIONS', 'ROWS_PROCESSED') {
            Add-Member -InputObject $output -MemberType NoteProperty -Name "$($metric)_PCT" -Value ([Math]::Round($sum.$metric * 100 / $allSnapTable.$metric, $roundingPlaces))
        }
    }

    foreach ($metric in $metrics) {
        Add-Member -InputObject $output -MemberType NoteProperty -Name "$($metric)_PER_SEC" -Value ([Math]::Round($sum.$metric / $allSnapSec, $roundingPlaces))
    }

    foreach ($metric in $metrics) {
        if ($metric -notin 'EXECUTIONS') {
            Add-Member -InputObject $output -MemberType NoteProperty -Name "$($metric)_PER_EXEC" -Value $(if ($sum.EXECUTIONS) { [Math]::Round($sum.$metric / $sum.EXECUTIONS, $roundingPlaces) })
        }
    }
    $output
}
$sqlIdTable = $sqlIdTable | Sort-Object -Property ELAPSED_TIME -Descending
# $sqlIdTable | Out-GridView

$sqlIdExcel = @{
    WorksheetName        = 'Per SQL'
    Title                = 'Informationen pro SQL Statement'
    FreezeFirstColumn    = $true
    Style                = Get-MyExcelStyle -Table $sqlIdTable -Format $sqlMetricsFormat
    ConditionalFormat    = @( )
}
foreach ($metric in 'ELAPSED_TIME', 'CPU_TIME', 'IOWAIT', 'CCWAIT', 'BUFFER_GETS', 'DISK_READS') {
    $sqlIdExcel.ConditionalFormat += @{ Range = "$($metric)_PCT" ; DataBarColor = 'CornflowerBlue' }
}
$sqlIdTable | Export-Excel @excelParams @sqlIdExcel


# Step 4: Sum per snapshot

$snapshotGroups = $dbaHistSqlstat | Group-Object -Property SNAP_ID
$snapshotTable = foreach ($group in $snapshotGroups) {
    # $group = $snapshotGroups[0]

    $snapId = [int]$group.Name

    $sum = [PSCustomObject]@{ }
    foreach ($metric in $metrics) {
        Add-Member -InputObject $sum -MemberType NoteProperty -Name $metric -Value ($group.Group | Measure-Object -Property $metric -Sum).Sum
    }

    $output = [PSCustomObject]@{
        SNAP_DESC = $snapInfo[$snapId].SNAP_DESC
        SNAP_ID   = $snapId
    }
    foreach ($metric in $metrics) {
        if ($metric -notin 'EXECUTIONS', 'ROWS_PROCESSED') {
            Add-Member -InputObject $output -MemberType NoteProperty -Name $metric -Value $sum.$metric
        }
    }
    foreach ($metric in $metrics) {
        if ($metric -notin 'EXECUTIONS', 'ROWS_PROCESSED') {
            Add-Member -InputObject $output -MemberType NoteProperty -Name "$($metric)_PER_SEC" -Value ([Math]::Round($sum.$metric / $allSnapSec, $roundingPlaces))
        }
    }
    $output
}
$snapshotTable = $snapshotTable | Sort-Object -Property SNAP_ID
# $snapshotTable | Format-Table

$snapshotExcel = @{
    WorksheetName        = 'Per snapshot'
    Title                = 'Informationen über alle Statements pro Snapshot'
    FreezeFirstColumn    = $true
    Style                = Get-MyExcelStyle -Table $snapshotTable -Format $sqlMetricsFormat
    ExcelChartDefinition = @( )
}
$chartParams = @{
    ChartType      = 'Line'
    XRange         = 'SNAP_DESC'
    NoLegend       = $true
    Column         = 1
    Width          = 1000
    Height         = 400
}
$row = $snapshotTable.Count + 5
foreach ($metric in $metrics) {
    if ($metric -notin 'EXECUTIONS', 'ROWS_PROCESSED') {
        $chartParamsMetric = @{
            Title          = "$($metric)_PER_SEC"
            YRange         = "$($metric)_PER_SEC"
            Row            = $row
        }
        $snapshotExcel.ExcelChartDefinition += New-ExcelChartDefinition @chartParams @chartParamsMetric
        $row += 25
    }
}
$snapshotTable | Export-Excel @excelParams @snapshotExcel


# Step 5: Details per snapshot (only plans from relevant statements)

$pctProperties = $sqlIdTable[0] | Get-Member -MemberType NoteProperty | Where-Object Name -like '*_PCT' | Select-Object -ExpandProperty Name
$relevantPlans = @( )
foreach ($prop in $pctProperties) {
    # $prop = $pctProperties[0]

    $sqlId = $sqlIdTable | Where-Object -Property $prop -gt $relevantSqlPercent | Select-Object -ExpandProperty SQL_ID
    $relevantPlans += $dbaHistSqlstat | Where-Object SQL_ID -in $sqlId | Select-Object -Property SQL_ID, PLAN_HASH_VALUE -Unique
}
$relevantPlans = $relevantPlans | Select-Object -Property SQL_ID, PLAN_HASH_VALUE -Unique
$relevantPlans = $relevantPlans | Sort-Object -Property { ($sqlIdInfo | Where-Object SQL_ID -eq $_.SQL_ID).ELAPSED_TIME } -Descending
    
$detailsTable = foreach ($group in $snapshotGroups) {
    # $group = $snapshotGroups[0]

    $snapId = [int]$group.Name

    $output = [PSCustomObject]@{
        SNAP_DESC = $snapInfo[$snapId].SNAP_DESC
        SNAP_ID   = $snapId
    }

    foreach ($plan in $relevantPlans) {
        # $plan = $relevantPlans[0]

        $key = "$($plan.SQL_ID)_$($plan.PLAN_HASH_VALUE)"
        $planDetail = $group.Group | Where-Object { $_.SQL_ID -eq $plan.SQL_ID -and $_.PLAN_HASH_VALUE -eq $plan.PLAN_HASH_VALUE }

        foreach ($metric in $metrics) {
            if ($metric -ne 'ROWS_PROCESSED') {
                Add-Member -InputObject $output -MemberType NoteProperty -Name "$($metric)_PER_SEC_$key" -Value $planDetail."$($metric)_PER_SEC"
            }
        }
        foreach ($metric in $metrics) {
            if ($metric -notin 'EXECUTIONS', 'ROWS_PROCESSED') {
                Add-Member -InputObject $output -MemberType NoteProperty -Name "$($metric)_PER_EXEC_$key" -Value $planDetail."$($metric)_PER_EXEC"
            }
        }
    }
    $output
}
$detailsTable = $detailsTable | Sort-Object -Property SNAP_ID
# $detailsTable | Out-GridView

$detailsExcel = @{
    WorksheetName        = 'Per Snapshot per PLAN'
    Title                = 'Informationen zu relevanten Statements pro Snapshot'
    FreezeFirstColumn    = $true
    Style                = @( )
    ExcelChartDefinition = @( )
}
foreach ($plan in $relevantPlans) {
    $key = "$($plan.SQL_ID)_$($plan.PLAN_HASH_VALUE)"
    $detailsExcel.Style += @{ Range = "EXECUTIONS_PER_SEC_$key" ; NumberFormat = '#,##0.00' }
    foreach ($metric in $metrics) {
        if ($metric -notin 'EXECUTIONS', 'ROWS_PROCESSED') {
            $detailsExcel.Style += @{ Range = "$($metric)_PER_SEC_$key" ; NumberFormat = '#,##0.00' }
            $detailsExcel.Style += @{ Range = "$($metric)_PER_EXEC_$key" ; NumberFormat = '#,##0.00' }
        }
    }
}
$chartParams = @{
    ChartType      = 'Line'
    XRange         = 'SNAP_DESC'
    NoLegend       = $true
    Column         = 1
    Width          = 1000
    Height         = 400
}
$row = $detailsTable.Count + 5
foreach ($plan in $relevantPlans) {
    $key = "$($plan.SQL_ID)_$($plan.PLAN_HASH_VALUE)"
    foreach ($metric in $metrics) {
        if ($metric -ne 'ROWS_PROCESSED') {
            $chartParamsMetric = @{
                Title          = "$key - $($metric)_PER_SEC"
                YRange         = "$($metric)_PER_SEC_$key"
                Row            = $row
            }
            $detailsExcel.ExcelChartDefinition += New-ExcelChartDefinition @chartParams @chartParamsMetric
            $row += 25
        }
        if ($metric -notin 'EXECUTIONS', 'ROWS_PROCESSED') {
            $chartParamsMetric = @{
                Title          = "$key - $($metric)_PER_EXEC"
                YRange         = "$($metric)_PER_EXEC_$key"
                Row            = $row
            }
            $detailsExcel.ExcelChartDefinition += New-ExcelChartDefinition @chartParams @chartParamsMetric
            $row += 25
        }
    }
    $row += 10
}
$detailsTable | Export-Excel @excelParams @detailsExcel


# Step 6: Create text files for sql statements

if (-not (Test-Path -Path $basePath\sqltext)) {
    $null = New-Item -Path $basePath\sqltext -ItemType Directory
}
foreach ($sql in $dbaHistSqltext) {
    # $sql = $dbaHistSqltext[0]

    if ($sql.sql_id -in $relevantPlans.SQL_ID) {
        $path = "$basePath\sqltext\sqltext_$($sql.sql_id).txt"
        Set-Content -Path $path -Value $sql.sql_text
    }
}


# Step 7: Add SQL text as comments

$excelPackage = Open-ExcelPackage -Path $excelParams.Path
$worksheet = $excelPackage.Workbook.Worksheets[$sqlIdExcel.WorksheetName]
$startRow =  $worksheet.Tables[0].Address.Start.Row + 1
$endRow =  $worksheet.Tables[0].Address.End.Row
foreach ($row in $startRow .. $endRow) {
    $sqlId = $worksheet.Cells["A$row"].Text
    $sqlText = $dbaHistSqltext | Where-Object sql_id -eq $sqlId | Select-Object -ExpandProperty sql_text
    if ($sqlText) {
        if ($sqlText.Length -gt 200) {
            $sqlText = $sqlText.Substring(0, 200)
        }
        $null = $worksheet.Cells["A$row"].AddComment($sqlText, 'X')
    }
}
Close-ExcelPackage -ExcelPackage $excelPackage
