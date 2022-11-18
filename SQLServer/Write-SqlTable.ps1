function Write-SqlTable {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][Microsoft.Data.SqlClient.SqlConnection]$Connection,
        [Parameter(Mandatory)][string]$Table,
        [object[]]$Data,
        [object]$DataReader,
        [int]$DataReaderRowCount,
        [int]$BatchSize = 1000,
        [switch]$TruncateTable,
        [switch]$EnableException
    )

    Write-PSFMessage -Level Verbose -Message "Importing $($Data.Count) rows into $Table"

    if ($TruncateTable) {
        try {
            Write-PSFMessage -Level Verbose -Message "Truncating table"
            $command = $Connection.CreateCommand()
            $command.CommandText = "TRUNCATE TABLE $Table"
            $null = $command.ExecuteNonQuery()
            $command.Dispose()
        } catch {
            Stop-PSFFunction -Message "Truncating table failed: $($_.Exception.InnerException.Message)" -Target $Table -EnableException $EnableException
            return
        } finally {
            try { $command.Dispose() } catch { }
        }
    }

    if ($Data.Count -gt 0) {
        Write-PSFMessage -Level Verbose -Message "Getting schema table"
        Write-Progress -Id 1 -Activity "Getting schema table for $Table"
        try {
            $command = $Connection.CreateCommand()
            $command.CommandText = "SELECT * FROM $Table"
            $reader = $command.ExecuteReader()
            $schemaTable = $reader.GetSchemaTable()
        } catch {
            Stop-PSFFunction -Message "Getting schema table failed: $($_.Exception.InnerException.Message)" -Target $Table -EnableException $EnableException
            return
        } finally {
            try { $reader.Dispose() } catch { }
            try { $command.Dispose() } catch { }
        }

        Write-PSFMessage -Level Verbose -Message "Creating data table"
        $dataTable = [System.Data.DataTable]::new()
        foreach ($column in $schemaTable) { $null = $dataTable.Columns.Add($column.ColumnName, $column.DataType) }

        Write-PSFMessage -Level Verbose -Message "Filling data table"
        Write-Progress -Id 1 -Activity "Filling data table for $Table"
        try {
            foreach ($row in $Data) {
                $newRow = $dataTable.NewRow()
                foreach ($column in $schemaTable) {
                    $value = $row.$($column.ColumnName)
                    if ($value -ne $null) {
                        $newRow[$column.ColumnName] = $value
                    } 
                }
                $dataTable.Rows.Add($newRow)
            }
        } catch {
            Stop-PSFFunction -Message "Filling data table failed: $($_.Exception.Message)" -Target $row -EnableException $EnableException
            return
        }
        $rowCount = $Data.Count
    } elseif ($PSBoundParameters.Keys -contains 'DataReader') {
        $rowCount = $DataReaderRowCount
    } else {
        Stop-PSFFunction -Message "No data found" -EnableException $EnableException
        return
    }

    Write-PSFMessage -Level Verbose -Message "Initializing bulk copy"
    Write-Progress -Id 1 -Activity "Initializing bulk copy for $Table"
    $bulkCopyOptions = 0
    $bulkCopyOptions += [Microsoft.Data.SqlClient.SqlBulkCopyOptions]::TableLock
    $bulkCopyOptions += [Microsoft.Data.SqlClient.SqlBulkCopyOptions]::UseInternalTransaction
    $bulkCopy = [Microsoft.Data.SqlClient.SqlBulkCopy]::new($Connection, $bulkCopyOptions, $null)
    $bulkCopy.DestinationTableName = $Table
    $bulkCopy.BatchSize = $BatchSize
    $bulkCopy.NotifyAfter = $BatchSize
    $bulkCopy.BulkCopyTimeout = 0
    $bulkCopy.Add_SqlRowsCopied({
        $completed = $args[1].RowsCopied
        $progressParam = @{ 
            Id               = 1
            Activity         = "Inserting rows into $Table"
            Status           = "$completed of $rowCount rows transfered"
            PercentComplete  = $completed * 100 / $rowCount
            SecondsRemaining = $stopwatch.Elapsed.TotalSeconds * ($rowCount - $completed) / $completed
        }
        if ($stopwatch.Elapsed.TotalSeconds -gt 1) {
            $progressParam.CurrentOperation = "$([int]($completed / $stopwatch.Elapsed.TotalSeconds)) rows per second"
        }
        Write-Progress @progressParam
    })

    try {
        Write-PSFMessage -Level Verbose -Message "Starting bulk copy"
        Write-Progress -Id 1 -Activity "Inserting rows into $Table"
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        if ($Data.Count -gt 0) {
            $bulkCopy.WriteToServer($dataTable)
        } else {
            $bulkCopy.WriteToServer($DataReader)
            $DataReader.Dispose()
        }
        $stopwatch.Stop()
        Write-PSFMessage -Level Verbose -Message "Finished bulk copy in $($stopwatch.ElapsedMilliseconds) Milliseconds"
    } catch {
        Stop-PSFFunction -Message "Bulk copy failed: $($_.Exception.InnerException.Message)" -Target $bulkCopy -EnableException $EnableException
        return
    } finally {
        $bulkCopy.Dispose()
    }
}
