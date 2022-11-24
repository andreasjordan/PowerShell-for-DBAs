function Write-SqlTable {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][System.Data.SqlClient.SqlConnection]$Connection,
        [Parameter(Mandatory)][string]$Table,
        [object[]]$Data,
        [object]$DataReader,
        [int]$DataReaderRowCount,
        [int]$BatchSize = 1000,
        [switch]$TruncateTable,
        [switch]$EnableException
    )

    Write-PSFMessage -Level Verbose -Message "Importing data into $Table"

    Write-PSFMessage -Level Verbose -Message "Getting target schema table"
    Write-Progress -Id 1 -Activity "Getting target schema table for $Table"
    try {
        $command = $Connection.CreateCommand()
        $command.CommandText = "SELECT * FROM $Table"
        $reader = $command.ExecuteReader()
        $targetSchemaTable = $reader.GetSchemaTable()
    } catch {
        Stop-PSFFunction -Message "Getting target schema table failed: $($_.Exception.InnerException.Message)" -Target $Table -EnableException $EnableException
        return
    } finally {
        if ($reader) { $reader.Dispose() }
        if ($command) { $command.Dispose() }
    }

    if ($PSBoundParameters.Keys -contains 'Data') {
        Write-PSFMessage -Level Verbose -Message "Creating data table"
        $dataTable = [System.Data.DataTable]::new()
        foreach ($column in $targetSchemaTable) { $null = $dataTable.Columns.Add($column.ColumnName, $column.DataType) }

        Write-PSFMessage -Level Verbose -Message "Filling data table"
        Write-Progress -Id 1 -Activity "Filling data table for $Table"
        try {
            foreach ($row in $Data) {
                $newRow = $dataTable.NewRow()
                foreach ($column in $targetSchemaTable) {
                    $value = $row.$($column.ColumnName)
                    if ($null -ne $value) {
                        $newRow[$column.ColumnName] = $value
                    } 
                }
                $dataTable.Rows.Add($newRow)
            }
        } catch {
            Stop-PSFFunction -Message "Filling data table failed: $($_.Exception.Message)" -Target $row -EnableException $EnableException
            return
        }
        $columnMappings = @( )
        $rowCount = $Data.Count
    } elseif ($PSBoundParameters.Keys -contains 'DataReader') {
        Write-PSFMessage -Level Verbose -Message "Getting source schema table"
        Write-Progress -Id 1 -Activity "Getting source schema table"
        try {
            $sourceSchemaTable = $DataReader.GetSchemaTable()
        } catch {
            Stop-PSFFunction -Message "Getting source schema table failed: $($_.Exception.InnerException.Message)" -Target $Table -EnableException $EnableException
            return
        }
        $columnMappings = @( )
        foreach ($sourceColumnName in $sourceSchemaTable.Rows.ColumnName) {
            $targetColumnName = $targetSchemaTable.Rows | Where-Object ColumnName -eq $sourceColumnName | Select-Object -ExpandProperty ColumnName
            if ($null -ne $targetColumnName) {
                Write-PSFMessage -Level Verbose -Message "Adding column mapping: $sourceColumnName -> $targetColumnName"
                $columnMappings += [System.Data.SqlClient.SqlBulkCopyColumnMapping]::new($sourceColumnName, $targetColumnName)
            } else {
                Stop-PSFFunction -Message "No target column for source column $sourceColumnName found." -Target $Table -EnableException $EnableException
                return
            }
        }
        $rowCount = $DataReaderRowCount
    } else {
        Stop-PSFFunction -Message "Neither Data nor DataReader is used, so nothing to do." -EnableException $EnableException
        return
    }

    if ($TruncateTable) {
        Write-PSFMessage -Level Verbose -Message "Truncating table"
        Write-Progress -Id 1 -Activity "Truncating table"
        try {
            $command = $Connection.CreateCommand()
            $command.CommandText = "TRUNCATE TABLE $Table"
            $null = $command.ExecuteNonQuery()
            $command.Dispose()
        } catch {
            Stop-PSFFunction -Message "Truncating table failed: $($_.Exception.InnerException.Message)" -Target $Table -EnableException $EnableException
            return
        } finally {
            if ($command) { $command.Dispose() }
        }
    }

    Write-PSFMessage -Level Verbose -Message "Initializing bulk copy"
    Write-Progress -Id 1 -Activity "Initializing bulk copy for $Table"
    try {
        $bulkCopyOptions = 0
        $bulkCopyOptions += [System.Data.SqlClient.SqlBulkCopyOptions]::TableLock
        $bulkCopyOptions += [System.Data.SqlClient.SqlBulkCopyOptions]::UseInternalTransaction
        $bulkCopy = [System.Data.SqlClient.SqlBulkCopy]::new($Connection, $bulkCopyOptions, $null)
        $bulkCopy.DestinationTableName = $Table
        #$columnMappings | ForEach-Object -Process { $null = $bulkCopy.ColumnMappings.Add($_) }
        $bulkCopy.BatchSize = $BatchSize
        $bulkCopy.NotifyAfter = $BatchSize
        $bulkCopy.BulkCopyTimeout = 0
        $bulkCopy.Add_SqlRowsCopied({
            $completed = $args[1].RowsCopied
            $progressParam = @{ 
                Id               = 1
                Activity         = "Inserting rows into $Table"
                Status           = "$completed of $rowCount rows transfered"
                SecondsRemaining = $stopwatch.Elapsed.TotalSeconds * ($rowCount - $completed) / $completed
            }
            if ($rowCount -gt 0) {
                $progressParam.PercentComplete  = $completed * 100 / $rowCount
            }
            if ($stopwatch.Elapsed.TotalSeconds -gt 1) {
                $progressParam.CurrentOperation = "$([int]($completed / $stopwatch.Elapsed.TotalSeconds)) rows per second"
            }
            Write-Progress @progressParam
        })
    } catch {
        if ($bulkCopy) { $bulkCopy.Dispose() }
        Stop-PSFFunction -Message "Initializing bulk copy failed: $($_.Exception.InnerException.Message)" -Target $Table -EnableException $EnableException
        return
    }

    Write-PSFMessage -Level Verbose -Message "Starting bulk copy"
    Write-Progress -Id 1 -Activity "Inserting rows into $Table"
    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        if ($PSBoundParameters.Keys -contains 'Data') {
            $bulkCopy.WriteToServer($dataTable)
        } else {
            $bulkCopy.WriteToServer($DataReader)
        }
        $stopwatch.Stop()
        Write-PSFMessage -Level Verbose -Message "Finished bulk copy in $($stopwatch.ElapsedMilliseconds) Milliseconds"
    } catch {
        Stop-PSFFunction -Message "Bulk copy failed: $($_.Exception.InnerException.Message)" -Target $bulkCopy -EnableException $EnableException
        return
    } finally {
        $bulkCopy.Dispose()
        if ($DataReader) { $DataReader.Dispose() }
    }
}
