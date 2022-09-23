throw "This is not a complete script and therefore must not be executed with F5. Please use F8."


#region *** Setting up the PowerShell session *** 


Add-Type -Path C:\oracle\product\19.0.0\client_1\odp.net\managed\common\Oracle.ManagedDataAccess.dll
. C:\DOAG\Connect-OraInstance.ps1
. C:\DOAG\Invoke-OraQuery.ps1


#endregion





#region *** Setting up the connection to the instance with Connect-OraInstance *** 


$instance = 'MDBW01/XEPDB1'
$credential = Get-Credential -Message $instance -UserName sys

$connection = Connect-OraInstance -Instance $instance -Credential $credential -AsSysdba


#endregion





#region *** Querying data with Invoke-OraQuery *** 


$query = 'SELECT * FROM v$parameter'

$data = Invoke-OraQuery -Connection $connection -Query $query

$data | Out-GridView -Title $query

# Show: Filter on "optimi" affects all columns


#endregion





#region *** Comparing data from different sources with local reference values *** 


<# Preparation:
Invoke-OraQuery -Connection $connection -Query 'ALTER SYSTEM SET optimizer_mode=all_rows'
Invoke-OraQuery -Connection $connection -Query 'ALTER SYSTEM SET optimizer_index_cost_adj=100'
$data = Invoke-OraQuery -Connection $connection -Query 'SELECT * FROM v$parameter'
$data | ? NAME -like 'optimizer*' | Sort NAME | Select NAME, VALUE | ConvertTo-Json | Set-Content .\target_parameter.json.txt
Invoke-OraQuery -Connection $connection -Query 'ALTER SYSTEM SET optimizer_mode=first_rows'
Invoke-OraQuery -Connection $connection -Query 'ALTER SYSTEM SET optimizer_index_cost_adj=200'
#>

Clear-Host
$target = Get-Content -Path .\target_parameter.json.txt | ConvertFrom-Json
$parameter = @{ }
foreach ($i in 'MDBW01/XEPDB1', 'MDBW02/XEPDB1') {
    $c = Connect-OraInstance -Instance $i -Credential $credential -AsSysdba
    $parameter[$i] = Invoke-OraQuery -Connection $c -Query 'SELECT * FROM v$parameter'
    $c.Dispose()
}

$comparison = foreach ($t in $target) {
    $output = [PSCustomObject]@{
        ParameterName = $t.NAME
        TargetValue   = $t.VALUE
        Status        = $null
    }
    foreach ($i in $parameter.Keys) {
        $value = ($parameter[$i] | Where-Object NAME -eq $t.NAME).VALUE
        Add-Member -InputObject $output -NotePropertyName $i -NotePropertyValue $value
        if ($value -ne $t.VALUE) { $output.Status = 'Difference' }
    }
    $output
}

$comparison | Where-Object Status -eq 'Difference' | Format-Table
$comparison | Out-GridView -Title 'Comparison'


#endregion





# Here we go again to the slides to show the content of Connect-OraInstance and Invoke-OraQuery ...





#region *** Loops *** 


# Example: Updating statistics. Iterative query of the objects to be processed and progress display.

# Retrieving the required data:

$dbaTables = Invoke-OraQuery -Connection $connection -Query 'SELECT * FROM dba_tables'
$dbaTables | Where-Object OWNER -eq STACKOVERFLOW | Format-Table -Property OWNER, TABLE_NAME, LAST_ANALYZED

# Two-level selection of the tables to be edited:

$owners = $dbaTables | Select-Object -ExpandProperty OWNER -Unique | Sort-Object
$selectedOwners = $owners | Out-GridView -OutputMode Multiple

$tables = $dbaTables | Where-Object OWNER -in $selectedOwners
$selectedTables = $tables | Select-Object -Property OWNER, TABLE_NAME, LAST_ANALYZED | Out-GridView -OutputMode Multiple

# Setting up the progress bar

Clear-Host
$progressParameter = @{ Activity = 'Updating statistics for selected tables' }
$progressTotal = $selectedTables.Count
$progressCompleted = 0 
$progressStart = Get-Date

# Start of the loop

foreach ($table in $selectedTables) {
    # $table = $selectedTables[0]

    # Updating the progress bar

    $progressParameter.Status = "$progressCompleted of $progressTotal tables completed"
    $progressParameter.CurrentOperation = "processing owner $($table.OWNER), processing table $($table.TABLE_NAME)"
    $progressParameter.PercentComplete = $progressCompleted * 100 / $progressTotal
    if ($progressParameter.PercentComplete -gt 0) {
        $progressParameter.SecondsRemaining = ((Get-Date) - $progressStart).TotalSeconds / $progressParameter.PercentComplete * (100 - $progressParameter.PercentComplete)
    }
    Write-Progress @progressParameter
    $progressCompleted++

    # Implementation of the operation

    $query = "begin dbms_stats.gather_table_stats('$($table.OWNER)', '$($table.TABLE_NAME)'); end;"
    Invoke-OraQuery -Connection $connection -Query $query
    
    # Just so the demo doesn't run so fast: Unnecessary wait

    Start-Sleep -Seconds 5

}

# Important if the script contains additional code: Remove progress bar

Write-Progress @progressParameter -Completed


#endregion





#region *** Error handling *** 


# Example: Retrieving the time of the last record from all tables using the CreationDate.

# Retrieving the table names:

$tableNames = Invoke-OraQuery -Connection $connection -Query "SELECT table_name FROM dba_tables WHERE owner = 'STACKOVERFLOW'" -As SingleValue

# Once show the error and the effect of EnableException
$query = "SELECT MAX(CreationDate) FROM stackoverflow.LINKTYPES"
Invoke-OraQuery -Connection $connection -Query $query -As SingleValue
Invoke-OraQuery -Connection $connection -Query $query -As SingleValue -EnableException

# Start of the loop

Clear-Host
$maxCreationDate = @{ }
$currentErrorCount = 0
$maxErrorCount = 5  # later set to 2 to abort processing
foreach ($tableName in $tableNames) {
    # $tableName = $tableNames[0]

    $query = "SELECT MAX(CreationDate) FROM stackoverflow.$tableName"
    try {
        $maxCreationDate.$tableName = Invoke-OraQuery -Connection $connection -Query $query -As SingleValue -EnableException
    } catch {
        $ex = $_
        $currentErrorCount++
        # Write-Warning -Message "Failure for table $($tableName): $ex"
        Write-Warning -Message "Failure for table $($tableName): $($ex.Exception.InnerException.Message)"
        
        if ($currentErrorCount -gt $maxErrorCount) {
            throw "Too many errors"
        }
    }
}
$maxCreationDate


#endregion





#region *** Logging *** 


# Example: Retrieving the time of the last record from all tables using the CreationDate.

# Install-Module –Name PSFramework -Scope CurrentUser
Import-Module -Name PSFramework

Write-PSFMessage -Level Verbose -Message "Retrieving the table names"
$tableNames = Invoke-OraQuery -Connection $connection -Query "SELECT table_name FROM dba_tables WHERE owner = 'STACKOVERFLOW'" -As SingleValue

# Start of the loop

Clear-Host
$maxCreationDate = @{ }
$currentErrorCount = 0
$maxErrorCount = 5  # later set to 2 to abort processing
Write-PSFMessage -Level Debug -Message "maxErrorCount = $maxErrorCount"

Write-PSFMessage -Level Verbose -Message "Processing $($tableNames.Count) tables"
foreach ($tableName in $tableNames) {
    # $tableName = $tableNames[0]

    $query = "SELECT MAX(CreationDate) FROM stackoverflow.$tableName"
    try {
        Write-PSFMessage -Level Debug -Message "Running query: $query"
        $maxCreationDate.$tableName = Invoke-OraQuery -Connection $connection -Query $query -As SingleValue -EnableException
    } catch {
        $ex = $_
        $currentErrorCount++
        # Write-Warning -Message "Failure for table $($tableName): $ex"
        # Write-PSFMessage -Level Warning -Message "Failure for table $($tableName): $($ex.Exception.InnerException.Message)"
        Stop-PSFFunction -Message "Failure for table $($tableName)" -ErrorRecord $ex -Target $tableName

        if ($currentErrorCount -gt $maxErrorCount) {
            Stop-PSFFunction -Message "Too many errors" -EnableException $true
        }
    }
}
$maxCreationDate

# Display the logging messages

Get-PSFMessage | Out-GridView
Get-PSFConfigValue -FullName psframework.logging.filesystem.logpath | Invoke-Item


#endregion





# Here we go again to the slides to show the export of data to Excel with ImportExcel ...





#region *** Exporting data to Excel with ImportExcel *** 


$folder = "$env:TEMP\excel"
$null = New-Item -Path $folder -ItemType Directory

# Install-Module -Name ImportExcel -Scope CurrentUser
Import-Module -Name ImportExcel

$data = Invoke-OraQuery -Connection $connection -Query 'SELECT * FROM v$parameter'

$excelParams = @{
    Path          = "$folder\DatabaseInformation.xlsx"
    WorksheetName = 'v$parameter'
    TableStyle    = 'Light18'
    AutoSize      = $true
    FreezeTopRow  = $true
}
$data | Export-Excel @excelParams

Invoke-Item $folder

Remove-Item -Path $folder -Recurse -Force


#endregion





#region *** Exporting data to JSON with ConvertTo-Json *** 


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





#region *** Creation and use of a filter *** 


filter Out-OraGridView {
    Invoke-OraQuery -Connection $connection -Query $_ | Out-GridView -Title $_
}

'SELECT * FROM v$parameter' | Out-OraGridView
'SELECT * FROM dba_tables' | Out-OraGridView
'SELECT * FROM dba_segments' | Out-OraGridView


#endregion





#region *** Processing CLOBs (Part 1: body_of_a_post) *** 


$folder = "$env:TEMP\clob_html"
$null = New-Item -Path $folder -ItemType Directory

$filename = "$folder\body_of_a_post.htm"

$data = Invoke-OraQuery -Connection $connection -Query "SELECT * FROM stackoverflow.posts WHERE id = 1594484"

$data.BODY.Length  # 28118 Characters
$data.BODY | Set-Content -Path $filename -Encoding UTF8
& $filename

# https://stackoverflow.com/questions/1594484

Remove-Item -Path $folder -Recurse -Force


#endregion





#region *** Processing CLOBs (Part 2: Querying data from v$sql) *** 


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





#region *** Processing CLOBs (Part 3: Save data from v$sql to table with bind variables) *** 


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
